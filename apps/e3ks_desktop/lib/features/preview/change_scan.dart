/// تحديد الكتل المتأثّرة بالخطة.
///
/// يُستعمل في موضعين ويجب أن يتطابقا: رسم الإطار حول ما تغيّر، والتنقّل بين
/// التغييرات. لو اختلفا لصار زرّ «التالي» يقفز إلى كتلة لا إطار عليها.
library;

import 'package:e3ks_engine/e3ks_engine.dart';

bool blockChanged(
  PreviewBlock block, {
  required Set<String> colors,
  required Set<String> fonts,
}) => switch (block) {
  ParagraphBlock(:final paragraph) => paragraphChanged(
    paragraph,
    colors: colors,
    fonts: fonts,
  ),
  TableBlock(:final rows) => rows.any(
    (row) => row.cells.any(
      (cell) =>
          _hit(cell.fill, colors) ||
          cell.paragraphs.any(
            (p) => paragraphChanged(p, colors: colors, fonts: fonts),
          ),
    ),
  ),
};

bool paragraphChanged(
  PreviewParagraph paragraph, {
  required Set<String> colors,
  required Set<String> fonts,
}) =>
    _hit(paragraph.fill, colors) ||
    paragraph.runs.any(
      (run) =>
          _hit(run.color, colors) ||
          _hit(run.shading, colors) ||
          (run.latinFont != null && fonts.contains(run.latinFont)) ||
          (run.arabicFont != null && fonts.contains(run.arabicFont)),
    );

bool _hit(HexColor? color, Set<String> colors) =>
    color != null && colors.contains(color.value);
