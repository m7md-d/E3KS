/// إشعار صغير: بعض خطوط المستند غير متاحة.
///
/// **صغير عمدًا.** المستخدم جاء ليبدّل ألوانًا لا ليعالج خطوطًا، لكنه يستحقّ
/// أن يعرف أن ما يراه ليس الملف تمامًا. الصمت هنا يجعل المعاينة كاذبة (`00` §5).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/font_service.dart';

class FontNotice extends StatelessWidget {
  const FontNotice({super.key, required this.service, required this.onDetails});

  final FontService service;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    if (service.working) {
      return _Bar(
        icon: LucideIcons.download,
        tone: Shade.textMuted,
        text: t.fontsFetching,
        busy: true,
      );
    }

    final missing = service.missing;
    if (missing.isEmpty) return const SizedBox.shrink();

    return _Bar(
      icon: LucideIcons.triangleAlert,
      tone: Shade.warning,
      text: missing.length == 1
          ? t.fontsMissingOne
          : t.fontsMissingMany(missing.length),
      action: TextButton(onPressed: onDetails, child: Text(t.showDetails)),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.icon,
    required this.tone,
    required this.text,
    this.action,
    this.busy = false,
  });

  final IconData icon;
  final Color tone;
  final String text;
  final Widget? action;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: 0.08),
      border: const Border(bottom: BorderSide(color: Shade.border)),
    ),
    child: Row(
      children: [
        if (busy)
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.6),
          )
        else
          Icon(icon, size: 14, color: tone),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        ?action,
      ],
    ),
  );
}
