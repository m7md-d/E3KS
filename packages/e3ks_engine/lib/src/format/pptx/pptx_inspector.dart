/// فحص عرض PowerPoint: كل لون وكل خط بعدده ودوره وموضعه وعيّنة نصّه.
///
/// أنظف من Word: الألوان كلّها DrawingML (`a:srgbClr`) بلا صيغ متعدّدة ولا
/// سمات ثيم مبعثرة. **الفخّ هنا مختلف:** `a:schemeClr` إحالةٌ إلى الثيم لا
/// لونٌ صريح، وعدّها لونًا يُخرج «accent1» في جدول الألوان.
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
import 'pptx_parts.dart';

/// فتحات الخطّ في DrawingML. `a:sym` خطّ الرموز — يُحصى ولا يُبدَّل افتراضًا.
const Map<String, FontSlot> _fontSlots = {
  'latin': FontSlot.ascii,
  'cs': FontSlot.complexScript,
  'ea': FontSlot.eastAsian,
  'sym': FontSlot.drawing,
};

final class PptxInspector {
  const PptxInspector();

  EngineResult<InspectionReport> inspect(DocumentPackage package) {
    final colors = <HexColor, ColorAccumulator>{};
    final fonts = <String, FontAccumulator>{};
    final marks = <TextMark, MarkAccumulator>{};
    final scanned = <String>[];

    final warnings = scanXmlParts(
      package,
      classifyPptxPart,
      (element, partName, partClass) => _scan(
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
        // قلم PowerPoint `a:highlight` بلون صريح، بلا أسماء Word الثابتة.
        marks: buildMarks(marks),
        scannedParts: scanned,
      ),
      warnings: warnings,
    );
  }

  void _scan(
    XmlElement element,
    ScanContext context,
    Map<HexColor, ColorAccumulator> colors,
    Map<String, FontAccumulator> fonts,
    Map<TextMark, MarkAccumulator> marks,
  ) {
    if (element.name.namespaceUri != aNs) return;

    switch (element.name.local) {
      case 'srgbClr':
        final color = HexColor.tryParse(element.getAttribute('val'));
        if (color == null) return;
        // لونٌ داخل `a:highlight` علامةٌ تُرفع، فوق كونه لونًا يُبدَّل.
        if (element.parentElement?.name.local == 'highlight') {
          marks
              .putIfAbsent(TextMark.coloredPen(color), MarkAccumulator.new)
              .record(context, sample: sampleFor(element));
        }
        colors
            .putIfAbsent(color, ColorAccumulator.new)
            .record(
              context,
              roleOf(element),
              themed: false,
              sample: sampleFor(element),
            );

      case 'latin' || 'cs' || 'ea' || 'sym':
        final typeface = element.getAttribute('typeface');
        // `+mj-lt` و`+mn-ea` إحالات إلى خطوط الثيم لا أسماء عائلات.
        if (typeface == null || typeface.isEmpty || typeface.startsWith('+')) {
          return;
        }
        fonts
            .putIfAbsent(typeface, FontAccumulator.new)
            .record(context, _fontSlots[element.name.local]!, themed: false);
    }
  }
}

/// دور اللون من سياقه في شجرة DrawingML.
///
/// الترتيب مقصود: الأخصّ أولًا. `a:ln` داخل `a:spPr` حدٌّ لا تعبئة، ولون
/// داخل `a:rPr` نصٌّ ولو كان أبوه `a:solidFill` نفسه.
ColorRole roleOf(XmlElement element) {
  for (final ancestor in element.ancestors.whereType<XmlElement>()) {
    switch (ancestor.name.local) {
      case 'clrScheme' || 'clrMap' || 'clrMapOvr':
        return ColorRole.themePalette;
      case 'ln':
        return ColorRole.border;
      // قلم التمييز: خلفية النصّ لا لونه. وهو أخصّ من `a:rPr` فيسبقه.
      case 'highlight':
        return ColorRole.runFill;
      case 'rPr' || 'defRPr' || 'endParaRPr':
        return ColorRole.text;
      case 'tcPr':
        return ColorRole.cellFill;
      case 'bg' || 'bgPr' || 'bgRef':
        return ColorRole.pageBackground;
      case 'spPr' || 'grpSpPr':
        return ColorRole.shapeFill;
    }
  }
  return ColorRole.graphics;
}

/// عيّنة من النصّ الذي طُبّق عليه اللون.
///
/// نصعد إلى أقرب `a:r` — وحدة التنسيق — ثم إلى `a:p` إن لزم. بلا عيّنة
/// يصير جدول الأثر أرقامًا صمّاء لا يُبنى عليها قرار.
String? sampleFor(XmlElement element) {
  for (final ancestor in element.ancestors.whereType<XmlElement>()) {
    if (ancestor.name.namespaceUri != aNs) continue;
    final isRun = ancestor.name.local == 'r';
    final isParagraph = ancestor.name.local == 'p';
    if (!isRun && !isParagraph) continue;

    final buffer = StringBuffer();
    for (final node in ancestor.descendants.whereType<XmlElement>()) {
      if (node.name.namespaceUri == aNs && node.name.local == 't') {
        buffer.write(node.innerText);
        if (buffer.length >= colorSampleLength) break;
      }
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      if (isParagraph) return null;
      continue;
    }
    return text.length <= colorSampleLength
        ? text
        : '${text.substring(0, colorSampleLength)}…';
  }
  return null;
}
