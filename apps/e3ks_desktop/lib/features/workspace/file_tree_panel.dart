/// شجرة ملفات المجموعة.
///
/// **تظهر حين تصير المجموعة مجموعة.** ملفٌّ واحد لا يحتاج شجرةً، وعمودٌ
/// دائم يقتطع من المعاينة بلا مقابل (`03`).
///
/// وعلى كل صفٍّ عائلتان من العلامات لا تختلطان (`ADR 0005` §٤): **ما يقوله
/// المستخدم** — راجعته، ومقفل — و**ما يقوله الفحص**. خلطهما في شارةٍ واحدة
/// يجعل المستخدم يظنّ أن التطبيق قرّر عنه.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/file_tree.dart';
import '../../data/workspace_store.dart';

class FileTreePanel extends StatefulWidget {
  const FileTreePanel({
    super.key,
    required this.store,
    required this.onAddFiles,
    required this.onAddFolder,
  });

  final WorkspaceStore store;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  @override
  State<FileTreePanel> createState() => _FileTreePanelState();
}

class _FileTreePanelState extends State<FileTreePanel> {
  /// المجلدات المطويّة. **الافتراض مفتوح**: من فتح مجلدًا يريد أن يرى ما فيه.
  final Set<String> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final roots = widget.store.fileTree(t.looseFiles);

    return Container(
      width: Metrics.treeWidth,
      decoration: const BoxDecoration(
        color: Shade.surface,
        border: Border(right: BorderSide(color: Shade.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.filesPanel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _Action(
                  icon: LucideIcons.filePlus,
                  tooltip: t.addFiles,
                  onTap: widget.onAddFiles,
                ),
                _Action(
                  icon: LucideIcons.folderPlus,
                  tooltip: t.addFolder,
                  onTap: widget.onAddFolder,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [for (final root in roots) ..._root(root)],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _root(TreeRoot root) {
    final key = root.directory ?? '#${root.name}';
    return [
      _FolderRow(
        name: root.name,
        depth: 0,
        icon: root.directory == null
            ? LucideIcons.files
            : LucideIcons.folderOpen,
        collapsed: _collapsed.contains(key),
        onTap: () => setState(
          () => _collapsed.contains(key)
              ? _collapsed.remove(key)
              : _collapsed.add(key),
        ),
      ),
      if (!_collapsed.contains(key))
        for (final node in root.children) ..._node(node, key, 1),
    ];
  }

  List<Widget> _node(TreeNode node, String parent, int depth) {
    switch (node) {
      case FileNode(:final name, :final index):
        return [
          _FileRow(name: name, depth: depth, store: widget.store, index: index),
        ];
      case FolderNode(:final name, :final children):
        final key = '$parent/$name';
        final collapsed = _collapsed.contains(key);
        return [
          _FolderRow(
            name: name,
            depth: depth,
            icon: collapsed ? LucideIcons.folder : LucideIcons.folderOpen,
            collapsed: collapsed,
            onTap: () => setState(
              () => collapsed ? _collapsed.remove(key) : _collapsed.add(key),
            ),
          ),
          if (!collapsed)
            for (final child in children) ..._node(child, key, depth + 1),
        ];
    }
  }
}

double _indent(int depth) => 10 + depth * 12.0;

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.name,
    required this.depth,
    required this.icon,
    required this.collapsed,
    required this.onTap,
  });

  final String name;
  final int depth;
  final IconData icon;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    hoverColor: Shade.surfaceHover,
    child: Padding(
      padding: EdgeInsets.fromLTRB(_indent(depth), 6, 10, 6),
      child: Row(
        children: [
          Icon(
            collapsed ? LucideIcons.chevronRightDir : LucideIcons.chevronDown,
            size: 13,
            color: Shade.textFaint,
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: Shade.textMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.name,
    required this.depth,
    required this.store,
    required this.index,
  });

  final String name;
  final int depth;
  final WorkspaceStore store;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final tab = store.tabs[index];
    final selected = store.activeIndex == index;
    final changes = store.changeCountAt(index);

    return Material(
      color: selected ? Shade.mirrorDeep : Colors.transparent,
      child: InkWell(
        onTap: () => store.selectDocument(index),
        hoverColor: Shade.surfaceHover,
        child: Padding(
          padding: EdgeInsets.fromLTRB(_indent(depth) + 17, 6, 10, 6),
          child: Row(
            children: [
              Icon(
                LucideIcons.fileText,
                size: 13,
                color: selected ? Shade.mirror : Shade.textFaint,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: selected ? Shade.mirror : Shade.text,
                    fontWeight: selected ? Type.semiBold : Type.regular,
                  ),
                ),
              ),
              // **ما يقوله المستخدم** — قرارٌ منه، وشاراته أوّلًا.
              if (tab.reviewed)
                Tooltip(
                  message: t.fileReviewed,
                  child: const Icon(
                    LucideIcons.check,
                    size: 13,
                    color: Shade.textMuted,
                  ),
                ),
              if (tab.locked)
                Tooltip(
                  message: t.fileLocked,
                  child: const Icon(
                    LucideIcons.lock,
                    size: 12,
                    color: Shade.textMuted,
                  ),
                ),
              if (changes > 0) ...[
                const SizedBox(width: 6),
                Text('$changes', style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, size: 15),
    color: Shade.textMuted,
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
  );
}
