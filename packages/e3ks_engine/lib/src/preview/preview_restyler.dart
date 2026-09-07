/// تطبيق الخطة على نموذج المعاينة **في الذاكرة**.
///
/// لا يمسّ المستند إطلاقًا. الغرض أن يرى المستخدم أثر أي تعديل فورًا،
/// بلا إعادة فتح الملف ولا إعادة بنائه — المبدأ `03`: الواجهة لا تتجمّد.
///
/// القواعد هنا **نفسها** المطبَّقة في `DocxTransformer`: قائمة الحماية تسبق
/// الخطة، والعربي من فتحة `cs`. أي اختلاف بينهما يجعل المعاينة كذبًا.
///
/// **وما لم يتغيّر يخرج بذاته لا بنسخةٍ منه.** كل عقدة لم يمسّها التبديل
/// تُرجَع **هي**، فتبقى `identical` بما كانت. وهذا ليس تقتيرًا في الذاكرة:
/// عليه تقوم الواجهة في تخطّي إعادة البناء. صفحةٌ لا تحوي اللون المبدَّل
/// تُعاد كما هي، فتُعاد معها ودجتُها نفسها، فيتخطّاها Flutter كاملةً —
/// بناءً وتخطيطًا ورسمًا. وبدونه يُعاد تخطيط كل صفحة مرئية عند كل تبديل لون
/// ولو لم تكن فيها.
library;

import '../inspect/hex_color.dart';
import '../inspect/text_mark.dart';
import '../transform/style_plan.dart';
import 'preview_model.dart';

DocumentPreview restylePreview(DocumentPreview preview, StylePlan plan) {
  final sections = _mapKeepingIdentity(
    preview.sections,
    (section) => _section(section, plan),
  );
  return identical(sections, preview.sections)
      ? preview
      : DocumentPreview(sections: sections);
}

/// يطبّق [convert] على كل عنصر، ويُرجع **القائمة الأصلية نفسها** إن لم
/// يتغيّر أيٌّ منها.
///
/// المقارنة بالهُويّة لا بالمساواة: العقد لا تعرّف `==`، والهُويّة هي ما
/// يقرأه Flutter حين يقرّر تخطّي شجرةٍ فرعية.
List<T> _mapKeepingIdentity<T>(List<T> items, T Function(T) convert) {
  List<T>? changed;
  for (var i = 0; i < items.length; i++) {
    final next = convert(items[i]);
    if (identical(next, items[i])) {
      changed?.add(next);
      continue;
    }
    changed ??= [...items.take(i)];
    changed.add(next);
  }
  return changed ?? items;
}

PreviewSection _section(PreviewSection section, StylePlan plan) {
  final pages = _mapKeepingIdentity(section.pages, (page) => _page(page, plan));
  if (identical(pages, section.pages)) return section;
  return PreviewSection(
    partName: section.partName,
    kind: section.kind,
    truncated: section.truncated,
    pages: pages,
  );
}

PreviewPage _page(PreviewPage page, StylePlan plan) {
  final blocks = _mapKeepingIdentity(
    page.blocks,
    (block) => _block(block, plan),
  );
  if (identical(blocks, page.blocks)) return page;
  return PreviewPage(
    number: page.number,
    geometry: page.geometry,
    blocks: blocks,
  );
}

PreviewBlock _block(PreviewBlock block, StylePlan plan) => switch (block) {
  ShapeBlock() => _shape(block, plan),
  ParagraphBlock(:final paragraph) => () {
    final next = _paragraph(paragraph, plan);
    return identical(next, paragraph) ? block : ParagraphBlock(next);
  }(),
  TableBlock() => _table(block, plan),
};

PreviewBlock _shape(ShapeBlock block, StylePlan plan) {
  final paragraphs = _mapKeepingIdentity(
    block.paragraphs,
    (p) => _paragraph(p, plan),
  );
  final fill = _color(block.fill, plan);
  if (identical(paragraphs, block.paragraphs) && fill == block.fill) {
    return block;
  }
  return ShapeBlock(
    paragraphs: paragraphs,
    frame: block.frame,
    fill: fill,
    startsPage: block.startsPage,
  );
}

PreviewBlock _table(TableBlock block, StylePlan plan) {
  final rows = _mapKeepingIdentity(block.rows, (row) => _row(row, plan));
  if (identical(rows, block.rows)) return block;
  return TableBlock(
    rows,
    isRtl: block.isRtl,
    startsPage: block.startsPage,
    columnFractions: block.columnFractions,
    frame: block.frame,
  );
}

PreviewRow _row(PreviewRow row, StylePlan plan) {
  final cells = _mapKeepingIdentity(row.cells, (cell) => _cell(cell, plan));
  if (identical(cells, row.cells)) return row;
  return PreviewRow(cells: cells, isHeader: row.isHeader);
}

PreviewCell _cell(PreviewCell cell, StylePlan plan) {
  final paragraphs = _mapKeepingIdentity(
    cell.paragraphs,
    (p) => _paragraph(p, plan),
  );
  final fill = _color(cell.fill, plan);
  if (identical(paragraphs, cell.paragraphs) && fill == cell.fill) return cell;
  return PreviewCell(
    paragraphs: paragraphs,
    fill: fill,
    columnSpan: cell.columnSpan,
  );
}

PreviewParagraph _paragraph(PreviewParagraph paragraph, StylePlan plan) {
  final runs = _mapKeepingIdentity(paragraph.runs, (run) => _run(run, plan));
  final fill = _color(paragraph.fill, plan);
  if (identical(runs, paragraph.runs) && fill == paragraph.fill) {
    return paragraph;
  }
  return PreviewParagraph(
    runs: runs,
    fill: fill,
    align: paragraph.align,
    spaceBeforePt: paragraph.spaceBeforePt,
    spaceAfterPt: paragraph.spaceAfterPt,
    lineHeight: paragraph.lineHeight,
    styleName: paragraph.styleName,
    isRtl: paragraph.isRtl,
    outlineLevel: paragraph.outlineLevel,
    startsPage: paragraph.startsPage,
  );
}

PreviewRun _run(PreviewRun run, StylePlan plan) {
  final color = _color(run.color, plan);
  final latin = _font(run.latinFont, plan.fonts?.latin, plan);
  final arabic = _font(run.arabicFont, plan.fonts?.arabic, plan);
  final shading = _shading(run.shading, plan);
  final highlight = _pen(run.highlight, plan);
  if (color == run.color &&
      latin == run.latinFont &&
      arabic == run.arabicFont &&
      shading == run.shading &&
      highlight == run.highlight) {
    return run;
  }
  return PreviewRun(
    text: run.text,
    color: color,
    latinFont: latin,
    arabicFont: arabic,
    sizePt: run.sizePt,
    bold: run.bold,
    italic: run.italic,
    underline: run.underline,
    shading: shading,
    highlight: highlight,
  );
}

/// خلفية النصّ: تُرفع إن طلبت الخطة رفعها، وإلّا بُدّلت كأي لون.
///
/// **الرفع يسبق التبديل** كما في المحوّل: اختلاف الترتيب بينهما يجعل
/// المعاينة تَعِد بما لا يخرج.
HexColor? _shading(HexColor? current, StylePlan plan) {
  if (current == null) return null;
  if (plan.removes(TextMark.shading(current))) return null;
  return plan.colors[current] ?? current;
}

TextMark? _pen(TextMark? mark, StylePlan plan) =>
    (mark == null || plan.removes(mark)) ? null : mark;

HexColor? _color(HexColor? current, StylePlan plan) =>
    current == null ? null : plan.colors[current] ?? current;

String? _font(String? current, String? target, StylePlan plan) {
  if (current == null || target == null) return current;
  if (plan.preserves(current)) return current; // الحماية تسبق الخطة — `02` §7.
  return target;
}
