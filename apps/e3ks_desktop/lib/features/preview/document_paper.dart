/// رسم صفحة واحدة على ورقة بمقاسها الحقيقي.
///
/// ليست محاكاة لمحرّك تخطيط Word: نقرأ خصائص الفقرات والمقاطع ونرسمها،
/// ولا نحسب أين ينكسر السطر. لكن **مقاس الورقة وهوامشها من المستند نفسه**
/// (`w:sectPr`) — فلا تختلف الصفحات عن بعضها ولا يضيع إحساس الصفحة.
///
/// تكبير ١٠٠٪ = مقاس الورقة الحقيقي (`Metrics.pxPerPoint`).
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/swatch.dart';
import 'change_scan.dart';

/// عرض عمود الترقيم بالنقاط الطباعية — يسكن **داخل** هامش الصفحة.
const double _gutterPt = 22;

class DocumentPaper extends StatelessWidget {
  const DocumentPaper({
    super.key,
    required this.page,
    required this.zoom,
    required this.startNumber,
    this.showNumbers = true,
    this.highlightChanged = false,
    this.changedColors = const {},
    this.changedFonts = const {},
  });

  /// صفحة واحدة. القائمة تبني المرئي منها فقط — وهذا سرّ خفّة المعاينة.
  final PreviewPage page;

  /// تكبير. ‏١٫٠ = مقاس الورقة الحقيقي.
  final double zoom;

  /// رقم أول كتلة في هذه الصفحة ضمن المستند كلّه.
  final int startNumber;

  final bool showNumbers;

  /// إطار سماوي حول ما سيتغيّر — يوجّه العين إلى الأثر بدل البحث عنه.
  final bool highlightChanged;
  final Set<String> changedColors;
  final Set<String> changedFonts;

  /// بكسل منطقي لكل نقطة طباعية عند هذا التكبير.
  double get _scale => zoom * Metrics.pxPerPoint;

  @override
  Widget build(BuildContext context) {
    final geometry = page.geometry;
    final width = geometry.widthPt * _scale;
    final height = geometry.heightPt * _scale;

    // الرقم يسكن داخل الهامش الأيسر فلا يزيح النصّ عن موضعه الحقيقي.
    // وإن ضاق الهامش عن استيعابه تنازلنا عن جزء منه — الرقم أداة مراجعة،
    // والهامش هو الحقيقة.
    final gutter = showNumbers
        ? (_gutterPt * _scale).clamp(0.0, geometry.marginLeftPt * _scale)
        : 0.0;

    final children = <Widget>[
      for (var i = 0; i < page.blocks.length; i++)
        _numbered(
          index: startNumber + i,
          gutter: gutter,
          child: _block(page.blocks[i]),
        ),
    ];

    // الاتجاه هنا فيزيائي لا منطقي: هوامش `w:pgMar` يمين ويسار الورقة، وكل
    // نصّ يحمل اتجاهه بنفسه. بلا هذا التثبيت تنقلب الصفحة في واجهة عربية.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: CustomPaint(
        foregroundPainter: _PageEdge(height),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: width,
            maxWidth: width,
            minHeight: height,
          ),
          child: Container(
            color: Paper.sheet,
            padding: EdgeInsets.fromLTRB(
              geometry.marginLeftPt * _scale - gutter,
              geometry.marginTopPt * _scale,
              geometry.marginRightPt * _scale,
              geometry.marginBottomPt * _scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  /// يضع رقم الكتلة في هامش الصفحة — مرجع ثابت يحيل إليه المستخدم.
  Widget _numbered({
    required int index,
    required double gutter,
    required Widget child,
  }) {
    if (gutter <= 0) return child;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: gutter,
          child: Padding(
            padding: EdgeInsets.only(top: 3 * _scale, right: 6 * _scale),
            child: Text(
              '$index',
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 7 * _scale,
                color: Paper.gutter,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _block(PreviewBlock block) => switch (block) {
    ParagraphBlock(:final paragraph) => _paragraph(paragraph),
    TableBlock(:final rows, :final isRtl, :final columnFractions) => _table(
      rows,
      isRtl,
      columnFractions,
    ),
  };

  Widget _paragraph(PreviewParagraph paragraph, {bool inCell = false}) {
    // فقرة فارغة ليست عدمًا: تشغل سطرًا وحده ومسافاتها، وWord يعدّها صفحةً.
    if (paragraph.runs.isEmpty) {
      return SizedBox(
        height: inCell
            ? 0
            : (11 * (paragraph.lineHeight ?? 1.15) +
                      paragraph.spaceBeforePt +
                      paragraph.spaceAfterPt) *
                  _scale,
      );
    }

    final content = Container(
      width: double.infinity,
      color: paragraph.fill == null ? null : toFlutter(paragraph.fill!),
      padding: paragraph.fill == null
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: 7 * _scale, vertical: 2 * _scale),
      // المسافة من `w:spacing` كما صرّح بها المستند لا من تقديرنا. الخلية
      // أضيق دائمًا، فنقصّ مسافاتها كما يفعل Word.
      margin: EdgeInsets.only(
        top: paragraph.spaceBeforePt * _scale * (inCell ? 0.5 : 1),
        bottom: paragraph.spaceAfterPt * _scale * (inCell ? 0.5 : 1),
      ),
      child: Text.rich(
        TextSpan(
          children: [for (final run in paragraph.runs) _span(run, paragraph)],
        ),
        textAlign: switch (paragraph.align) {
          PreviewAlign.center => TextAlign.center,
          PreviewAlign.end => TextAlign.end,
          PreviewAlign.justify => TextAlign.justify,
          PreviewAlign.start => TextAlign.start,
        },
        textDirection: paragraph.isRtl ? TextDirection.rtl : TextDirection.ltr,
      ),
    );

    final changed =
        highlightChanged &&
        paragraphChanged(paragraph, colors: changedColors, fonts: changedFonts);
    return changed ? _ChangedFrame(scale: _scale, child: content) : content;
  }

  TextSpan _span(PreviewRun run, PreviewParagraph paragraph) {
    // تقدير أخير لحجم العنوان **حين لا يصرّح به المستند ولا نمطه**.
    // تطبيقه فوق حجم مصرَّح كان يضخّم كل عنوان ٩٠٪ ويطيل الصفحة بلا سبب.
    final headingScale = run.sizePt != null
        ? 1.0
        : switch (paragraph.outlineLevel) {
            0 => 1.9,
            1 => 1.5,
            2 => 1.25,
            _ => 1.0,
          };

    return TextSpan(
      text: run.text,
      style: TextStyle(
        color: run.color == null ? Paper.ink : toFlutter(run.color!),
        backgroundColor: run.shading == null ? null : toFlutter(run.shading!),
        // حجم المقطع بالنقاط كما صرّح به المستند، محوَّلًا إلى بكسل.
        fontSize: (run.sizePt ?? 11) * headingScale * _scale,
        // ارتفاع السطر من `w:spacing/@w:line`. ‏1.15 احتياطي «مفرد» في Word.
        fontWeight: run.bold || paragraph.isHeading ? Type.bold : Type.regular,
        fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
        decoration: run.underline ? TextDecoration.underline : null,
        // اسم الخط الحقيقي من المستند: إن كان منصّبًا رآه المستخدم فعلًا.
        // وإن لم يكن، فآخر احتياطي خطّنا المضمَّن — وهو يرسم العربية
        // واللاتينية معًا، فلا ينكسر السطر المختلط في المعاينة.
        fontFamily: run.arabicFont ?? run.latinFont,
        fontFamilyFallback: [
          if (run.latinFont != null) run.latinFont!,
          Type.family,
          ...Type.fallback,
        ],
        height: paragraph.lineHeight ?? 1.15,
      ),
    );
  }

  Widget _table(List<PreviewRow> rows, bool isRtl, List<double> fractions) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final columns = rows
        .map((r) => r.cells.length)
        .reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: EdgeInsets.only(bottom: 4 * _scale),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Table(
          border: TableBorder.all(color: Paper.rule),
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          // أعرضة المستند حين يصرّح بها. الشبكة قد تصف أعمدة أكثر من أوسع
          // صفّ (خلايا مدمجة)، فنقصرها على ما نرسمه ونعيد التطبيع.
          columnWidths: _columnWidths(fractions, columns),
          children: [
            for (final row in rows)
              TableRow(
                children: [
                  for (var i = 0; i < columns; i++)
                    i < row.cells.length
                        ? _cell(row.cells[i])
                        : const SizedBox.shrink(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// نسب `w:tblGrid` مقصورةً على الأعمدة المرسومة ومُعاد تطبيعها.
  Map<int, TableColumnWidth>? _columnWidths(
    List<double> fractions,
    int columns,
  ) {
    if (fractions.length < columns) return null;
    final used = fractions.take(columns).toList();
    final total = used.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return null;
    return {
      for (var i = 0; i < columns; i++) i: FractionColumnWidth(used[i] / total),
    };
  }

  Widget _cell(PreviewCell cell) {
    final changed =
        highlightChanged &&
        (_hitColor(cell.fill) ||
            cell.paragraphs.any(
              (p) => paragraphChanged(
                p,
                colors: changedColors,
                fonts: changedFonts,
              ),
            ));
    return Container(
      color: cell.fill == null ? null : toFlutter(cell.fill!),
      // هوامش خلية Word الافتراضية: ‏5.4pt جانبًا ولا شيء رأسيًّا.
      padding: EdgeInsets.symmetric(
        horizontal: 5.4 * _scale,
        vertical: 1 * _scale,
      ),
      foregroundDecoration: changed
          ? BoxDecoration(border: Border.all(color: Shade.mirror, width: 1.5))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in cell.paragraphs) _paragraph(p, inCell: true),
        ],
      ),
    );
  }

  bool _hitColor(HexColor? color) =>
      color != null && changedColors.contains(color.value);
}

/// خطّ رفيع عند حدّ الصفحة الحقيقي حين يتجاوزه المحتوى.
///
/// نحن لا نحسب انكسار السطر كما يحسبه Word، فقد يفيض محتوى صفحةٍ عن ورقتها.
/// **لا نقصّه** — إخفاء محتوى في أداة معاينة كذب. نمدّ الورقة ونعلّم أين كان
/// حدّها، فيعرف المستخدم أن ما تحت الخطّ تقديرنا لا تخطيط Word.
class _PageEdge extends CustomPainter {
  const _PageEdge(this.pageHeight);
  final double pageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= pageHeight + 1) return;
    canvas.drawLine(
      Offset(0, pageHeight),
      Offset(size.width, pageHeight),
      Paint()
        ..color = Paper.rule
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PageEdge old) => old.pageHeight != pageHeight;
}

class _ChangedFrame extends StatelessWidget {
  const _ChangedFrame({required this.child, required this.scale});
  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: 3 * scale),
    decoration: BoxDecoration(
      border: Border.all(color: Shade.mirror.withValues(alpha: 0.55)),
      borderRadius: BorderRadius.circular(4),
    ),
    padding: EdgeInsets.all(2 * scale),
    child: child,
  );
}
