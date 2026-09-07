/// لوحة العلامات على النصّ: قلم التمييز وتظليل الخلفية.
///
/// **الحاجة التي تخدمها:** ملفّ يصل المستخدم وفيه أثر تحديدٍ يستعصي على
/// وورد نفسه — تظليلٌ في `w:rPr` لا يرفعه قلم التمييز لأنه ليس تمييزًا.
/// هنا يراه بعدده وعيّنة نصّه، ويرفعه واحدةً واحدة أو دفعةً واحدة.
///
/// الفعل هنا **رفعٌ لا تبديل**، وهذا ما يفصلها عن لوحة الألوان: لون
/// التظليل يظهر في الجدولين، يُبدَّل هناك ويُمسح هنا.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/panel.dart';
import 'scope_box.dart';
import '../../shared/widgets/swatch.dart';

class MarksPanel extends StatelessWidget {
  const MarksPanel({super.key, required this.store});

  final WorkspaceStore store;

  @override
  Widget build(BuildContext context) {
    final report = store.report;
    final t = context.l10n;
    // **الفحص خارج مسار أوّل رسمة**، فالصفحة تُعرَض قبل أن يصل. ولوحةٌ بيضاء
    // في تلك اللحظة تقول «لا شيء هنا» وهي كاذبة (`00` §5).
    if (report == null) {
      return Padding(
        padding: const EdgeInsets.all(Metrics.gutter),
        child: EmptyNote(
          text: t.inspectingDocument,
          icon: LucideIcons.highlighter,
        ),
      );
    }

    final marks = report.marks;
    final lifted = store.liftedMarks;
    final all = marks.isNotEmpty && marks.every((m) => lifted.contains(m.mark));

    return ListView(
      padding: const EdgeInsets.all(Metrics.gutter),
      children: [
        SectionHeader(
          title: t.marksTitle,
          hint: t.marksHint,
          count: marks.length,
          trailing: marks.isEmpty
              ? null
              // فعلٌ واحد للجدول كلّه: من وصله ملفّ مليء بالتحديد يريده
              // كلّه، وضغطُ عشرين صفًّا عقوبة لا أداة.
              : TextButton(
                  onPressed: () => store.liftAllMarks(!all, store.defaultScope),
                  child: Text(all ? t.keepAll : t.liftAll),
                ),
        ),
        if (marks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              t.noMarks,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        for (final usage in marks)
          _MarkRow(
            usage: usage,
            store: store,
            lifted: lifted.contains(usage.mark),
            focused: store.focusedMark == usage.mark,
          ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _MarkRow extends StatelessWidget {
  const _MarkRow({
    required this.usage,
    required this.store,
    required this.lifted,
    required this.focused,
  });

  final MarkUsage usage;
  final WorkspaceStore store;

  /// مطلوبٌ رفعها عند التصدير.
  final bool lifted;

  /// متتبَّعة الآن: مُبرَزة هنا ومُبرَزة في الصفحة، فيربط المستخدم بينهما.
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    final mark = usage.mark;
    final color = mark.color;
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
        color: lifted
            ? Shade.mirrorDeep.withValues(alpha: 0.35)
            : Shade.surface,
        borderRadius: BorderRadius.circular(Metrics.radius),
        border: Border.all(
          color: focused
              ? Shade.mirror
              : (lifted ? Shade.mirrorSoft : Shade.border),
          width: focused ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // الضغط على العيّنة يتتبّع العلامة في الصفحة — الطريق العكسي
              // للضغط على النصّ المعلَّم في المعاينة.
              Tooltip(
                message: t.tapMarkHint,
                child: Swatch(
                  color: color,
                  size: 38,
                  dashed: color == null,
                  selected: focused,
                  onTap: () => store.focusMark(mark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // المفتاح كما يعلنه المستند: اسم المواصفة للقلم
                        // (`yellow`)، والسداسي للتظليل. وهو نفسه ما يُكتب
                        // في خطة سطر الأوامر، فلا يُترجَم ولا يُستبدَل
                        // بلونه — الاسم أدلّ على مصدره.
                        Text(
                          mark.key,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            color?.describe(t) ?? mark.kind.label(t),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.markUsage(usage.count, mark.kind.label(t), parts),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _LiftButton(
                lifted: lifted,
                onTap: () =>
                    store.liftMark(mark, !lifted, store.scopeForMark(mark)),
              ),
            ],
          ),
          // **الطبقة تُقال على العلامة المرفوعة نفسها** — كما على اللون.
          if (store.canScope && lifted) ...[
            const SizedBox(height: 6),
            ScopeBox(
              specific: store.isMarkSpecific(mark),
              onChanged: (value) => store.setMarkScope(
                mark,
                value ? EditScope.file : EditScope.general,
              ),
            ),
          ],
          if (usage.samples.isNotEmpty) ...[
            const SizedBox(height: 10),
            // العيّنة تُرسَم على أرضية العلامة نفسها: يفهمها المستخدم في
            // لمحة بلا أن يقرأ رقمًا سداسيًا.
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
                // النصّ على أرضية العلامة نفسها، بحبرٍ يُقرأ عليها:
                // الرمادي الفاتح يذوب في الأصفر، والقارئ يرى شريطًا فارغًا.
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color == null
                      ? Shade.textMuted
                      : (color.relativeLuminance > 0.35
                            ? Paper.ink
                            : Paper.sheet),
                  backgroundColor: color == null ? null : toFlutter(color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// زرّ الرفع: حالته تُقرأ بلا نصّ، ونصّه يؤكّدها.
class _LiftButton extends StatelessWidget {
  const _LiftButton({required this.lifted, required this.onTap});

  final bool lifted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Tooltip(
      message: lifted ? t.markLifted : t.liftMark,
      child: Material(
        color: lifted ? Shade.mirrorDeep : Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          hoverColor: Shade.surfaceHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  lifted ? LucideIcons.check : LucideIcons.eraser,
                  size: 15,
                  color: lifted ? Shade.mirror : Shade.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  lifted ? t.markLifted : t.liftMark,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: lifted ? Shade.mirror : Shade.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
