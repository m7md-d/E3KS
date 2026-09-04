/// نتيجة التصدير: نجاح بتفصيل ما جرى، أو منع بتفسير واضح.
///
/// عند المنع لا يُكتب أي ملف — وهذا **أول** ما يُقال للمستخدم، لئلّا يبحث
/// عن ملف ناقص أو يظنّ العملية نجحت (`00` §١/٢).
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/document_loader.dart';

Future<void> showExportDone(
  BuildContext context,
  String path,
  TransformReport report,
) => showDialog<void>(
  context: context,
  builder: (context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    Widget line(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );

    return AlertDialog(
      backgroundColor: Shade.surface,
      title: Row(
        children: [
          const Icon(LucideIcons.circleCheck, color: Shade.success, size: 20),
          const SizedBox(width: 10),
          Text(t.exported),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              path,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 16),
            line(
              t.reportColorsReplaced,
              t.occurrences(report.totalColorReplacements),
            ),
            line(
              t.reportFontsReplaced,
              t.occurrences(report.totalFontReplacements),
            ),
            line(t.reportPartsChanged, '${report.changedParts.length}'),
            if (report.preservedFonts.isNotEmpty)
              line(
                t.reportFontsProtected,
                report.preservedFonts.keys.join('، '),
              ),
            if (report.unmatchedColors.isNotEmpty) ...[
              const SizedBox(height: 10),
              _Note(
                color: Shade.warning,
                text: t.reportUnmatched(
                  report.unmatchedColors.map((c) => c.value).join('، '),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.close),
        ),
      ],
    );
  },
);

Future<void> showExportBlocked(BuildContext context, LoadFailure failure) =>
    showDialog<void>(
      context: context,
      builder: (context) {
        final t = context.l10n;
        return AlertDialog(
          backgroundColor: Shade.surface,
          title: Row(
            children: [
              const Icon(
                LucideIcons.shieldAlert,
                color: Shade.danger,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(t.exportBlocked)),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.exportBlockedWhy,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                for (final line in failureLines(t, failure)) ...[
                  _Note(color: Shade.danger, text: line),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.close),
            ),
          ],
        );
      },
    );

class _Note extends StatelessWidget {
  const _Note({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}
