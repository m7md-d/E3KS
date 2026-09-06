/// رسم صفحة واحدة على ورقة بمقاسها الحقيقي.
///
/// ليست محاكاة لمحرّك تخطيط Word: نقرأ خصائص الفقرات والمقاطع ونرسمها،
/// ولا نحسب أين ينكسر السطر. لكن **مقاس الورقة وهوامشها من المستند نفسه**
/// (`w:sectPr`) — فلا تختلف الصفحات عن بعضها ولا يضيع إحساس الصفحة.
///
/// تكبير ١٠٠٪ = مقاس الورقة الحقيقي (`Metrics.pxPerPoint`).
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/swatch.dart';
import 'change_scan.dart';
import '../../data/font_substitutes.dart';

/// عرض عمود الترقيم بالنقاط الطباعية — يسكن **داخل** هامش الصفحة.
const double _gutterPt = 22;

class DocumentPaper extends StatefulWidget {
  const DocumentPaper({
    super.key,
    required this.page,
    required this.zoom,
    required this.startNumber,
    this.showNumbers = true,
    this.highlightChanged = false,
    this.changedColors = const {},
    this.changedFonts = const {},
    this.focusedColor,
    this.onColorTap,
  });

  /// صفحة واحدة. القائمة تبني المرئي منها فقط — وهذا سرّ خفّة المعاينة.
  final PreviewPage page;

  /// تكبير. ١٫٠ = مقاس الورقة الحقيقي.
  final double zoom;

  /// رقم أول كتلة في هذه الصفحة ضمن المستند كلّه.
  final int startNumber;

  final bool showNumbers;

  /// إطار سماوي حول ما سيتغيّر — يوجّه العين إلى الأثر بدل البحث عنه.
  final bool highlightChanged;
  final Set<String> changedColors;
  final Set<String> changedFonts;

  /// اللون المتتبَّع: يُحاط بإطار أينما ظهر، فيراه المستخدم في لمحة.
  final HexColor? focusedColor;

  /// ضغطة على لون في الصفحة. **هذا ما يصل الصفحة بقائمة الألوان**: كان
  /// المستخدم يرى لونًا ثم يبحث عنه في قائمة بالرقم السداسي.
  final void Function(HexColor color)? onColorTap;

  @override
  State<DocumentPaper> createState() => _DocumentPaperState();
}

class _DocumentPaperState extends State<DocumentPaper> {
  /// مُلتقِط ضغطة لكل لون، يُعاد استعماله عبر إعادات البناء.
  ///
  /// `TapGestureRecognizer` داخل `TextSpan` يجب أن يُتخلَّص منه، وإنشاؤه في
  /// كل رسمة تسريبٌ صامت. الألوان عشرات لا آلاف، فخريطةٌ واحدة تكفي.
  final Map<String, TapGestureRecognizer> _taps = {};

  @override
  void dispose() {
    for (final tap in _taps.values) {
      tap.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer? _tapFor(HexColor? color) {
    final onTap = widget.onColorTap;
    if (color == null || onTap == null) return null;
    return _taps.putIfAbsent(
      color.value,
      () =>
          TapGestureRecognizer()..onTap = () => widget.onColorTap?.call(color),
    );
  }

  PreviewPage get page => widget.page;
  double get zoom => widget.zoom;
  int get startNumber => widget.startNumber;
  bool get showNumbers => widget.showNumbers;
  bool get highlightChanged => widget.highlightChanged;
  Set<String> get changedColors => widget.changedColors;
  Set<String> get changedFonts => widget.changedFonts;
  HexColor? get focusedColor => widget.focusedColor;

  /// بكسل منطقي لكل نقطة طباعية عند هذا التكبير.
  double get _scale => zoom * Metrics.pxPerPoint;

  bool _isFocused(HexColor? color) =>
      color != null &&
      focusedColor != null &&
      color.value == focusedColor!.value;

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

    // مستند Word تدفّق، والشريحة لوحة. الصفحة الواحدة قد تحمل النوعين،
    // فنرسم المتدفّق عمودًا ونضع المؤطَّر فوقه في موضعه المعلَن.
    final flowing = <Widget>[];
    final placed = <Widget>[];
    for (var i = 0; i < page.blocks.length; i++) {
      final block = page.blocks[i];
      final frame = block.frame;
      if (frame == null) {
        flowing.add(
          _numbered(
            index: startNumber + i,
            gutter: gutter,
            child: _block(block),
          ),
        );
        continue;
      }
      placed.add(
        Positioned(
          left: frame.leftPt * _scale,
          top: frame.topPt * _scale,
          width: frame.widthPt * _scale,
          // الارتفاع حدٌّ أدنى لا سقف: نصٌّ أطول من صندوقه يُعرَض ولا يُقصّ.
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: frame.heightPt * _scale),
            child: _block(block),
          ),
        ),
      );
    }

    // **لوحة أم تدفّق؟** وجود إطار معلَن يحسم الأمر، والفرق ليس تقنيًّا:
    //
    // الشريحة لوحة محدودة — ما خرج عن حدّها لا يظهر في PowerPoint نفسه،
    // فقصّه هنا **صدقٌ لا إخفاء**، وارتفاعها ثابت لا يمتدّ.
    //
    // وصفحة Word تدفّق — وفيضها منّا لا من المستند، لأننا لا نحسب انكسار
    // السطر كما يحسبه Word. فتُمدّ ويُعلَّم حدّها، ولا تُقصّ (`02` §7/1).
    final isCanvas = placed.isNotEmpty;

    final content = Container(
      color: Paper.sheet,
      padding: EdgeInsets.fromLTRB(
        geometry.marginLeftPt * _scale - gutter,
        geometry.marginTopPt * _scale,
        geometry.marginRightPt * _scale,
        geometry.marginBottomPt * _scale,
      ),
      child: Stack(
        clipBehavior: isCanvas ? Clip.hardEdge : Clip.none,
        children: [
          // طفل غير مُوضَّع يمنح الـStack مقاسه. بدونه لا يعرف ارتفاعه.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: flowing,
          ),
          ...placed,
        ],
      ),
    );

    // الاتجاه هنا فيزيائي لا منطقي: هوامش `w:pgMar` يمين ويسار الورقة، وكل
    // نصّ يحمل اتجاهه بنفسه. بلا هذا التثبيت تنقلب الصفحة في واجهة عربية.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: CustomPaint(
        foregroundPainter: isCanvas ? null : _PageEdge(height),
        child: isCanvas
            ? SizedBox(width: width, height: height, child: content)
            : ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: width,
                  maxWidth: width,
                  minHeight: height,
                ),
                child: content,
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
    ShapeBlock(:final paragraphs, :final fill) => _shape(paragraphs, fill),
    ParagraphBlock(:final paragraph) => _paragraph(paragraph),
    TableBlock(:final rows, :final isRtl, :final columnFractions) => _table(
      rows,
      isRtl,
      columnFractions,
    ),
  };

  /// شكل على شريحة: تعبئته وفقراته المتدفّقة داخله.
  Widget _shape(List<PreviewParagraph> paragraphs, HexColor? fill) {
    final content = Container(
      color: fill == null ? null : toFlutter(fill),
      foregroundDecoration: _isFocused(fill) ? _focusRing : null,
      padding: EdgeInsets.symmetric(
        horizontal: 7.2 * _scale,
        vertical: 3.6 * _scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final paragraph in paragraphs)
            _paragraph(paragraph, inCell: true),
        ],
      ),
    );

    final changed =
        highlightChanged &&
        (_hitColor(fill) ||
            paragraphs.any(
              (p) => paragraphChanged(
                p,
                colors: changedColors,
                fonts: changedFonts,
              ),
            ));
    final tappable = _wrapTap(content, fill);
    return changed ? _ChangedFrame(scale: _scale, child: tappable) : tappable;
  }

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
      foregroundDecoration: _isFocused(paragraph.fill) ? _focusRing : null,
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

    final tappable = _wrapTap(content, paragraph.fill);
    final changed =
        highlightChanged &&
        paragraphChanged(paragraph, colors: changedColors, fonts: changedFonts);
    return changed ? _ChangedFrame(scale: _scale, child: tappable) : tappable;
  }

  /// يجعل مساحةً ملوَّنة قابلة للضغط — التعبئة لون كالنصّ.
  Widget _wrapTap(Widget child, HexColor? color) {
    final onTap = widget.onColorTap;
    if (color == null || onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => onTap(color), child: child),
    );
  }

  /// العائلة التي تُرسم بها فعلًا، أو `null` إن لم يصرّح المقطع بخطّ.
  String? _family(String? declared) =>
      declared == null ? null : previewFamily(declared);

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

    // اللون المتتبَّع يظهر على أرضية سماوية خفيفة: أدقّ من إطار حول الفقرة
    // كلّها — يشير إلى المقطع نفسه لا إلى ما حوله.
    final focused = _isFocused(run.color) || _isFocused(run.shading);

    return TextSpan(
      text: run.text,
      recognizer: _tapFor(run.color ?? run.shading),
      style: TextStyle(
        color: run.color == null ? Paper.ink : toFlutter(run.color!),
        backgroundColor: focused
            ? Shade.mirror.withValues(alpha: 0.28)
            : (run.shading == null ? null : toFlutter(run.shading!)),
        // حجم المقطع بالنقاط كما صرّح به المستند، محوَّلًا إلى بكسل.
        fontSize: (run.sizePt ?? 11) * headingScale * _scale,
        // ارتفاع السطر من `w:spacing/@w:line`. 1.15 احتياطي «مفرد» في Word.
        fontWeight: run.bold || paragraph.isHeading ? Type.bold : Type.regular,
        fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
        decoration: run.underline ? TextDecoration.underline : null,
        // اسم الخط من المستند، مارًّا بجدول البدائل: خطٌّ مملوك لا نشحنه
        // يُرسَم ببديل مطابق مقاسيًّا، فيبقى التخطيط هو التخطيط.
        // وإن لم يُحلّ، فآخر احتياطي خطّنا المضمَّن — وهو يرسم العربية
        // واللاتينية معًا، فلا ينكسر السطر المختلط في المعاينة.
        fontFamily: _family(run.arabicFont ?? run.latinFont),
        fontFamilyFallback: [
          if (run.latinFont != null) previewFamily(run.latinFont!),
          Type.family,
          ...Type.fallback,
        ],
        height: paragraph.lineHeight ?? 1.15,
        // كنصّ الواجهة: بلا هذا يُقصّ ذيل الحرف، والمعاينة تَعِد بالشكل
        // الحقيقي — فقصٌّ فيها كذبٌ صامت (`07`).
        leadingDistribution: TextLeadingDistribution.even,
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
    final content = Container(
      color: cell.fill == null ? null : toFlutter(cell.fill!),
      // هوامش خلية Word الافتراضية: 5.4pt جانبًا ولا شيء رأسيًّا.
      padding: EdgeInsets.symmetric(
        horizontal: 5.4 * _scale,
        vertical: 1 * _scale,
      ),
      foregroundDecoration: _isFocused(cell.fill)
          ? _focusRing
          : (changed
                ? BoxDecoration(
                    border: Border.all(color: Shade.mirror, width: 1.5),
                  )
                : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in cell.paragraphs) _paragraph(p, inCell: true),
        ],
      ),
    );
    return _wrapTap(content, cell.fill);
  }

  bool _hitColor(HexColor? color) =>
      color != null && changedColors.contains(color.value);
}

/// إطار اللون المتتبَّع. أثخن من إطار التغيير كي يُميَّز عنه بلا لبس.
final BoxDecoration _focusRing = BoxDecoration(
  border: Border.all(color: Shade.mirror, width: 2.5),
);

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
