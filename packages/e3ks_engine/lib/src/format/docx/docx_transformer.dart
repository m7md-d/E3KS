/// تبديل الألوان والخطوط في مستند Word.
///
/// الضمان العملي (`00` §١/١): جزء لا يتغيّر محتواه دلاليًا **لا يُكتب أصلًا**.
/// نقارن بايتات المخرج ببايتات المصدر بعد إعادة التسلسل، وهذا ممكن لأن ترميز
/// [ooxmlEntities] يجعل الدورة مطابقة حرفيًا — انظر `ooxml_entity_mapping.dart`.
library;

import 'package:xml/xml.dart';

import '../../diagnostics/engine_issue.dart';
import '../../diagnostics/engine_result.dart';
import '../../inspect/hex_color.dart';
import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';
import '../../transform/style_plan.dart';
import '../../transform/transform_report.dart';
import '../xml_part_pass.dart';
import 'docx_parts.dart';

final class DocxTransformer {
  const DocxTransformer();

  /// يطبّق [plan] على [package] موضعيًا ويُرجع تقريرًا بما جرى.
  EngineResult<TransformReport> apply(DocumentPackage package, StylePlan plan) {
    final state = _TransformState(plan);
    final warnings = <EngineIssue>[];

    final rewritten = rewriteXmlParts(package, classifyDocxPart, state.visit);
    if (rewritten case Failed(:final issues)) return Failed(issues);
    state.changedParts.addAll((rewritten as Ok<List<String>>).value);

    final unmatched = {
      for (final from in plan.colors.keys)
        if (!state.colorReplacements.containsKey(from)) from,
    };
    if (unmatched.isNotEmpty) {
      warnings.add(
        EngineIssue(
          code: IssueCode.unmatchedMapping,
          severity: IssueSeverity.warning,
          args: {
            'colors': [for (final c in unmatched) c.value],
          },
        ),
      );
    }

    return Ok(state.build(unmatched), warnings: warnings);
  }
}

/// حالة التحويل أثناء المرور — تفصيل داخلي لا يُصدَّر.
final class _TransformState {
  _TransformState(this.plan);

  final StylePlan plan;
  final Map<HexColor, int> colorReplacements = {};
  final Map<String, int> fontReplacements = {};
  final Map<String, int> preservedFonts = {};
  final List<String> changedParts = [];
  int themeAttributesRemoved = 0;
  int highlightsRemoved = 0;

  void visit(XmlElement element) {
    final namespace = element.name.namespaceUri;
    if (namespace == wNs) {
      _visitWordElement(element);
    } else if (namespace == aNs) {
      _visitDrawingElement(element);
    }
  }

  void _visitWordElement(XmlElement element) {
    switch (element.name.local) {
      case 'color':
        _replaceColorAttribute(element, 'val');
      case 'shd':
        _replaceColorAttribute(element, 'fill');
        _replaceColorAttribute(element, 'color');
      case 'background':
        _replaceColorAttribute(element, 'color');
      case 'rFonts':
        _replaceFonts(element);
      case 'highlight':
        if (plan.removeHighlight) {
          final value = element.getAttribute('val', namespace: wNs);
          if (value != null && value != 'none') {
            element.parent?.children.remove(element);
            highlightsRemoved++;
          }
        }
      default:
        if (borderElements.contains(element.name.local) ||
            element.name.local == 'bdr') {
          _replaceColorAttribute(element, 'color');
        }
    }
  }

  void _visitDrawingElement(XmlElement element) {
    if (element.name.local != 'srgbClr') return;
    final current = HexColor.tryParse(element.getAttribute('val'));
    if (current == null) return;
    final target = plan.colors[current];
    if (target == null) return;
    element.setAttribute('val', target.ooxmlValue);
    _countColor(current);
  }

  void _replaceColorAttribute(XmlElement element, String attribute) {
    final current = HexColor.tryParse(
      element.getAttribute(attribute, namespace: wNs),
    );
    if (current == null) return; // ومنها `auto` — تفويض لا لون.
    final target = plan.colors[current];
    if (target == null) return;

    element.setAttribute(attribute, target.ooxmlValue, namespace: wNs);
    _countColor(current);
    // سمة الثيم قد تغلب على القيمة الصريحة في بعض المستوردات — `02` §6.
    _removeAttributes(element, colorThemeAttributes);
  }

  void _replaceFonts(XmlElement element) {
    const slotPlan = {
      'ascii': _Slot.latin,
      'hAnsi': _Slot.latin,
      'cs': _Slot.arabic,
      'eastAsia': _Slot.eastAsian,
    };

    final fonts = plan.fonts;
    if (fonts == null || fonts.isEmpty) return;

    var replacedAny = false;
    for (final attribute in fontAttributes) {
      final current = element.getAttribute(attribute, namespace: wNs);
      if (current == null || current.isEmpty) continue;

      final target = switch (slotPlan[attribute]!) {
        _Slot.latin => fonts.latin,
        _Slot.arabic => fonts.arabic,
        _Slot.eastAsian => fonts.eastAsian,
      };
      if (target == null || target == current) continue;

      // قائمة الحماية تسبق الخطة دائمًا — `02` §7.
      if (plan.preserves(current)) {
        preservedFonts[current] = (preservedFonts[current] ?? 0) + 1;
        continue;
      }

      element.setAttribute(attribute, target, namespace: wNs);
      fontReplacements[current] = (fontReplacements[current] ?? 0) + 1;
      replacedAny = true;
    }

    if (replacedAny) _removeAttributes(element, fontThemeAttributes);
  }

  void _removeAttributes(XmlElement element, List<String> names) {
    for (final name in names) {
      if (element.getAttribute(name, namespace: wNs) == null) continue;
      element.removeAttribute(name, namespace: wNs);
      themeAttributesRemoved++;
    }
  }

  void _countColor(HexColor from) =>
      colorReplacements[from] = (colorReplacements[from] ?? 0) + 1;

  TransformReport build(Set<HexColor> unmatched) => TransformReport(
    colorReplacements: Map.unmodifiable(colorReplacements),
    fontReplacements: Map.unmodifiable(fontReplacements),
    themeAttributesRemoved: themeAttributesRemoved,
    highlightsRemoved: highlightsRemoved,
    changedParts: List.unmodifiable(changedParts),
    unmatchedColors: Set.unmodifiable(unmatched),
    preservedFonts: Map.unmodifiable(preservedFonts),
  );
}

enum _Slot { latin, arabic, eastAsian }
