/// فحص مستند Word: استخراج كل لون وكل خط بعدده ودوره وموضعه وعيّنة نصّه.
///
/// الفحص **قراءة محضة** — لا يعدّل الحاوية ولا يمسّ جزءًا.
library;

import 'package:xml/xml.dart';

import '../diagnostics/engine_issue.dart';
import '../diagnostics/engine_result.dart';
import '../ooxml/ooxml_names.dart';
import '../ooxml/part_classes.dart';
import '../package/document_package.dart';
import 'color_usage.dart';
import 'font_usage.dart';
import 'hex_color.dart';
import 'inspection_report.dart';

/// أقصى عدد عيّنات نصّية نحفظها لكل لون. ثلاث تكفي لفهم الدور، والمزيد ضجيج.
const int _maxSamples = 3;
const int _sampleLength = 60;

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
    final colors = <HexColor, _ColorAccumulator>{};
    final fonts = <String, _FontAccumulator>{};
    final highlights = <String, int>{};
    final scanned = <String>[];
    final warnings = <EngineIssue>[];

    for (final partName in package.partNames) {
      final partClass = classifyDocxPart(partName);
      if (partClass == PartClass.other) continue;

      final text = package.textOf(partName);
      if (text == null) continue;

      final XmlDocument document;
      try {
        document = XmlDocument.parse(text);
      } on XmlException catch (e) {
        // جزء تالف لا يُسقط الفحص كلّه، لكنه لا يُبتلع صامتًا (`03`).
        warnings.add(
          EngineIssue(
            code: IssueCode.malformedXml,
            severity: IssueSeverity.warning,
            part: partName,
            detail: '$e',
          ),
        );
        continue;
      }

      scanned.add(partName);
      final context = _ScanContext(partName, partClass);
      for (final element in document.descendants.whereType<XmlElement>()) {
        _scanElement(element, context, colors, fonts, highlights);
      }
    }

    final colorList = [
      for (final entry in colors.entries) entry.value.build(entry.key),
    ]..sort((a, b) => b.count.compareTo(a.count));

    final fontList = [
      for (final entry in fonts.entries) entry.value.build(entry.key),
    ]..sort((a, b) => b.count.compareTo(a.count));

    return Ok(
      InspectionReport(
        colors: colorList,
        fonts: fontList,
        highlights: highlights,
        scannedParts: scanned,
      ),
      warnings: warnings,
    );
  }

  void _scanElement(
    XmlElement element,
    _ScanContext context,
    Map<HexColor, _ColorAccumulator> colors,
    Map<String, _FontAccumulator> fonts,
    Map<String, int> highlights,
  ) {
    final name = element.name.local;
    final namespace = element.name.namespaceUri;

    void addColor(String? raw, ColorRole role, {bool themed = false}) {
      final color = HexColor.tryParse(raw);
      if (color == null) return; // ومنها `auto` — تفويض لا لون (`02` §5).
      colors
          .putIfAbsent(color, _ColorAccumulator.new)
          .record(context, role, themed: themed, sample: _sampleFor(element));
    }

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
          addColor(
            element.getAttribute('fill', namespace: wNs),
            role,
            themed: hasThemeAttribute,
          );
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
            highlights[value] = (highlights[value] ?? 0) + 1;
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
              .putIfAbsent(typeface, _FontAccumulator.new)
              .record(context, FontSlot.drawing, themed: false);
        }
      }
    }
  }

  void _scanFonts(
    XmlElement element,
    _ScanContext context,
    Map<String, _FontAccumulator> fonts,
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
          .putIfAbsent(value, _FontAccumulator.new)
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
          if (buffer.length >= _sampleLength) break;
        }
      }
      final text = buffer.toString().trim();
      if (text.isEmpty) {
        if (isParagraph) return null;
        continue; // الـ run بلا نص: نجرّب الفقرة.
      }
      return text.length <= _sampleLength
          ? text
          : '${text.substring(0, _sampleLength)}…';
    }
    return null;
  }
}

/// موضع الفحص الحالي: أي جزء وأي تصنيف.
final class _ScanContext {
  const _ScanContext(this.partName, this.partClass);
  final String partName;
  final PartClass partClass;
}

final class _ColorAccumulator {
  int count = 0;
  final Map<ColorRole, int> byRole = {};
  final Map<String, int> byPart = {};
  final Set<PartClass> partClasses = {};
  final List<String> samples = [];
  bool themeLinked = false;

  void record(
    _ScanContext context,
    ColorRole role, {
    required bool themed,
    String? sample,
  }) {
    count++;
    byRole[role] = (byRole[role] ?? 0) + 1;
    byPart[context.partName] = (byPart[context.partName] ?? 0) + 1;
    partClasses.add(context.partClass);
    if (themed) themeLinked = true;
    if (sample != null &&
        samples.length < _maxSamples &&
        !samples.contains(sample)) {
      samples.add(sample);
    }
  }

  ColorUsage build(HexColor color) => ColorUsage(
    color: color,
    count: count,
    byRole: Map.unmodifiable(byRole),
    byPart: Map.unmodifiable(byPart),
    partClasses: Set.unmodifiable(partClasses),
    themeLinked: themeLinked,
    samples: List.unmodifiable(samples),
  );
}

final class _FontAccumulator {
  int count = 0;
  final Map<FontSlot, int> bySlot = {};
  final Map<String, int> byPart = {};
  final Set<PartClass> partClasses = {};
  bool themeLinked = false;

  void record(_ScanContext context, FontSlot slot, {required bool themed}) {
    count++;
    bySlot[slot] = (bySlot[slot] ?? 0) + 1;
    byPart[context.partName] = (byPart[context.partName] ?? 0) + 1;
    partClasses.add(context.partClass);
    if (themed) themeLinked = true;
  }

  FontUsage build(String name) => FontUsage(
    name: name,
    count: count,
    bySlot: Map.unmodifiable(bySlot),
    byPart: Map.unmodifiable(byPart),
    partClasses: Set.unmodifiable(partClasses),
    themeLinked: themeLinked,
  );
}
