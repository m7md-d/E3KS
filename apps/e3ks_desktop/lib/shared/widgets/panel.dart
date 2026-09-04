/// لبنات بصرية مشتركة.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// سطح مرتفع بحدّ خفيف — الحاوية الأساسية في كل الشاشات.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Metrics.gutter),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color ?? Shade.surface,
      borderRadius: BorderRadius.circular(Metrics.radius),
      border: Border.all(color: Shade.border),
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// عنوان قسم مع شرح تحته. الشرح ليس زينة: مستخدمنا موظف مكتبي،
/// وكلمة «موروثة من قوالب Word» توفّر عليه قرارًا خاطئًا.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.hint,
    this.trailing,
    this.count,
  });

  final String title;
  final String? hint;
  final Widget? trailing;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (count != null) ...[
                      const SizedBox(width: 8),
                      _Pill(label: '$count'),
                    ],
                  ],
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(hint!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: Shade.surfaceHover,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

/// حالة فارغة مفهومة: ما الذي ينقص، وماذا يفعل المستخدم.
class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key, required this.text, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 34, color: Shade.textFaint),
          const SizedBox(height: 12),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
