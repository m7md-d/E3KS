/// تبديل الألوان والخطوط في عرض PowerPoint.
///
/// نفس ضمان Word (`00` §١/١): جزء لا يتغيّر محتواه **لا يُكتب أصلًا**،
/// والمقارنة بالبايتات لا بالنيّة — يتولّاها [rewriteXmlParts].
///
/// **وقاعدة الحماية نفسها تسبق الخطة** (`02` §7): خطّ في قائمة الحماية لا
/// يُبدَّل، ويُذكر في التقرير. اختلاف القاعدتين بين الصيغتين يجعل المستخدم
/// يرى سلوكين لأداة واحدة.
library;

import 'package:xml/xml.dart';

import '../../diagnostics/engine_issue.dart';
import '../../diagnostics/engine_result.dart';
import '../../inspect/hex_color.dart';
import '../../package/document_package.dart';
import '../../ooxml/ooxml_names.dart';
import '../../transform/style_plan.dart';
import '../../transform/transform_report.dart';
import '../xml_part_pass.dart';
import 'pptx_parts.dart';

final class PptxTransformer {
  const PptxTransformer();

  EngineResult<TransformReport> apply(DocumentPackage package, StylePlan plan) {
    final state = _PptxState(plan);
    final warnings = <EngineIssue>[];

    final rewritten = rewriteXmlParts(package, classifyPptxPart, state.visit);
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

final class _PptxState {
  _PptxState(this.plan);

  final StylePlan plan;
  final Map<HexColor, int> colorReplacements = {};
  final Map<String, int> fontReplacements = {};
  final Map<String, int> preservedFonts = {};
  final List<String> changedParts = [];

  void visit(XmlElement element) {
    if (element.name.namespaceUri != aNs) return;
    switch (element.name.local) {
      case 'srgbClr':
        _replaceColor(element);
      case 'latin' || 'cs' || 'ea':
        _replaceFont(element);
      // `a:sym` خطّ الرموز: تبديله يقلب الرموز إلى مربّعات فارغة.
    }
  }

  void _replaceColor(XmlElement element) {
    final current = HexColor.tryParse(element.getAttribute('val'));
    if (current == null) return;
    final target = plan.colors[current];
    if (target == null) return;
    // نغيّر `val` وحدها: `a:alpha` و`a:lumMod` أبناء يعدّلون اللون، وحذفهم
    // يغيّر مظهر الشكل بما لم يطلبه المستخدم.
    element.setAttribute('val', target.ooxmlValue);
    colorReplacements[current] = (colorReplacements[current] ?? 0) + 1;
  }

  void _replaceFont(XmlElement element) {
    final fonts = plan.fonts;
    if (fonts == null || fonts.isEmpty) return;

    final current = element.getAttribute('typeface');
    // `+mj-lt` إحالة إلى خطّ الثيم: تركها يعني أن تغيير الثيم يسري، وهو
    // المقصود من وجودها.
    if (current == null || current.isEmpty || current.startsWith('+')) return;

    final target = switch (element.name.local) {
      'latin' => fonts.latin,
      'cs' => fonts.arabic,
      _ => fonts.eastAsian,
    };
    if (target == null || target == current) return;

    if (plan.preserves(current)) {
      preservedFonts[current] = (preservedFonts[current] ?? 0) + 1;
      return;
    }

    element.setAttribute('typeface', target);
    fontReplacements[current] = (fontReplacements[current] ?? 0) + 1;
  }

  TransformReport build(Set<HexColor> unmatched) => TransformReport(
    colorReplacements: Map.unmodifiable(colorReplacements),
    fontReplacements: Map.unmodifiable(fontReplacements),
    // ‏DrawingML بلا سمات ثيم على العنصر: الإحالة عنصرٌ آخر (`a:schemeClr`)
    // لا نلمسه، فلا شيء يُحذف هنا.
    themeAttributesRemoved: 0,
    highlightsRemoved: 0,
    changedParts: List.unmodifiable(changedParts),
    unmatchedColors: Set.unmodifiable(unmatched),
    preservedFonts: Map.unmodifiable(preservedFonts),
  );
}
