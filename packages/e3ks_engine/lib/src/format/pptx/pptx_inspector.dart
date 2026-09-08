/// فحص عرض PowerPoint: كل لون وكل خط بعدده ودوره وموضعه وعيّنة نصّه.
///
/// أنظف من Word: الألوان كلّها DrawingML (`a:srgbClr`) بلا صيغ متعدّدة ولا
/// سمات ثيم مبعثرة. **الفخّ هنا مختلف:** `a:schemeClr` إحالةٌ إلى الثيم لا
/// لونٌ صريح، وعدّها لونًا يُخرج «accent1» في جدول الألوان.
///
/// والفحص **قراءة محضة فلا يبني شجرة** — تدفّق أحداث كنظيره في Word.
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
import 'pptx_embedded_fonts.dart';
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

    final warnings = scanXmlPartsStreamed(
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
      textShape: const TextShape(namespace: aNs),
    );

    return Ok(
      InspectionReport(
        colors: buildColors(colors),
        fonts: buildFonts(fonts),
        // قلم PowerPoint `a:highlight` بلون صريح، بلا أسماء Word الثابتة.
        marks: buildMarks(marks),
        scannedParts: scanned,
        embeddedFonts: readEmbeddedFonts(package),
      ),
      warnings: warnings,
    );
  }

  void _scan(
    ScannedElement element,
    ScanContext context,
    Map<HexColor, ColorAccumulator> colors,
    Map<String, FontAccumulator> fonts,
    Map<TextMark, MarkAccumulator> marks,
  ) {
    if (element.namespaceUri != aNs) return;

    final local = element.localName;
    switch (local) {
      case 'srgbClr':
        final color = HexColor.tryParse(element.attribute('val'));
        if (color == null) return;
        // لونٌ داخل `a:highlight` علامةٌ تُرفع، فوق كونه لونًا يُبدَّل.
        if (element.parentLocalName == 'highlight') {
          final mark = marks.putIfAbsent(
            TextMark.coloredPen(color),
            MarkAccumulator.new,
          );
          mark.record(context);
          element.deferSample(mark.addSample);
        }
        final accumulator = colors.putIfAbsent(color, ColorAccumulator.new);
        accumulator.record(context, roleOf(element), themed: false);
        element.deferSample(accumulator.addSample);

      case 'latin' || 'cs' || 'ea' || 'sym':
        final typeface = element.attribute('typeface');
        // `+mj-lt` و`+mn-ea` إحالات إلى خطوط الثيم لا أسماء عائلات.
        if (typeface == null || typeface.isEmpty || typeface.startsWith('+')) {
          return;
        }
        fonts
            .putIfAbsent(typeface, FontAccumulator.new)
            .record(context, _fontSlots[local]!, themed: false);
    }
  }
}

/// دور اللون من سياقه في شجرة DrawingML.
///
/// الترتيب مقصود: الأخصّ أولًا. `a:ln` داخل `a:spPr` حدٌّ لا تعبئة، ولون
/// داخل `a:rPr` نصٌّ ولو كان أبوه `a:solidFill` نفسه.
ColorRole roleOf(ScannedElement element) =>
    switch (element.nearestAncestor(_roleBearers)) {
      'clrScheme' || 'clrMap' || 'clrMapOvr' => ColorRole.themePalette,
      'ln' => ColorRole.border,
      // قلم التمييز: خلفية النصّ لا لونه. وهو أخصّ من `a:rPr` فيسبقه.
      'highlight' => ColorRole.runFill,
      'rPr' || 'defRPr' || 'endParaRPr' => ColorRole.text,
      'tcPr' => ColorRole.cellFill,
      'bg' || 'bgPr' || 'bgRef' => ColorRole.pageBackground,
      'spPr' || 'grpSpPr' => ColorRole.shapeFill,
      _ => ColorRole.graphics,
    };

/// العناصر التي يُقرأ منها الدور. الأقرب يفوز، فتُطلَب دفعةً ويُردّ أقربها.
const Set<String> _roleBearers = {
  'clrScheme',
  'clrMap',
  'clrMapOvr',
  'ln',
  'highlight',
  'rPr',
  'defRPr',
  'endParaRPr',
  'tcPr',
  'bg',
  'bgPr',
  'bgRef',
  'spPr',
  'grpSpPr',
};
