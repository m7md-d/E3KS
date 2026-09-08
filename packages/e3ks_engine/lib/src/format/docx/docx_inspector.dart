/// فحص مستند Word: استخراج كل لون وكل خط بعدده ودوره وموضعه وعيّنة نصّه.
///
/// الفحص **قراءة محضة** — لا يعدّل الحاوية ولا يمسّ جزءًا. ولأنه قراءة محضة
/// **لا يبني شجرة**: يمرّ على تدفّق الأحداث ([scanXmlPartsStreamed])، فما
/// كان يكلّف ١٧٦MB لمستند مئة صفحة صار ٤١MB.
library;

import '../../diagnostics/engine_result.dart';
import '../../inspect/color_usage.dart';
import '../../inspect/font_usage.dart';
import '../../inspect/hex_color.dart';
import '../../inspect/inspection_report.dart';
import '../../inspect/text_mark.dart';
import '../../inspect/usage_accumulator.dart';
import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';
import '../xml_stream_pass.dart';
import 'docx_embedded_fonts.dart';
import 'docx_parts.dart';

/// دور خلفية `w:shd` يُحدَّد من العنصر الأب.
const Map<String, ColorRole> _shadingRoleByParent = {
  'rPr': ColorRole.runFill,
  'pPr': ColorRole.paragraphFill,
  'tcPr': ColorRole.cellFill,
  'trPr': ColorRole.rowFill,
  'tblPr': ColorRole.tableFill,
};

final class DocxInspector {
  const DocxInspector();

  EngineResult<InspectionReport> inspect(DocumentPackage package) {
    final colors = <HexColor, ColorAccumulator>{};
    final fonts = <String, FontAccumulator>{};
    final marks = <TextMark, MarkAccumulator>{};
    final scanned = <String>[];

    final warnings = scanXmlPartsStreamed(
      package,
      classifyDocxPart,
      (element, partName, partClass) => _scanElement(
        element,
        ScanContext(partName, partClass),
        colors,
        fonts,
        marks,
      ),
      scannedParts: scanned,
      textShape: const TextShape(namespace: wNs),
    );

    return Ok(
      InspectionReport(
        colors: buildColors(colors),
        fonts: buildFonts(fonts),
        marks: buildMarks(marks),
        scannedParts: scanned,
        // **يُقرأ مع الفحص لا بعده**: المعاينة تُرسَم أوّل ما يصل التقرير،
        // ونداءٌ ثانٍ يفتح الحاوية من جديد ليقرأ ما كان بين يديه.
        embeddedFonts: readEmbeddedFonts(package),
      ),
      warnings: warnings,
    );
  }

  void _scanElement(
    ScannedElement element,
    ScanContext context,
    Map<HexColor, ColorAccumulator> colors,
    Map<String, FontAccumulator> fonts,
    Map<TextMark, MarkAccumulator> marks,
  ) {
    final name = element.localName;
    final namespace = element.namespaceUri;

    void addColor(String? raw, ColorRole role, {bool themed = false}) {
      final color = HexColor.tryParse(raw);
      if (color == null) return; // ومنها `auto` — تفويض لا لون (`02` §5).
      final accumulator = colors.putIfAbsent(color, ColorAccumulator.new);
      accumulator.record(context, role, themed: themed);
      element.deferSample(accumulator.addSample);
    }

    void addMark(TextMark mark) {
      final accumulator = marks.putIfAbsent(mark, MarkAccumulator.new);
      accumulator.record(context);
      element.deferSample(accumulator.addSample);
    }

    if (namespace == wNs) {
      final hasThemeAttribute = colorThemeAttributes.any(
        (a) => element.attribute(a, namespace: wNs) != null,
      );

      switch (name) {
        case 'color':
          addColor(
            element.attribute('val', namespace: wNs),
            ColorRole.text,
            themed: hasThemeAttribute,
          );
        case 'shd':
          final role =
              _shadingRoleByParent[element.parentLocalName] ?? ColorRole.other;
          final fill = element.attribute('fill', namespace: wNs);
          addColor(fill, role, themed: hasThemeAttribute);
          // تظليل النصّ نفسه علامةٌ تُرفع، فوق كونه لونًا يُبدَّل: قلم Word
          // لا يرفعه لأنه ليس تمييزًا، فيستعصي على المستخدم.
          final shading = HexColor.tryParse(fill);
          if (role == ColorRole.runFill && shading != null) {
            addMark(TextMark.shading(shading));
          }
          addColor(
            element.attribute('color', namespace: wNs),
            ColorRole.shadingPattern,
            themed: hasThemeAttribute,
          );
        case 'background':
          addColor(
            element.attribute('color', namespace: wNs),
            ColorRole.pageBackground,
            themed: hasThemeAttribute,
          );
        case 'highlight':
          final value = element.attribute('val', namespace: wNs);
          if (value != null && value != 'none') {
            addMark(TextMark(MarkKind.highlight, value));
          }
        case 'rFonts':
          _scanFonts(element, context, fonts);
        default:
          if (borderElements.contains(name) || name == 'bdr') {
            addColor(
              element.attribute('color', namespace: wNs),
              ColorRole.border,
              themed: hasThemeAttribute,
            );
          }
      }
      return;
    }

    if (namespace == aNs) {
      if (name == 'srgbClr') {
        // داخل `a:clrScheme` هذه لوحة الثيم نفسها، لا استعمال في المحتوى.
        final inScheme = element.hasAncestor('clrScheme');
        addColor(
          element.attribute('val'),
          inScheme ? ColorRole.themePalette : ColorRole.graphics,
        );
      } else if (name == 'latin' || name == 'cs' || name == 'ea') {
        final typeface = element.attribute('typeface');
        if (typeface != null &&
            typeface.isNotEmpty &&
            !typeface.startsWith('+')) {
          fonts
              .putIfAbsent(typeface, FontAccumulator.new)
              .record(context, FontSlot.drawing, themed: false);
        }
      }
    }
  }

  void _scanFonts(
    ScannedElement element,
    ScanContext context,
    Map<String, FontAccumulator> fonts,
  ) {
    final themed = fontThemeAttributes.any(
      (a) => element.attribute(a, namespace: wNs) != null,
    );

    const slots = {
      'ascii': FontSlot.ascii,
      'hAnsi': FontSlot.highAnsi,
      'cs': FontSlot.complexScript,
      'eastAsia': FontSlot.eastAsian,
    };

    for (final attribute in fontAttributes) {
      final value = element.attribute(attribute, namespace: wNs);
      if (value == null || value.isEmpty) continue;
      fonts
          .putIfAbsent(value, FontAccumulator.new)
          .record(context, slots[attribute]!, themed: themed);
    }
  }
}
