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
  Set<TextMark> marks = const {},
}) => switch (block) {
  ShapeBlock(:final paragraphs, :final fill) =>
    _hit(fill, colors) ||
        paragraphs.any(
          (p) =>
              paragraphChanged(p, colors: colors, fonts: fonts, marks: marks),
        ),
  ParagraphBlock(:final paragraph) => paragraphChanged(
    paragraph,
    colors: colors,
    fonts: fonts,
    marks: marks,
  ),
  TableBlock(:final rows) => rows.any(
    (row) => row.cells.any(
      (cell) =>
          _hit(cell.fill, colors) ||
          cell.paragraphs.any(
            (p) =>
                paragraphChanged(p, colors: colors, fonts: fonts, marks: marks),
          ),
    ),
  ),
};

/// **العلامة المرفوعة تُرى في «قبل» وحدها.** معاينة «بعد» لا تحملها أصلًا،
/// فلا إطار حولها ولا قفزة إليها هناك — والموضعان يتفقان لأن الدالّة واحدة.
bool paragraphChanged(
  PreviewParagraph paragraph, {
  required Set<String> colors,
  required Set<String> fonts,
  Set<TextMark> marks = const {},
}) =>
    _hit(paragraph.fill, colors) ||
    paragraph.runs.any(
      (run) =>
          _hit(run.color, colors) ||
          _hit(run.shading, colors) ||
          marks.any((mark) => runHasMark(run, mark)) ||
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

/// هل تحوي هذه الكتلة العلامة [mark]؟
///
/// نفس منطق [blockHasColor] وللغرض نفسه: التنقّل بين مواضع ما يتتبّعه
/// المستخدم. والتظليل يُطابَق بلونه، فهو في المعاينة لونُ خلفيةٍ لا علامة.
bool blockHasMark(PreviewBlock block, TextMark mark) => switch (block) {
  ShapeBlock(:final paragraphs) => paragraphs.any(
    (p) => paragraphHasMark(p, mark),
  ),
  ParagraphBlock(:final paragraph) => paragraphHasMark(paragraph, mark),
  TableBlock(:final rows) => rows.any(
    (row) => row.cells.any(
      (cell) => cell.paragraphs.any((p) => paragraphHasMark(p, mark)),
    ),
  ),
};

bool paragraphHasMark(PreviewParagraph paragraph, TextMark mark) =>
    paragraph.runs.any((run) => runHasMark(run, mark));

bool runHasMark(PreviewRun run, TextMark mark) => switch (mark.kind) {
  MarkKind.highlight => run.highlight == mark,
  MarkKind.textShading => run.shading?.value == mark.key,
};
