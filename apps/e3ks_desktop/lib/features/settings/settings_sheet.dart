/// الإعدادات: خطوط المستندات وما تستهلكه من قرص المستخدم.
///
/// المستخدم يرى **ما جلبناه، وكم يزن، ومن أين جاء كل خطّ**، ويحذف ما شاء.
/// جلبنا ملفات إلى قرصه، فمن حقّه أن يراها ويتحكّم بها.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/font_cache.dart';
import '../../data/font_service.dart';
import '../../shared/widgets/panel.dart';

Future<void> showSettings(BuildContext context, FontService fonts) =>
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Shade.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Metrics.radius),
          side: const BorderSide(color: Shade.border),
        ),
        child: SizedBox(
          width: 620,
          height: 560,
          child: _SettingsBody(fonts: fonts),
        ),
      ),
    );

class _SettingsBody extends StatefulWidget {
  const _SettingsBody({required this.fonts});
  final FontService fonts;

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cached = widget.fonts.cache.list();
    final total = cached.fold(0, (sum, f) => sum + f.bytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Metrics.gutter,
            Metrics.gutter,
            Metrics.gutter,
            0,
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.settings, size: 18, color: Shade.mirror),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.settings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x, size: 16),
                color: Shade.textFaint,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Metrics.gutter),
            children: [
              SectionHeader(title: t.fontsSection, hint: t.fontsSectionHint),

              // الجلب: قرار المستخدم لا قرارنا.
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.fetchFonts,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.fetchFontsHint,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: widget.fonts.fetchEnabled,
                      activeThumbColor: Shade.mirror,
                      onChanged: (v) =>
                          setState(() => widget.fonts.setFetchEnabled(v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              SectionHeader(
                title: t.cachedFonts,
                count: cached.length,
                hint: '${t.cacheSize}: ${formatBytes(total)}',
                trailing: cached.isEmpty
                    ? null
                    : TextButton.icon(
                        onPressed: () => setState(widget.fonts.forgetAll),
                        icon: const Icon(LucideIcons.trash2, size: 14),
                        label: Text(t.deleteAllFonts),
                      ),
              ),
              if (cached.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: EmptyNote(
                    text: t.noCachedFonts,
                    icon: LucideIcons.type,
                  ),
                )
              else ...[
                for (final font in cached)
                  _CachedRow(
                    font: font,
                    onDelete: () => setState(() => widget.fonts.forget(font)),
                  ),
                const SizedBox(height: 8),
                Text(
                  t.fontDeletedNote,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],

              if (widget.fonts.statuses.isNotEmpty) ...[
                const SizedBox(height: 26),
                SectionHeader(
                  title: t.fontsSection,
                  count: widget.fonts.statuses.length,
                ),
                for (final status in widget.fonts.statuses)
                  _StatusRow(status: status),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CachedRow extends StatelessWidget {
  const _CachedRow({required this.font, required this.onDelete});

  final CachedFont font;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
    decoration: BoxDecoration(
      color: Shade.canvas,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      border: Border.all(color: Shade.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            font.family,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          formatBytes(font.bytes),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(LucideIcons.trash2, size: 15),
          color: Shade.textFaint,
          visualDensity: VisualDensity.compact,
          tooltip: context.l10n.deleteFont,
        ),
      ],
    ),
  );
}

/// من أين جاء كل خطّ — أو لماذا لم يأتِ.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});
  final FontStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final ok = status.origin.isResolved;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? LucideIcons.check : LucideIcons.triangleAlert,
            size: 13,
            color: ok ? Shade.success : Shade.warning,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              status.family,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            status.origin.label(t),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
