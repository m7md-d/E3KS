/// شريط تبويبات المستندات المفتوحة.
///
/// يظهر فقط عند فتح ملف ثانٍ — الملف الواحد لا يحتاج تبويبًا، وإظهاره
/// دائمًا يسرق سطرًا من المعاينة بلا مقابل.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';

class DocumentTabs extends StatelessWidget {
  const DocumentTabs({super.key, required this.store, required this.onAdd});

  final WorkspaceStore store;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (store.tabs.length < 2) return const SizedBox.shrink();
    final t = context.l10n;

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Shade.canvas,
        border: Border(bottom: BorderSide(color: Shade.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              itemCount: store.tabs.length,
              itemBuilder: (context, i) => _Tab(
                label: store.tabs[i].document.fileName,
                changes: store.tabs[i].changeCount,
                selected: i == store.activeIndex,
                onTap: () => store.selectDocument(i),
                onClose: () => store.closeDocument(i),
              ),
            ),
          ),
          Tooltip(
            message: t.chooseFile,
            child: IconButton(
              onPressed: onAdd,
              icon: const Icon(LucideIcons.plus, size: 16),
              color: Shade.textMuted,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.changes,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final String label;
  final int changes;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Material(
      color: selected ? Shade.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        hoverColor: Shade.surfaceHover,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 230),
          padding: const EdgeInsets.only(left: 6, right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Metrics.radiusSmall),
            border: Border.all(
              color: selected ? Shade.mirrorSoft : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.fileText,
                size: 13,
                color: selected ? Shade.mirror : Shade.textFaint,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: selected ? Shade.text : Shade.textMuted,
                    fontWeight: selected ? Type.semiBold : Type.regular,
                  ),
                ),
              ),
              if (changes > 0) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Shade.mirror,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(3),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(LucideIcons.x, size: 12, color: Shade.textFaint),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
