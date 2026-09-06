/// لوحة المعاينة: مساحة العمل الحقيقية.
///
/// هنا يُسقَط الملف، وهنا يُراجَع العمل. المبدأ في `03`: لا زرّ ينفّذ عملية
/// غير قابلة للتراجع دون معاينة قبلها — وهذه اللوحة تنفيذ ذلك المبدأ.
library;

import 'dart:math' as math;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';
import 'focus_bar.dart';
import 'color_pick_layer.dart';
import 'document_paper.dart';
import 'page_index.dart';
import 'preview_toolbar.dart';
import 'drop_zone.dart';

/// الفراغ حول الورقة داخل القائمة — يدخل في حساب «ملء العرض».
const double _sheetMargin = 24;

class PreviewPanel extends StatefulWidget {
  const PreviewPanel({
    super.key,
    required this.store,
    required this.onOpen,
    required this.dragging,
  });

  final WorkspaceStore store;
  final void Function(String path) onOpen;
  final bool dragging;

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  final _scroll = ScrollController();
  final _across = ScrollController();

  /// افتراضًا نملأ العرض: ورقة Letter عند ١٠٠٪ أعرض من لوحة المعاينة في
  /// نافذة عادية، فبدء المستخدم أمام تمرير أفقي يبدو عطلًا لا مقاسًا حقيقيًّا.
  bool _fit = true;
  double _zoom = 1.0;
  bool _numbers = true;
  int _cursor = -1;

  /// مؤشّر التنقّل بين مواضع المتتبَّع — لونًا كان أو علامة. مستقلّ عن
  /// مؤشّر التغييرات، فالمستخدم قد يتتبّع شيئًا وهو في وسط مراجعة تغييراته.
  int _match = -1;
  String? _matchesFor;

  /// الصفحة الظاهرة الآن (من ١) — يقرؤها حقل الترقيم في الشريط.
  int _page = 1;

  /// **علامات التغيير مطفأة افتراضًا.** إطارٌ حول كل فقرة تغيّرت يصير بلا
  /// معنى حين يتغيّر لونٌ شائع: تُحاط الصفحة كلّها فلا تدلّ على شيء. ما
  /// يُبرَز افتراضًا هو **اللون المتتبَّع وحده** — ما اختاره المستخدم.
  bool _marks = false;

  /// حدّ إعادة الرسم حول الورق — منه تُلتقط البكسلات في وضع الالتقاط.
  final GlobalKey _paperKey = GlobalKey();

  /// وضع التقاط اللون من الصفحة نفسها.
  bool _picking = false;

  /// مفاتيح مستقرّة عبر إعادات البناء.
  ///
  /// كانت تُنشأ داخل `build` فتصير جديدة في كل رسم، فيبحث زرّ التنقّل عن
  /// مفتاح لا سياق له — وهذا سبب أن الأسهم لم تكن تفعل شيئًا.
  final Map<int, GlobalKey> _pageKeys = {};

  GlobalKey _keyFor(int index) => _pageKeys.putIfAbsent(index, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackVisiblePage);
  }

  /// يحدّد الصفحة التي تعبر حافّة النافذة العليا.
  ///
  /// نقيس الصفحات **المبنيّة** فقط — وهي أربع أو خمس مع العرض المُحجَّم،
  /// فالكلفة لا تُذكر ولا نعيد البناء إلا حين يتغيّر الرقم فعلًا.
  void _trackVisiblePage() {
    if (!_scroll.hasClients) return;
    var best = _page - 1;
    var bestTop = double.negativeInfinity;

    for (final entry in _pageKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      // آخر صفحة تبدأ فوق الحافّة هي التي يراها المستخدم.
      if (top <= 80 && top > bestTop) {
        bestTop = top;
        best = entry.key;
      }
    }

    if (best + 1 != _page) setState(() => _page = best + 1);
  }

  @override
  void dispose() {
    _scroll.removeListener(_trackVisiblePage);
    _scroll.dispose();
    _across.dispose();
    super.dispose();
  }

  /// التكبير الذي يجعل أعرض ورقة تملأ اللوحة تمامًا.
  double _fitZoom(double available, double widestPt) {
    if (widestPt <= 0) return 1;
    final usable = available - _sheetMargin * 2;
    if (usable <= 0) return zoomSteps.first;
    return (usable / (widestPt * Metrics.pxPerPoint)).clamp(
      zoomSteps.first,
      zoomSteps.last,
    );
  }

  /// أقرب درجة تكبير معلنة — نقطة انطلاق معقولة حين يترك المستخدم «ملء العرض».
  double _nearestStep(double value) => zoomSteps.reduce(
    (a, b) => (a - value).abs() <= (b - value).abs() ? a : b,
  );

  /// يقفز إلى صفحة قد لا تكون مبنيّة بعد.
  ///
  /// العرض المُحجَّم لا يبني إلا المرئي، فمفتاح صفحة بعيدة بلا سياق. لذلك
  /// نقفز أولًا بتقدير من متوسّط ارتفاع الصفحة، ثم نضبط بدقّة بعد أن تُبنى.
  Future<void> _goToPage(int index, int total) async {
    if (!_scroll.hasClients || total == 0) return;

    final context = _keyFor(index).currentContext;
    if (context == null) {
      final extent =
          _scroll.position.maxScrollExtent + _scroll.position.viewportDimension;
      final target = (extent / total) * index;
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    final settled = _keyFor(index).currentContext;
    if (settled == null) return;
    await Scrollable.ensureVisible(
      settled,
      alignment: 0.05,
      duration: Motion.slow,
      curve: Motion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final document = store.document;
    final t = context.l10n;

    if (document == null) {
      final failure = store.failure;
      return DropZone(
        onOpen: widget.onOpen,
        busy: store.busy,
        dragging: widget.dragging,
        errors: failure == null ? const [] : failureLines(t, failure),
      );
    }

    final showAfter = store.showAfter && store.hasChanges;
    final preview = showAfter ? store.previewAfter! : document.preview;

    final colors = <String>{
      for (final entry in store.colorMap.entries)
        showAfter ? entry.value.value : entry.key.value,
    };
    final fonts = <String>{
      if (store.latinFont != null || store.arabicFont != null)
        for (final font in document.report.fonts)
          if (!store.preserveFonts.contains(font.name))
            showAfter
                ? (store.arabicFont ?? store.latinFont ?? font.name)
                : font.name,
    };

    // ألوان المستند **كما تُرسم الآن**: في عرض «بعد» هي ألوان البدائل،
    // وإليها يقارن المنتقي بكسلات الشاشة.
    final palette = <HexColor>[
      for (final usage in document.report.contentColors)
        showAfter ? (store.colorMap[usage.color] ?? usage.color) : usage.color,
    ];

    final pages = flattenPages(preview);

    // العلامات المرفوعة تُرى في «قبل» وحدها: «بعد» لا تحملها أصلًا.
    final lifted = showAfter ? const <TextMark>{} : store.liftedMarks;
    final changed = changedPages(
      pages,
      colors: colors,
      fonts: fonts,
      marks: lifted,
    );
    if (_cursor >= changed.length) _cursor = changed.length - 1;

    // مواضع المتتبَّع. تُحسب عند تغيّره لا في كل رسمة.
    final focused = store.focusedColor;
    final focusedMark = store.focusedMark;

    // **العلامة تُطلَب من صفحات «قبل».** الرفع يمحوها من معاينة «بعد»،
    // فالبحث عنها هناك يقول «لا مواضع» لعلامةٍ للمستخدم فيها ثلاثة.
    // والترقيم واحد في المعاينتين: الرفع لا ينقل فقرة إلى صفحة أخرى.
    final List<int> matches;
    if (focused != null) {
      matches = pagesWithColor(pages, focused.value);
    } else if (focusedMark != null) {
      matches = pagesWithMark(
        showAfter ? flattenPages(document.preview) : pages,
        focusedMark,
      );
    } else {
      matches = const [];
    }
    final matchKey = focused?.value ?? focusedMark?.toString();
    if (_matchesFor != matchKey) {
      _matchesFor = matchKey;
      _match = -1;
    }
    if (_match >= matches.length) _match = matches.length - 1;

    // ترقيم الكتل متّصل عبر الصفحات كي يبقى المرجع ثابتًا.
    final blockStart = <int>[];
    var running = 1;
    for (final entry in pages) {
      blockStart.add(running);
      running += entry.page.blocks.length;
    }

    // أعرض ورقة في المستند: القسم الأفقيّ يقرّر عرض اللوحة كلّها كي لا
    // تقفز الصفحات يمينًا ويسارًا أثناء التمرير.
    final widestPt = pages.fold<double>(
      0,
      (widest, entry) => math.max(widest, entry.page.geometry.widthPt),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final zoom = _fit ? _fitZoom(constraints.maxWidth, widestPt) : _zoom;
        final paperWidth = widestPt * zoom * Metrics.pxPerPoint;
        final contentWidth = math.max(
          paperWidth + _sheetMargin * 2,
          constraints.maxWidth,
        );

        return Column(
          children: [
            if (focused != null)
              ColorFocusBar(
                color: focused,
                matches: matches.length,
                cursor: _match,
                onStep: matches.isEmpty
                    ? null
                    : _stepper(matches, pages.length),
                onClear: () => store.focusColor(null),
              )
            else if (focusedMark != null)
              MarkFocusBar(
                mark: focusedMark,
                matches: matches.length,
                cursor: _match,
                onStep: matches.isEmpty
                    ? null
                    : _stepper(matches, pages.length),
                onClear: () => store.focusMark(null),
              ),
            PreviewToolbar(
              store: store,
              zoom: zoom,
              fit: _fit,
              numbers: _numbers,
              pageCount: pages.length,
              changeCount: changed.length,
              cursor: _cursor,
              sections: [
                for (final entry in pages)
                  if (entry.firstOfSection)
                    (title: entry.kind.label(t), index: entry.index),
              ],
              onZoom: (value) => setState(() {
                _fit = false;
                _zoom = value;
              }),
              onFit: () => setState(() {
                if (_fit) _zoom = _nearestStep(zoom);
                _fit = !_fit;
              }),
              page: _page.clamp(1, pages.isEmpty ? 1 : pages.length),
              marks: _marks,
              picking: _picking,
              onPicking: (value) => setState(() => _picking = value),
              onNumbers: (value) => setState(() => _numbers = value),
              onMarks: (value) => setState(() => _marks = value),
              onGoToPage: (page) => _goToPage(page - 1, pages.length),
              onSection: (index) => _goToPage(index, pages.length),
              onStep: changed.isEmpty
                  ? null
                  : (delta) {
                      final next = (_cursor + delta).clamp(
                        0,
                        changed.length - 1,
                      );
                      setState(() => _cursor = next);
                      _goToPage(changed[next], pages.length);
                    },
            ),
            Expanded(
              child: Stack(
                children: [
                  // الورق داخل حدّ إعادة رسم: منه تُلتقط البكسلات حين
                  // يستعمل المستخدم منتقي اللون.
                  Positioned.fill(
                    child: RepaintBoundary(
                      key: _paperKey,
                      child: ColoredBox(
                        color: Shade.canvas,
                        child: Scrollbar(
                          controller: _across,
                          thumbVisibility: contentWidth > constraints.maxWidth,
                          child: SingleChildScrollView(
                            controller: _across,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: contentWidth,
                              height: constraints.maxHeight,
                              child: Scrollbar(
                                controller: _scroll,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: _scroll,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  // العرض المُحجَّم: مستند من ٣٧ صفحة يبني منها
                                  // المرئي فقط.
                                  itemCount: pages.length,
                                  itemBuilder: (context, i) => _PageSheet(
                                    key: _keyFor(i),
                                    entry: pages[i],
                                    zoom: zoom,
                                    startNumber: blockStart[i],
                                    showNumbers: _numbers,
                                    label: _pageLabel(
                                      t,
                                      pages[i],
                                      pages.length,
                                    ),
                                    marks: _marks,
                                    highlight:
                                        _marks &&
                                        store.hasChanges &&
                                        changed.contains(i),
                                    changedColors: colors,
                                    changedFonts: fonts,
                                    changedMarks: lifted,
                                    focusedColor: focused,
                                    onColorTap: store.focusColor,
                                    focusedMark: focusedMark,
                                    onMarkTap: store.focusMark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_picking)
                    Positioned.fill(
                      child: ColorPickLayer(
                        boundary: _paperKey,
                        candidates: palette,
                        onPicked: store.focusColor,
                        onCancel: () => setState(() => _picking = false),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// التنقّل بين المطابقات — واحدٌ للّون وللعلامة، فلا ينحرف سلوكهما.
  void Function(int delta) _stepper(List<int> matches, int pageCount) =>
      (delta) {
        final next = (_match + delta).clamp(0, matches.length - 1);
        setState(() => _match = next);
        _goToPage(matches[next], pageCount);
      };

  String _pageLabel(L t, FlatPage entry, int total) =>
      entry.kind == PreviewSectionKind.body
      ? t.pageOf(entry.numberInSection, total)
      : entry.kind.label(t);
}

/// ورقة واحدة بظلّها ورقمها. الفصل بين الصفحات ظاهر لا مُتخيَّل.
class _PageSheet extends StatelessWidget {
  const _PageSheet({
    super.key,
    required this.entry,
    required this.zoom,
    required this.startNumber,
    required this.showNumbers,
    required this.label,
    required this.marks,
    required this.highlight,
    required this.changedColors,
    required this.changedFonts,
    this.changedMarks = const {},
    this.focusedColor,
    this.onColorTap,
    this.focusedMark,
    this.onMarkTap,
  });

  final FlatPage entry;
  final double zoom;
  final int startNumber;
  final bool showNumbers;
  final String label;

  /// مفتاح علامات التغيير. **يحكم إطارات الكتل كما يحكم إطار الصفحة**:
  /// إطفاؤه كان يُخفي إطار الصفحة ويترك كل فقرة تغيّرت محاطة — وهو الضجيج
  /// نفسه الذي وُضع المفتاح لإسكاته.
  final bool marks;

  final bool highlight;
  final Set<String> changedColors;
  final Set<String> changedFonts;
  final Set<TextMark> changedMarks;
  final HexColor? focusedColor;
  final void Function(HexColor color)? onColorTap;
  final TextMark? focusedMark;
  final void Function(TextMark mark)? onMarkTap;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      // عرض الورقة مقاسها الحقيقي — لا مقاس محتواها.
      width: entry.page.geometry.widthPt * zoom * Metrics.pxPerPoint,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: Type.semiBold,
                      color: highlight ? Shade.mirror : Shade.textFaint,
                    ),
                  ),
                  if (highlight) ...[
                    const SizedBox(width: 7),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Shade.mirror,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: highlight
                    ? Border.all(color: Shade.mirrorSoft, width: 1.5)
                    : null,
                boxShadow: const [
                  BoxShadow(
                    color: Paper.shadow,
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: DocumentPaper(
                  page: entry.page,
                  zoom: zoom,
                  startNumber: startNumber,
                  showNumbers: showNumbers,
                  highlightChanged:
                      marks &&
                      (changedColors.isNotEmpty ||
                          changedFonts.isNotEmpty ||
                          changedMarks.isNotEmpty),
                  changedColors: changedColors,
                  changedFonts: changedFonts,
                  changedMarks: changedMarks,
                  focusedColor: focusedColor,
                  onColorTap: onColorTap,
                  focusedMark: focusedMark,
                  onMarkTap: onMarkTap,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
