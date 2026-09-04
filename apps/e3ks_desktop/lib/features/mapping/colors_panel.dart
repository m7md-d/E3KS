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

class ColorsPanel extends StatefulWidget {
  const ColorsPanel({
    super.key,
    required this.store,
    required this.suggestions,
  });

  final WorkspaceStore store;
  final List<HexColor> suggestions;

  @override
  State<ColorsPanel> createState() => _ColorsPanelState();
}

class _ColorsPanelState extends State<ColorsPanel> {
  bool _showInherited = false;

  @override
  Widget build(BuildContext context) {
    final report = widget.store.report;
    if (report == null) return const SizedBox.shrink();
    final t = context.l10n;

    final identity = report.contentColors;
    final inherited = report.inheritedColors;

    return ListView(
      padding: const EdgeInsets.all(Metrics.gutter),
      children: [
        SectionHeader(
          title: t.identityColors,
          hint: t.identityColorsHint,
          count: identity.length,
        ),
        for (final usage in identity) _ColorRow(usage: usage, state: this),
        const SizedBox(height: 22),
        _InheritedSection(
          count: inherited.length,
          expanded: _showInherited,
          onToggle: () => setState(() => _showInherited = !_showInherited),
        ),
        if (_showInherited)
          for (final usage in inherited) _ColorRow(usage: usage, state: this),
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
      suggestions: widget.suggestions,
      // ألوان المستندات الأخرى المفتوحة، الأكثر استعمالًا أولًا.
      reference: store.otherDocumentColors(),
    );
    if (picked == null) return;
    store.mapColor(usage.color, picked == usage.color ? null : picked);
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.usage, required this.state});

  final ColorUsage usage;
  final _ColorsPanelState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    final target = state.widget.store.colorMap[usage.color];
    final changed = target != null;
    final parts = usage.byPart.keys
        .map((p) => partLabel(t, p))
        .toSet()
        .join('، ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: changed
            ? Shade.mirrorDeep.withValues(alpha: 0.35)
            : Shade.surface,
        borderRadius: BorderRadius.circular(Metrics.radius),
        border: Border.all(color: changed ? Shade.mirrorSoft : Shade.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Swatch(color: usage.color, size: 38),
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
              Icon(
                LucideIcons.moveLeft,
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
