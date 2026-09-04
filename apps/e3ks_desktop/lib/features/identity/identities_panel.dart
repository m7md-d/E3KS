/// الهويات المحفوظة: احفظ ما بنيته، وطبّقه على مستند آخر بضغطة.
library;

import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/identity.dart';
import '../../data/identity_store.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/panel.dart';
import '../../shared/widgets/swatch.dart';

class IdentitiesPanel extends StatelessWidget {
  const IdentitiesPanel({
    super.key,
    required this.store,
    required this.identities,
  });

  final WorkspaceStore store;
  final IdentityStore identities;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(Metrics.gutter),
      children: [
        SectionHeader(
          title: t.tabIdentities,
          hint: t.identitiesHint,
          count: identities.items.length,
        ),
        // الزرّ في سطره: بجانب العنوان يحتاج عرضًا أكبر من اللوحة،
        // وبهذا الشكل هو أوضح أيضًا لمن لا يبحث عن أزرار صغيرة.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: store.hasChanges ? () => _save(context) : null,
            icon: const Icon(LucideIcons.bookmarkPlus, size: 16),
            label: Text(
              store.hasChanges ? t.saveIdentity : t.saveIdentityDisabled,
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (identities.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: EmptyNote(text: t.noIdentities, icon: LucideIcons.palette),
          ),
        for (final identity in identities.items)
          _IdentityCard(
            identity: identity,
            onApply: () => store.applyIdentity(identity),
            onDelete: () => identities.delete(identity),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final t = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    final colors = <NamedColor>[
      for (final target in store.colorMap.values.toSet())
        NamedColor(name: target.describe(t), hex: target),
    ];
    await identities.save(
      Identity(
        name: name.trim(),
        colors: colors,
        latinFont: store.latinFont,
        arabicFont: store.arabicFont,
        preserveFonts: store.preserveFonts.toList(),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.identity,
    required this.onApply,
    required this.onDelete,
  });

  final Identity identity;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    final fonts = [
      if (identity.arabicFont != null) identity.arabicFont!,
      if (identity.latinFont != null) identity.latinFont!,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Shade.surface,
        borderRadius: BorderRadius.circular(Metrics.radius),
        border: Border.all(color: Shade.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(identity.name, style: theme.textTheme.titleMedium),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(LucideIcons.trash2, size: 17),
                color: Shade.textFaint,
                tooltip: t.deleteIdentity,
              ),
              const SizedBox(width: 4),
              FilledButton(onPressed: onApply, child: Text(t.applyIdentity)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final color in identity.colors)
                Tooltip(
                  message: color.hex.value,
                  child: Swatch(color: color.hex, size: 24),
                ),
            ],
          ),
          if (fonts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(fonts, style: theme.textTheme.labelSmall),
          ],
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AlertDialog(
      backgroundColor: Shade.surface,
      title: Text(t.identityName),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.identityNameHint),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(t.save),
        ),
      ],
    );
  }
}
