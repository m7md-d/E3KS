/// شريط أدوات المعاينة.
///
/// **الكشف التدريجي قاعدته:** عند ضيق المساحة يختفي الأقلّ أهمية بترتيب
/// معلَن، ولا ينكسر الشريط أبدًا (`03`). ترتيب البقاء: قبل/بعد ← التنقّل بين
/// المطابقات ← الترقيم ← التكبير ← الانتقال إلى قسم.
///
/// مفصول عن `preview_panel.dart` لأن الملفّ تجاوز حدّ الأربعمئة سطر (`01`).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// `intl` تُصدّر `TextDirection` أيضًا، ونحن نريد التي في Flutter.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';
import '../../shared/arabic_digits.dart';

/// درجات التكبير المعلَنة. ١٫٠ = مقاس الورقة الحقيقي.
const List<double> zoomSteps = [0.5, 0.65, 0.8, 1.0, 1.25, 1.5, 2.0];

typedef SectionEntry = ({String title, int index});

class PreviewToolbar extends StatelessWidget {
  const PreviewToolbar({
    required this.store,
    required this.zoom,
    required this.fit,
    required this.numbers,
    required this.pageCount,
    required this.partial,
    required this.changeCount,
    required this.cursor,
    required this.sections,
    required this.page,
    required this.marks,
    required this.picking,
    required this.onPicking,
    required this.onZoom,
    required this.onFit,
    required this.onNumbers,
    required this.onMarks,
    required this.onSection,
    required this.onStep,
    required this.onGoToPage,
  });

  final WorkspaceStore store;
  final double zoom;
  final bool fit;
  final bool numbers;
  final int pageCount;

  /// المعاينة ناقصة: بقيّة الصفحات قيد الاستخراج، والعدد سيرتفع.
  ///
  /// **يُقال ولا يُخفى** (`00` §5): عدّادٌ يقول «من ٣٧» ثم يصير «من ١٧٣»
  /// بلا تفسير يجعل المستخدم يظنّ أنه فقد صفحات.
  final bool partial;
  final int changeCount;
  final int cursor;
  final List<SectionEntry> sections;

  /// الصفحة الظاهرة الآن، من ١.
  final int page;

  /// إظهار علامات التغيير على كل ما تغيّر.
  final bool marks;

  /// وضع التقاط اللون من الصفحة.
  final bool picking;

  final ValueChanged<bool> onPicking;

  final ValueChanged<double> onZoom;
  final VoidCallback onFit;
  final ValueChanged<bool> onNumbers;
  final ValueChanged<bool> onMarks;
  final void Function(int pageIndex) onSection;
  final void Function(int delta)? onStep;
  final void Function(int page) onGoToPage;

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
          // العتبات مقيسة لا مقدَّرة: المجموعة الثابتة (قبل/بعد + التنقّل +
          // منتقي اللون + مفتاح العلامات) تشغل الأساس، وكل أداة بعدها تُضيف
          // عرضها إلى عتبتها. اختبار الشاشات الضيّقة يحرسها من الانحراف.
          final showSections = width >= 1000 && sections.length > 1;
          final showZoom = width >= 840;
          final showNumbering = width >= 770;
          final showPage = width >= 710;

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
              Flexible(
                child: _Stepper(
                  count: changeCount,
                  cursor: cursor,
                  onStep: onStep,
                ),
              ),
              const SizedBox(width: 6),
              // منتقي اللون: **يشير المستخدم إلى اللون في صفحته**، فيُبرَز
              // ويُفتح صفّه في القائمة. الطريق الثالث بعد الضغط والعيّنة.
              _IconToggle(
                icon: LucideIcons.pipette,
                tooltip: picking ? t.cancelPicking : t.pickColorToTrack,
                value: picking,
                onChanged: onPicking,
              ),
              const SizedBox(width: 4),
              _IconToggle(
                icon: LucideIcons.squareDashedMousePointer,
                tooltip: t.showChangeMarks,
                value: marks,
                onChanged: onMarks,
              ),
              if (showPage) ...[
                const _Sep(),
                _PageField(
                  page: page,
                  total: pageCount,
                  onGoToPage: onGoToPage,
                ),
                if (partial) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: t.previewLoadingRest,
                    child: const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.6),
                    ),
                  ),
                ],
              ],
              if (showNumbering) ...[
                const SizedBox(width: 6),
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
        // النصّ قد يطول بالعربية («لا تغييرات») — يُقصّ ولا يدفع الشريط.
        Flexible(
          child: Text(
            active ? '${cursor < 0 ? 0 : cursor + 1} / $count' : t.noChangesYet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? Shade.textMuted : Shade.textFaint,
            ),
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
    final steps = direction > 0 ? zoomSteps : zoomSteps.reversed;
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

/// حقل رقم الصفحة: يُقرأ ويُكتب.
///
/// **يقبل ما نعرضه.** الواجهة العربية تكتب «صفحة ١٢»، فمن يكتب «١٢» ليقفز
/// إليها محقّ — ورفضُ ما عرضناه عليه عيبٌ فينا لا فيه. `parseFlexibleInt`
/// يقبل المجموعتين الهنديّتين والغربية.
class _PageField extends StatefulWidget {
  const _PageField({
    required this.page,
    required this.total,
    required this.onGoToPage,
  });

  final int page;
  final int total;
  final void Function(int page) onGoToPage;

  @override
  State<_PageField> createState() => _PageFieldState();
}

class _PageFieldState extends State<_PageField> {
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // بالخروج من الحقل تعود قيمته إلى الصفحة الظاهرة: مدخَلٌ نصف مكتوب
      // متروكًا في الحقل يكذب على المستخدم بموضعه.
      if (!_focus.hasFocus) _sync();
    });
  }

  @override
  void didUpdateWidget(_PageField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.page != old.page) _sync();
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// بأرقام لغة المستخدم — نفس ما يقرؤه على الورقة.
  void _sync() {
    final locale = Localizations.localeOf(context).toString();
    _field.text = NumberFormat.decimalPattern(locale).format(widget.page);
  }

  void _submit(String raw) {
    final page = parseFlexibleInt(raw);
    if (page == null || widget.total == 0) {
      _sync();
      return;
    }
    widget.onGoToPage(page.clamp(1, widget.total));
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_field.text.isEmpty) _sync();
    final t = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final total = NumberFormat.decimalPattern(locale).format(widget.total);

    return Tooltip(
      message: t.goToPage,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 46,
            height: 28,
            child: TextField(
              controller: _field,
              focusNode: _focus,
              textAlign: TextAlign.center,
              onSubmitted: _submit,
              onTapOutside: (_) => _focus.unfocus(),
              // لا نمنع الأرقام الهندية بمُرشِّح: المنع يجعل لوحة مفاتيح
              // عربية تبدو معطّلة. نقبل ثم نحوّل.
              inputFormatters: [LengthLimitingTextInputFormatter(6)],
              style: Theme.of(context).textTheme.labelSmall,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Shade.canvas,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Metrics.radiusSmall),
                  borderSide: const BorderSide(color: Shade.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Metrics.radiusSmall),
                  borderSide: const BorderSide(color: Shade.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Metrics.radiusSmall),
                  borderSide: const BorderSide(color: Shade.mirror),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('/ $total', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
