/// لوحة الخطوط.
///
/// الفصل بين العربي والإنجليزي ظاهر في الواجهة لا مخفيًا في الكود: دمجهما
/// في حقل واحد يكسر أحدهما، والمستخدم لن يعرف لماذا.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/font_suggestions.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/panel.dart';

class FontsPanel extends StatelessWidget {
  const FontsPanel({super.key, required this.store});

  final WorkspaceStore store;

  @override
  Widget build(BuildContext context) {
    final report = store.report;
    if (report == null) return const SizedBox.shrink();
    final t = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(Metrics.gutter),
      children: [
        SectionHeader(title: t.tabFonts, hint: t.fontsHint),
        _FontField(
          label: t.arabicFont,
          value: store.arabicFont,
          suggestions: arabicFontSuggestions,
          onChanged: store.setArabicFont,
        ),
        const SizedBox(height: 12),
        _FontField(
          label: t.latinFont,
          value: store.latinFont,
          suggestions: latinFontSuggestions,
          onChanged: store.setLatinFont,
        ),
        const SizedBox(height: 26),
        SectionHeader(
          title: t.protectedFonts,
          hint: t.protectedFontsHint,
          count: store.preserveFonts.length,
        ),
        for (final font in report.fonts)
          _ProtectedRow(
            font: font,
            protected: store.preserveFonts.contains(font.name),
            onChanged: (v) => store.togglePreserved(font.name, v),
          ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _FontField extends StatelessWidget {
  const _FontField({
    required this.label,
    required this.value,
    required this.suggestions,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> suggestions;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.titleSmall),
              const Spacer(),
              if (value != null)
                TextButton(
                  onPressed: () => onChanged(null),
                  child: Text(context.l10n.keepAsIs),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in suggestions)
                _FontChip(
                  name: name,
                  selected: value == name,
                  onTap: () => onChanged(value == name ? null : name),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Shade.mirrorDeep : Shade.canvas,
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          border: Border.all(color: selected ? Shade.mirror : Shade.border),
        ),
        child: Text(
          name,
          // نرسم الاسم بالخط نفسه: إن كان منصّبًا رآه المستخدم فورًا.
          style: TextStyle(
            fontFamily: name,
            fontSize: 13,
            color: selected ? Shade.mirror : Shade.text,
            fontWeight: selected ? Type.semiBold : Type.regular,
          ),
        ),
      ),
    ),
  );
}

class _ProtectedRow extends StatelessWidget {
  const _ProtectedRow({
    required this.font,
    required this.protected,
    required this.onChanged,
  });

  final FontUsage font;
  final bool protected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Shade.surface,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        border: Border.all(color: Shade.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  font.name,
                  style: TextStyle(
                    fontFamily: font.name,
                    fontSize: 13,
                    color: Shade.text,
                  ),
                ),
                Text(
                  font.looksMonospaced
                      ? '${t.occurrences(font.count)} · ${t.likelyCodeFont}'
                      : t.occurrences(font.count),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Switch(
            value: protected,
            onChanged: onChanged,
            activeThumbColor: Shade.mirror,
          ),
        ],
      ),
    );
  }
}
