/// لوحة المعاينة: مساحة العمل الحقيقية.
///
/// هنا يُسقَط الملف، وهنا يُراجَع العمل. المبدأ في `03`: لا زرّ ينفّذ عملية
/// غير قابلة للتراجع دون معاينة قبلها — وهذه اللوحة تنفيذ ذلك المبدأ.
library;

import 'dart:math' as math;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';
import 'document_paper.dart';
import 'page_index.dart';
import 'drop_zone.dart';

const List<double> _zoomSteps = [0.5, 0.65, 0.8, 1.0, 1.25, 1.5, 2.0];

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

  /// مفاتيح مستقرّة عبر إعادات البناء.
  ///
  /// كانت تُنشأ داخل `build` فتصير جديدة في كل رسم، فيبحث زرّ التنقّل عن
  /// مفتاح لا سياق له — وهذا سبب أن الأسهم لم تكن تفعل شيئًا.
  final Map<int, GlobalKey> _pageKeys = {};

  GlobalKey _keyFor(int index) => _pageKeys.putIfAbsent(index, GlobalKey.new);

  @override
  void dispose() {
    _scroll.dispose();
    _across.dispose();
    super.dispose();
  }

  /// التكبير الذي يجعل أعرض ورقة تملأ اللوحة تمامًا.
  double _fitZoom(double available, double widestPt) {
    if (widestPt <= 0) return 1;
    final usable = available - _sheetMargin * 2;
    if (usable <= 0) return _zoomSteps.first;
    return (usable / (widestPt * Metrics.pxPerPoint)).clamp(
      _zoomSteps.first,
      _zoomSteps.last,
    );
  }

  /// أقرب درجة تكبير معلنة — نقطة انطلاق معقولة حين يترك المستخدم «ملء العرض».
  double _nearestStep(double value) => _zoomSteps.reduce(
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

    final pages = flattenPages(preview);
    final changed = changedPages(pages, colors: colors, fonts: fonts);
    if (_cursor >= changed.length) _cursor = changed.length - 1;

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
            _Toolbar(
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
              onNumbers: (value) => setState(() => _numbers = value),
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
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          // العرض المُحجَّم: مستند من ٣٧ صفحة يبني منها
                          // المرئي فقط.
                          itemCount: pages.length,
                          itemBuilder: (context, i) => _PageSheet(
                            key: _keyFor(i),
                            entry: pages[i],
                            zoom: zoom,
                            startNumber: blockStart[i],
                            showNumbers: _numbers,
                            label: _pageLabel(t, pages[i], pages.length),
                            highlight: store.hasChanges && changed.contains(i),
                            changedColors: colors,
                            changedFonts: fonts,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
    required this.highlight,
    required this.changedColors,
    required this.changedFonts,
  });

  final FlatPage entry;
  final double zoom;
  final int startNumber;
  final bool showNumbers;
  final String label;
  final bool highlight;
  final Set<String> changedColors;
  final Set<String> changedFonts;

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
                      changedColors.isNotEmpty || changedFonts.isNotEmpty,
                  changedColors: changedColors,
                  changedFonts: changedFonts,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

typedef _SectionEntry = ({String title, int index});

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.store,
    required this.zoom,
    required this.fit,
    required this.numbers,
    required this.pageCount,
    required this.changeCount,
    required this.cursor,
    required this.sections,
    required this.onZoom,
    required this.onFit,
    required this.onNumbers,
    required this.onSection,
    required this.onStep,
  });

  final WorkspaceStore store;
  final double zoom;
  final bool fit;
  final bool numbers;
  final int pageCount;
  final int changeCount;
  final int cursor;
  final List<_SectionEntry> sections;
  final ValueChanged<double> onZoom;
  final VoidCallback onFit;
  final ValueChanged<bool> onNumbers;
  final void Function(int pageIndex) onSection;
  final void Function(int delta)? onStep;

  @override
  Widget build(BuildContext context) {
    final enabled = store.hasChanges;
    final t = context.l10n;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Shade.surface,
        border: Border(bottom: BorderSide(color: Shade.border)),
      ),
      // كشف تدريجي: عند ضيق المساحة يختفي الأقلّ أهمية بدل أن ينكسر الشريط.
      // ترتيب البقاء: قبل/بعد ← التنقّل بين التغييرات ← الترقيم ← التكبير ←
      // الانتقال إلى قسم.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showSections = width >= 620 && sections.length > 1;
          final showZoom = width >= 470;
          final showNumbering = width >= 400;

          return Row(
            children: [
              _Segmented(
                options: [t.before, t.after],
                selected: store.showAfter && enabled ? 1 : 0,
                enabled: enabled,
                onSelect: (i) => store.setShowAfter(i == 1),
              ),
              const _Sep(),
              // أهمّ أداة مراجعة: لا يبحث المستخدم عن تغييره في ٤٠٠ فقرة.
              _Stepper(count: changeCount, cursor: cursor, onStep: onStep),
              if (showNumbering) ...[
                const _Sep(),
                _IconToggle(
                  icon: LucideIcons.listOrdered,
                  tooltip: t.showNumbers,
                  value: numbers,
                  onChanged: onNumbers,
                ),
              ],
              if (showZoom) ...[
                const SizedBox(width: 6),
                _ZoomControl(
                  zoom: zoom,
                  fit: fit,
                  onZoom: onZoom,
                  onFit: onFit,
                ),
              ],
              const Spacer(),
              if (showSections)
                PopupMenuButton<int>(
                  tooltip: t.jumpToSection,
                  color: Shade.surfaceHigh,
                  onSelected: onSection,
                  itemBuilder: (_) => [
                    for (final section in sections)
                      PopupMenuItem(
                        value: section.index,
                        child: Text(section.title),
                      ),
                  ],
                  child: _Chip(
                    icon: LucideIcons.listTree,
                    label: t.jumpToSection,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.count,
    required this.cursor,
    required this.onStep,
  });

  final int count;
  final int cursor;
  final void Function(int delta)? onStep;

  @override
  Widget build(BuildContext context) {
    final active = onStep != null && count > 0;
    final t = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SquareButton(
          icon: LucideIcons.chevronUp,
          tooltip: t.previousChange,
          onTap: active && cursor > 0 ? () => onStep!(-1) : null,
        ),
        const SizedBox(width: 4),
        _SquareButton(
          icon: LucideIcons.chevronDown,
          tooltip: t.nextChange,
          onTap: active && cursor < count - 1 ? () => onStep!(1) : null,
        ),
        const SizedBox(width: 8),
        Text(
          active ? '${cursor < 0 ? 0 : cursor + 1} / $count' : t.noChangesYet,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active ? Shade.textMuted : Shade.textFaint,
          ),
        ),
      ],
    );
  }
}

class _ZoomControl extends StatelessWidget {
  const _ZoomControl({
    required this.zoom,
    required this.fit,
    required this.onZoom,
    required this.onFit,
  });

  final double zoom;
  final bool fit;
  final ValueChanged<double> onZoom;
  final VoidCallback onFit;

  /// أوّل درجة أكبر/أصغر من التكبير الحالي — يعمل ولو كان الحالي محسوبًا
  /// من «ملء العرض» ولا يطابق أي درجة معلنة.
  double? _step(int direction) {
    final steps = direction > 0 ? _zoomSteps : _zoomSteps.reversed;
    for (final step in steps) {
      if (direction > 0 ? step > zoom + 0.01 : step < zoom - 0.01) return step;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final smaller = _step(-1);
    final larger = _step(1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SquareButton(
          icon: LucideIcons.minus,
          tooltip: t.zoomOut,
          onTap: smaller == null ? null : () => onZoom(smaller),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${(zoom * 100).round()}%',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        _SquareButton(
          icon: LucideIcons.plus,
          tooltip: t.zoomIn,
          onTap: larger == null ? null : () => onZoom(larger),
        ),
        const SizedBox(width: 4),
        // «ملء العرض» مفتاح لا درجة: المستخدم يريد ورقةً كاملة أمامه، لا
        // نسبةً يحسبها بنفسه كلّما غيّر مقاس النافذة.
        _IconToggle(
          icon: LucideIcons.moveHorizontal,
          tooltip: fit ? t.actualSize : t.fitWidth,
          value: fit,
          onChanged: (_) => onFit(),
        ),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: onTap == null ? Colors.transparent : Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          hoverColor: Shade.surfaceHover,
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? Shade.textFaint : Shade.textMuted,
          ),
        ),
      ),
    ),
  );
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.icon,
    required this.tooltip,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String tooltip;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 30,
      height: 28,
      child: Material(
        color: value ? Shade.mirrorDeep : Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          child: Icon(
            icon,
            size: 16,
            color: value ? Shade.mirror : Shade.textMuted,
          ),
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Shade.canvas,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      border: Border.all(color: Shade.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Shade.textMuted),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Shade.border,
  );
}

/// مبدّل «قبل/بعد» — زرّان لا مؤشّر انزلاق: الحالة صريحة دائمًا.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Shade.canvas,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      border: Border.all(color: Shade.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++)
          MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: enabled ? () => onSelect(i) : null,
              child: AnimatedContainer(
                duration: Motion.quick,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: i == selected ? Shade.mirrorDeep : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: Type.semiBold,
                    color: !enabled
                        ? Shade.textFaint
                        : (i == selected ? Shade.mirror : Shade.textMuted),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
