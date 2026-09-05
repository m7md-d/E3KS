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
  ShapeBlock(:final paragraphs, :final fill) =>
    _hit(fill, colors) ||
        paragraphs.any(
          (p) => paragraphChanged(p, colors: colors, fonts: fonts),
        ),
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

/// هل تحوي هذه الكتلة اللون [value]؟
///
/// نفس منطق [blockChanged] لكن بلون واحد: تتبّع لونٍ بعينه عبر المستند،
/// كما يتتبّع المستخدم كلمةً بـ`Ctrl+F`.
bool blockHasColor(PreviewBlock block, String value) => switch (block) {
  ShapeBlock(:final paragraphs, :final fill) =>
    _hit(fill, {value}) || paragraphs.any((p) => paragraphHasColor(p, value)),
  ParagraphBlock(:final paragraph) => paragraphHasColor(paragraph, value),
  TableBlock(:final rows) => rows.any(
    (row) => row.cells.any(
      (cell) =>
          _hit(cell.fill, {value}) ||
          cell.paragraphs.any((p) => paragraphHasColor(p, value)),
    ),
  ),
};

bool paragraphHasColor(PreviewParagraph paragraph, String value) =>
    _hit(paragraph.fill, {value}) ||
    paragraph.runs.any(
      (run) => _hit(run.color, {value}) || _hit(run.shading, {value}),
    );
