/// تطبيق الخطة على نموذج المعاينة **في الذاكرة**.
///
/// لا يمسّ المستند إطلاقًا. الغرض أن يرى المستخدم أثر أي تعديل فورًا،
/// بلا إعادة فتح الملف ولا إعادة بنائه — المبدأ `03`: الواجهة لا تتجمّد.
///
/// القواعد هنا **نفسها** المطبَّقة في `DocxTransformer`: قائمة الحماية تسبق
/// الخطة، والعربي من فتحة `cs`. أي اختلاف بينهما يجعل المعاينة كذبًا.
library;

import '../inspect/hex_color.dart';
import '../transform/style_plan.dart';
import 'preview_model.dart';

DocumentPreview restylePreview(DocumentPreview preview, StylePlan plan) =>
    DocumentPreview(
      sections: [
        for (final section in preview.sections)
          PreviewSection(
            partName: section.partName,
            kind: section.kind,
            truncated: section.truncated,
            pages: [
              for (final page in section.pages)
                PreviewPage(
                  number: page.number,
                  geometry: page.geometry,
                  blocks: [
                    for (final block in page.blocks) _block(block, plan),
                  ],
                ),
            ],
          ),
      ],
    );

PreviewBlock _block(PreviewBlock block, StylePlan plan) => switch (block) {
  ParagraphBlock(:final paragraph) => ParagraphBlock(
    _paragraph(paragraph, plan),
  ),
  TableBlock(
    :final rows,
    :final isRtl,
    :final startsPage,
    :final columnFractions,
  ) =>
    TableBlock(
      [
        for (final row in rows)
          PreviewRow(
            isHeader: row.isHeader,
            cells: [
              for (final cell in row.cells)
                PreviewCell(
                  fill: _color(cell.fill, plan),
                  columnSpan: cell.columnSpan,
                  paragraphs: [
                    for (final p in cell.paragraphs) _paragraph(p, plan),
                  ],
                ),
            ],
          ),
      ],
      isRtl: isRtl,
      startsPage: startsPage,
      columnFractions: columnFractions,
    ),
};

PreviewParagraph _paragraph(PreviewParagraph paragraph, StylePlan plan) =>
    PreviewParagraph(
      runs: [for (final run in paragraph.runs) _run(run, plan)],
      fill: _color(paragraph.fill, plan),
      align: paragraph.align,
      spaceBeforePt: paragraph.spaceBeforePt,
      spaceAfterPt: paragraph.spaceAfterPt,
      lineHeight: paragraph.lineHeight,
      styleName: paragraph.styleName,
      isRtl: paragraph.isRtl,
      outlineLevel: paragraph.outlineLevel,
      startsPage: paragraph.startsPage,
    );

PreviewRun _run(PreviewRun run, StylePlan plan) => PreviewRun(
  text: run.text,
  color: _color(run.color, plan),
  latinFont: _font(run.latinFont, plan.fonts?.latin, plan),
  arabicFont: _font(run.arabicFont, plan.fonts?.arabic, plan),
  sizePt: run.sizePt,
  bold: run.bold,
  italic: run.italic,
  underline: run.underline,
  shading: _color(run.shading, plan),
);

HexColor? _color(HexColor? current, StylePlan plan) =>
    current == null ? null : plan.colors[current] ?? current;

String? _font(String? current, String? target, StylePlan plan) {
  if (current == null || target == null) return current;
  if (plan.preserves(current)) return current; // الحماية تسبق الخطة — `02` §7.
  return target;
}
