/// لوحة الألوان — قلب التطبيق.
///
/// كل صفّ يجيب على أربعة أسئلة يسألها موظف مكتبي: ما هذا اللون؟ أين يظهر؟
/// كم مرّة؟ وعلى أي نصّ؟ ثم يعطيه فعلًا واحدًا: بدّله.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/panel.dart';
import '../../shared/widgets/swatch.dart';
import 'color_picker.dart';
import 'scope_box.dart';

class ColorsPanel extends StatefulWidget {
  const ColorsPanel({
    super.key,
    required this.store,
    required this.suggestions,
  });

  final WorkspaceStore store;

  /// ألوان مسمّاة جاهزة للّصق: من الهويات المحفوظة ومن الملفات المفتوحة.
  final List<QuickPickGroup> suggestions;

  @override
  State<ColorsPanel> createState() => _ColorsPanelState();
}

class _ColorsPanelState extends State<ColorsPanel> {
  bool _showInherited = false;

  /// مفاتيح الصفوف — **تُنشأ في الحالة لا في `build`.** مفتاحٌ جديد كل رسمة
  /// يعني سياقًا ضائعًا، وهذا بعينه سبب أن أسهم المعاينة لم تكن تعمل يومًا.
  final Map<String, GlobalKey> _rowKeys = {};
  final ScrollController _scroll = ScrollController();
  String? _scrolledTo;

  /// ترتيب الصفوف المعروضة — يلزم للتقدير حين لا يكون الصفّ مبنيًّا بعد.
  List<String> _order = const [];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(HexColor color) =>
      _rowKeys.putIfAbsent(color.value, GlobalKey.new);

  /// صفوف مبنيّة، تُعاد **بذاتها** ما لم يتغيّر ما يخصّ صفَّها.
  ///
  /// **لماذا:** `notifyListeners()` تعيد بناء الشاشة كلّها، وقياسُ الإطار
  /// الخامل قال إن هذه اللوحة وحدها ١٦ms من ٢٨ — الصفوف المرئية تُعاد
  /// بناءً وتخطيطًا في كل إشعار ولو لم يمسّها شيء. و`Element.updateChild`
  /// يتخطّى الشجرة الفرعية حين تكون الودجة هي هي.
  ///
  /// **والمفتاح لكل صفٍّ حاله هو**: تبديلُ لونٍ يُسقط صفَّه وحده، لا الصفوف
  /// كلّها — وهذا ما يجعل الذاكرة تنفع أصلًا.
  final Map<String, ({Widget row, bool focused, String? target, String scope})>
  _rows = {};

  Widget _rowFor(ColorUsage usage, HexColor? focused) {
    final store = widget.store;
    final key = usage.color.value;
    final isFocused = focused?.value == key;
    final target = store.colorMap[usage.color]?.value;
    // **الطبقة جزءٌ من حال الصفّ**: نقلُ قاعدةٍ بين الطبقتين لا يغيّر بديلها،
    // فبصمةٌ بالبديل وحده تُبقي المربّع على حاله الأول ولا يستجيب لضغطة.
    final scope =
        '${store.canScope}'
        '${store.isFileSpecific(usage.color)}'
        '${store.isColorExcluded(usage.color)}';
    final cached = _rows[key];
    if (cached != null &&
        cached.focused == isFocused &&
        cached.target == target &&
        cached.scope == scope) {
      return cached.row;
    }
    final row = _ColorRow(
      key: _keyFor(usage.color),
      usage: usage,
      state: this,
      focused: isFocused,
    );
    _rows[key] = (row: row, focused: isFocused, target: target, scope: scope);
    return row;
  }

  /// يمرّر إلى اللون المتتبَّع بعد أن تُبنى صفوفه.
  ///
  /// **هذا نصف الجسر الثاني**: الضغط في الصفحة يتتبّع اللون، وهذا يُظهره في
  /// القائمة. بلا التمرير يبقى اللون مختارًا في مكان لا يراه المستخدم.
  void _revealFocused() {
    final focused = widget.store.focusedColor;
    if (focused == null) {
      _scrolledTo = null;
      return;
    }
    if (_scrolledTo == focused.value) return;
    _scrolledTo = focused.value;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(focused));
  }

  /// يقفز إلى صفٍّ قد لا يكون مبنيًّا بعد.
  ///
  /// القائمة تبني المرئي وما حوله فقط، فمفتاح صفٍّ بعيد بلا سياق. نقفز أولًا
  /// بتقدير من موضعه في الترتيب، ثم نضبط بدقّة بعد أن يُبنى — نفس ما تفعله
  /// أسهم المعاينة، وللسبب نفسه.
  Future<void> _scrollTo(HexColor color) async {
    if (!mounted) return;

    if (_rowKeys[color.value]?.currentContext == null && _scroll.hasClients) {
      final index = _order.indexOf(color.value);
      if (index >= 0 && _order.isNotEmpty) {
        final extent =
            _scroll.position.maxScrollExtent +
            _scroll.position.viewportDimension;
        final target = (extent / _order.length) * index;
        _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
        await WidgetsBinding.instance.endOfFrame;
      }
    }

    final settled = _rowKeys[color.value]?.currentContext;
    if (settled == null || !mounted) return;
    await Scrollable.ensureVisible(
      settled,
      alignment: 0.1,
      duration: Motion.normal,
      curve: Motion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.store.report;
    final t = context.l10n;
    // **الفحص خارج مسار أوّل رسمة**، فالصفحة تُعرَض قبل أن يصل. ولوحةٌ بيضاء
    // في تلك اللحظة تقول «لا شيء هنا» وهي كاذبة (`00` §5).
    if (report == null) {
      return Padding(
        padding: const EdgeInsets.all(Metrics.gutter),
        child: EmptyNote(text: t.inspectingDocument, icon: LucideIcons.palette),
      );
    }

    final identity = report.contentColors;
    final inherited = report.inheritedColors;
    final focused = widget.store.focusedColor;

    // لونٌ متتبَّع من القسم الموروث يفتح القسم: لا معنى لتمرير إلى صفّ مطويّ.
    if (focused != null &&
        !_showInherited &&
        inherited.any((c) => c.color.value == focused.value)) {
      _showInherited = true;
    }
    _order = [
      for (final usage in identity) usage.color.value,
      if (_showInherited)
        for (final usage in inherited) usage.color.value,
    ];
    _revealFocused();

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(Metrics.gutter),
      children: [
        SectionHeader(
          title: t.identityColors,
          hint: t.identityColorsHint,
          count: identity.length,
        ),
        for (final usage in identity) _rowFor(usage, focused),
        const SizedBox(height: 22),
        _InheritedSection(
          count: inherited.length,
          expanded: _showInherited,
          onToggle: () => setState(() => _showInherited = !_showInherited),
        ),
        if (_showInherited)
          for (final usage in inherited) _rowFor(usage, focused),
        const SizedBox(height: 30),
      ],
    );
  }

  Future<void> _edit(ColorUsage usage) async {
    final store = widget.store;
    final picked = await pickColor(
      context,
      original: usage.color,
      current: store.colorMap[usage.color],
      quickPicks: widget.suggestions,
    );
    if (picked == null) return;
    // **حيث تسكن القاعدة تُكتب**: رفعُ قاعدةٍ خاصّة بافتراضٍ عامّ يمحو من
    // العامّة ما ليس فيها، فلا يتغيّر شيء على الشاشة.
    store.mapColor(
      usage.color,
      picked == usage.color ? null : picked,
      store.scopeForColor(usage.color),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    super.key,
    required this.usage,
    required this.state,
    this.focused = false,
  });

  final ColorUsage usage;
  final _ColorsPanelState state;

  /// متتبَّع الآن: مُبرَز هنا ومُحاط في الصفحة، فيربط المستخدم بينهما.
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    final store = state.widget.store;
    final target = store.colorMap[usage.color];
    final changed = target != null;
    final excluded = store.isColorExcluded(usage.color);
    final parts = usage.byPart.keys
        .map((p) => partLabel(t, p))
        .toSet()
        .join('، ');

    return AnimatedContainer(
      duration: Motion.quick,
      curve: Motion.standard,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: changed
            ? Shade.mirrorDeep.withValues(alpha: 0.35)
            : Shade.surface,
        borderRadius: BorderRadius.circular(Metrics.radius),
        border: Border.all(
          color: focused
              ? Shade.mirror
              : (changed ? Shade.mirrorSoft : Shade.border),
          width: focused ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // الضغط على العيّنة يتتبّع اللون في الصفحة — الطريق العكسي
              // للضغط على اللون في المعاينة.
              Tooltip(
                message: t.tapColorHint,
                child: Swatch(
                  color: usage.color,
                  size: 38,
                  selected: focused,
                  onTap: () => state.widget.store.focusColor(usage.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          usage.color.value,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        // الوصف قد يطول («رمادي/محايد فاتح جدًا») واللوحة
                        // ثابتة العرض — يُقصّ ولا يدفع الصفّ خارج حدوده.
                        Flexible(
                          child: Text(
                            usage.color.describe(t),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.colorUsage(
                        usage.count,
                        usage.dominantRole.label(t),
                        parts,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // السهم يتبع اتجاه القراءة: من المصدر إلى البديل. أيقونة
              // ثابتة الاتجاه تنقلب معناها في الإنجليزية.
              Icon(
                LucideIcons.moveRightDir,
                size: 16,
                color: changed ? Shade.mirror : Shade.textFaint,
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: changed ? usage.color.value : t.pickReplacement,
                child: Swatch(
                  color: target,
                  size: 38,
                  dashed: !changed,
                  selected: changed,
                  onTap: () => state._edit(usage),
                ),
              ),
            ],
          ),
          // **الطبقة تُقال على القاعدة نفسها**، ولا تُقال حيث لا معنى لها:
          // مجموعةٌ فيها ملفّ واحد ليست فيها طبقتان.
          if (store.canScope && (changed || excluded)) ...[
            const SizedBox(height: 6),
            ScopeBox(
              specific: store.isFileSpecific(usage.color),
              excluded: excluded,
              onChanged: (value) => store.setColorScope(
                usage.color,
                value ? EditScope.file : EditScope.general,
              ),
            ),
          ],
          if (usage.samples.isNotEmpty) ...[
            const SizedBox(height: 10),
            // عيّنة النصّ تُرسَم بلون اللون نفسه على خلفية فاتحة — يفهمها
            // المستخدم في لمحة بلا أن يقرأ رقمًا سداسيًا.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Shade.canvas,
                borderRadius: BorderRadius.circular(Metrics.radiusSmall),
              ),
              child: Text(
                usage.samples.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: usage.dominantRole == ColorRole.text
                      ? toFlutter(usage.color)
                      : Shade.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InheritedSection extends StatelessWidget {
  const _InheritedSection({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final t = context.l10n;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(Metrics.radius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SectionHeader(
          title: t.inheritedColors,
          hint: t.inheritedColorsHint,
          count: count,
          trailing: Icon(
            expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 18,
            color: Shade.textMuted,
          ),
        ),
      ),
    );
  }
}
