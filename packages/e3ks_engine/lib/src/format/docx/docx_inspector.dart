/// فحص مستند Word: استخراج كل لون وكل خط بعدده ودوره وموضعه وعيّنة نصّه.
///
/// الفحص **قراءة محضة** — لا يعدّل الحاوية ولا يمسّ جزءًا.
library;

import 'package:xml/xml.dart';

import '../../diagnostics/engine_result.dart';
import '../../inspect/color_usage.dart';
import '../../inspect/font_usage.dart';
import '../../inspect/hex_color.dart';
import '../../inspect/inspection_report.dart';
import '../../inspect/text_mark.dart';
import '../../inspect/usage_accumulator.dart';
import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';
import '../xml_part_pass.dart';
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

    final warnings = scanXmlParts(
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
    );

    return Ok(
      InspectionReport(
        colors: buildColors(colors),
        fonts: buildFonts(fonts),
        marks: buildMarks(marks),
        scannedParts: scanned,
      ),
      warnings: warnings,
    );
  }

  void _scanElement(
    XmlElement element,
    ScanContext context,
    Map<HexColor, ColorAccumulator> colors,
    Map<String, FontAccumulator> fonts,
    Map<TextMark, MarkAccumulator> marks,
  ) {
    final name = element.name.local;
    final namespace = element.name.namespaceUri;

    void addColor(String? raw, ColorRole role, {bool themed = false}) {
      final color = HexColor.tryParse(raw);
      if (color == null) return; // ومنها `auto` — تفويض لا لون (`02` §5).
      colors
          .putIfAbsent(color, ColorAccumulator.new)
          .record(context, role, themed: themed, sample: _sampleFor(element));
    }

    void addMark(TextMark mark) => marks
        .putIfAbsent(mark, MarkAccumulator.new)
        .record(context, sample: _sampleFor(element));

    if (namespace == wNs) {
      final hasThemeAttribute = colorThemeAttributes.any(
        (a) => element.getAttribute(a, namespace: wNs) != null,
      );

      switch (name) {
        case 'color':
          addColor(
            element.getAttribute('val', namespace: wNs),
            ColorRole.text,
            themed: hasThemeAttribute,
          );
        case 'shd':
          final role =
              _shadingRoleByParent[element.parentElement?.name.local] ??
              ColorRole.other;
          final fill = element.getAttribute('fill', namespace: wNs);
          addColor(fill, role, themed: hasThemeAttribute);
          // تظليل النصّ نفسه علامةٌ تُرفع، فوق كونه لونًا يُبدَّل: قلم Word
          // لا يرفعه لأنه ليس تمييزًا، فيستعصي على المستخدم.
          final shading = HexColor.tryParse(fill);
          if (role == ColorRole.runFill && shading != null) {
            addMark(TextMark.shading(shading));
          }
          addColor(
            element.getAttribute('color', namespace: wNs),
            ColorRole.shadingPattern,
            themed: hasThemeAttribute,
          );
        case 'background':
          addColor(
            element.getAttribute('color', namespace: wNs),
            ColorRole.pageBackground,
            themed: hasThemeAttribute,
          );
        case 'highlight':
          final value = element.getAttribute('val', namespace: wNs);
          if (value != null && value != 'none') {
            addMark(TextMark(MarkKind.highlight, value));
          }
        case 'rFonts':
          _scanFonts(element, context, fonts);
        default:
          if (borderElements.contains(name) || name == 'bdr') {
            addColor(
              element.getAttribute('color', namespace: wNs),
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
        final inScheme = element.ancestors.whereType<XmlElement>().any(
          (e) => e.name.local == 'clrScheme',
        );
        addColor(
          element.getAttribute('val'),
          inScheme ? ColorRole.themePalette : ColorRole.graphics,
        );
      } else if (name == 'latin' || name == 'cs' || name == 'ea') {
        final typeface = element.getAttribute('typeface');
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
    XmlElement element,
    ScanContext context,
    Map<String, FontAccumulator> fonts,
  ) {
    final themed = fontThemeAttributes.any(
      (a) => element.getAttribute(a, namespace: wNs) != null,
    );

    const slots = {
      'ascii': FontSlot.ascii,
      'hAnsi': FontSlot.highAnsi,
      'cs': FontSlot.complexScript,
      'eastAsia': FontSlot.eastAsian,
    };

    for (final attribute in fontAttributes) {
      final value = element.getAttribute(attribute, namespace: wNs);
      if (value == null || value.isEmpty) continue;
      fonts
          .putIfAbsent(value, FontAccumulator.new)
          .record(context, slots[attribute]!, themed: themed);
    }
  }

  /// عيّنة من النصّ الذي طُبّق عليه اللون.
  ///
  /// نصعد إلى أقرب `w:r` — فهو وحدة التنسيق — ثم إلى `w:p` إن لزم.
  /// بلا عيّنة يصير جدول الأثر أرقامًا صمّاء لا يُبنى عليها قرار.
  String? _sampleFor(XmlElement element) {
    for (final ancestor in element.ancestors.whereType<XmlElement>()) {
      if (ancestor.name.namespaceUri != wNs) continue;
      final isRun = ancestor.name.local == 'r';
      final isParagraph = ancestor.name.local == 'p';
      if (!isRun && !isParagraph) continue;

      final buffer = StringBuffer();
      for (final node in ancestor.descendants.whereType<XmlElement>()) {
        if (node.name.namespaceUri == wNs && node.name.local == 't') {
          buffer.write(node.innerText);
          if (buffer.length >= colorSampleLength) break;
        }
      }
      final text = buffer.toString().trim();
      if (text.isEmpty) {
        if (isParagraph) return null;
        continue; // الـ run بلا نص: نجرّب الفقرة.
      }
      return text.length <= colorSampleLength
          ? text
          : '${text.substring(0, colorSampleLength)}…';
    }
    return null;
  }
}
