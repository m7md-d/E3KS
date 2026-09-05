/// شريط متابعة اللون.
///
/// **الحاجة التي يخدمها:** لون سقط سهوًا في زاوية من مستند من أربعين صفحة.
/// جدول الألوان يقول «‏٣ مواضع»، لكنه لا يقول **أين**. هذا الشريط يتنقّل
/// بينها كما يتنقّل `Ctrl+F` بين المطابقات.
///
/// يظهر فقط عند متابعة لون — شريطٌ دائم يأكل من مساحة الورقة بلا مقابل.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../shared/widgets/swatch.dart';

class ColorFocusBar extends StatelessWidget {
  const ColorFocusBar({
    super.key,
    required this.color,
    required this.matches,
    required this.cursor,
    required this.onStep,
    required this.onClear,
  });

  final HexColor color;

  /// عدد الصفحات التي يظهر فيها اللون.
  final int matches;

  /// موضع المؤشّر بين المطابقات، أو ‎-1‎ قبل أول قفزة.
  final int cursor;

  final void Function(int delta)? onStep;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final active = matches > 0;

    return Container(
      height: 46,
      padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
      decoration: const BoxDecoration(
        color: Shade.mirrorDeep,
        border: Border(bottom: BorderSide(color: Shade.mirrorSoft)),
      ),
      child: Row(
        children: [
          Swatch(color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            color.value,
            textDirection: TextDirection.ltr,
            style: text.bodyMedium?.copyWith(fontWeight: Type.semiBold),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              t.focusedColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: Shade.mirror),
            ),
          ),
          const Spacer(),
          Text(
            active ? '${cursor < 0 ? 0 : cursor + 1} / $matches' : t.noMatches,
            textDirection: TextDirection.ltr,
            style: text.labelSmall?.copyWith(
              color: active ? Shade.mirror : Shade.textFaint,
            ),
          ),
          const SizedBox(width: 8),
          _Step(
            icon: LucideIcons.chevronUp,
            tooltip: t.previousMatch,
            onTap: active && cursor > 0 ? () => onStep?.call(-1) : null,
          ),
          const SizedBox(width: 4),
          _Step(
            icon: LucideIcons.chevronDown,
            tooltip: t.nextMatch,
            onTap: active && cursor < matches - 1
                ? () => onStep?.call(1)
                : null,
          ),
          const SizedBox(width: 6),
          _Step(icon: LucideIcons.x, tooltip: t.clearFocus, onTap: onClear),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.tooltip, required this.onTap});

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
        color: onTap == null ? Shade.transparent : Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          hoverColor: Shade.surfaceHover,
          child: Icon(
            icon,
            size: 15,
            color: onTap == null ? Shade.textFaint : Shade.mirror,
          ),
        ),
      ),
    ),
  );
}
