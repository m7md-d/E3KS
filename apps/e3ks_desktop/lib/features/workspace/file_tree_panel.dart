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
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/app_menu.dart';

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
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      decoration: BoxDecoration(
        color: Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        border: Border.all(color: Shade.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // **رأسٌ يُرى رأسًا.** بلا حدٍّ يفصله يبدو العنوان وزرّاه صفًّا
          // أوّل في القائمة، فيلتبس ما يصفها بما فيها. والحدّ هو ما يقول
          // «هذا عنه لا منه».
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 6, 8),
            decoration: const BoxDecoration(
              // أرضيةٌ تفصله عن جسم الصندوق، وحدٌّ تحته. الحدّ وحده باهتٌ
              // على أرضيةٍ واحدة، فيبقى الرأس يبدو صفًّا أوّل في القائمة.
              color: Shade.surface,
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(Metrics.radiusSmall),
                topEnd: Radius.circular(Metrics.radiusSmall),
              ),
              border: Border(bottom: BorderSide(color: Shade.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.filesPanel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _Action(
                  icon: LucideIcons.filePlus,
                  tooltip: t.addFiles,
                  onTap: widget.onAddFiles,
                ),
                const SizedBox(width: 2),
                _Action(
                  icon: LucideIcons.folderPlus,
                  tooltip: t.addFolder,
                  onTap: widget.onAddFolder,
                ),
              ],
            ),
          ),
          Expanded(
            // **الفارغة تقول حالها ولا تُترك بيضاء** (`00` §5).
            child: roots.isEmpty
                ? Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      12,
                      12,
                      14,
                    ),
                    child: Text(
                      t.filesEmpty,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 8),
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
          _FileRow(
            // **مفتاحٌ بموضع الملفّ في المجموعة.** بدونه يُعاد استعمال حالة
            // الصفّ لملفٍّ آخر عند تغيّر الشجرة، فتنتقل قائمةٌ مفتوحة إلى
            // جاره.
            key: ValueKey(index),
            name: name,
            depth: depth,
            store: widget.store,
            index: index,
          ),
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

/// عرض مستوى العمق الواحد. **ثابتٌ لأن الخطوط تُرسم عليه**: كل خطٍّ إرشادي
/// يقع في منتصف مستواه، فتغيّرُ أحدهما دون الآخر يفكّ السلّم.
const double _step = 14;
const double _origin = 10;

/// خطوط العمق: خطٌّ رأسيّ لكل مستوى فوق هذا الصفّ.
///
/// **الإزاحة وحدها لا تكفي.** بلا خطٍّ يصير العمق تخمينًا بالعين: صفٌّ مزاح
/// عشرين بكسلًا وآخر أربعة عشر لا يُعرَف أيّهما ابنُ أيّ. والخطّ يصل الابن
/// بأبيه كما تفعل الأشجار الحقيقية.
class _Guides extends StatelessWidget {
  const _Guides({required this.depth, required this.child});

  final int depth;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (var level = 0; level < depth; level++)
        PositionedDirectional(
          start: _origin + level * _step + _step / 2,
          top: 0,
          bottom: 0,
          child: const SizedBox(
            width: 1,
            child: ColoredBox(color: Shade.border),
          ),
        ),
      child,
    ],
  );
}

double _indent(int depth) => _origin + depth * _step;

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
  Widget build(BuildContext context) => _Guides(
    depth: depth,
    child: InkWell(
      onTap: onTap,
      hoverColor: Shade.surfaceHover,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(_indent(depth), 6, 10, 6),
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
    ),
  );
}

/// ما يفعله المستخدم بملفٍّ من الشجرة.
///
/// **عائلتان لا تختلطان** (`ADR 0005` §٤): «راجعته» و«ملاحظة» قولُ المستخدم
/// عن الملفّ، والقفل قرارُه في التعديل عليه. وكلاهما منه لا من الفحص.
enum _FileAction { reviewed, locked, note, remove }

class _FileRow extends StatefulWidget {
  const _FileRow({
    super.key,
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
  State<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<_FileRow> {
  bool _hover = false;

  /// **قائمته مفتوحة الآن.** خروج المؤشّر إلى القائمة يُنهي التصويب، فلولا
  /// هذه لاختفى الزرّ من تحت القائمة المفتوحة — ولسقط الاختيار معه صامتًا،
  /// لأن `PopupMenuButton` تتجاهل ما وصلها وزرُّها غير مركَّب.
  bool _menuOpen = false;

  /// **قائمة واحدة لبابين**: الزرّ والضغطة اليمنى. قائمتان تنحرف إحداهما عن
  /// الأخرى عند أول إضافة، فيختلف ما يراه المستخدم باختلاف كيف وصل إليه.
  List<AppMenuEntry<_FileAction>> _items() {
    final t = context.l10n;
    final file = widget.store.files[widget.index];
    return [
      AppMenuChoice(
        value: _FileAction.reviewed,
        label: t.fileReviewed,
        selected: file.reviewed,
      ),
      AppMenuChoice(
        value: _FileAction.locked,
        label: t.fileLocked,
        selected: file.locked,
      ),
      AppMenuChoice(
        value: _FileAction.note,
        label: file.note == null ? t.fileNoteAdd : t.fileNoteEdit,
      ),
      const AppMenuSeparator(),
      AppMenuChoice(value: _FileAction.remove, label: t.removeFromSet),
    ];
  }

  Future<void> _run(_FileAction action) async {
    final store = widget.store;
    final index = widget.index;
    final file = store.files[index];
    switch (action) {
      case _FileAction.reviewed:
        store.setReviewed(index, !file.reviewed);
      case _FileAction.locked:
        store.setLocked(index, !file.locked);
      case _FileAction.note:
        final written = await _askNote(context, widget.name, file.note);
        if (written != null) store.setNote(index, written);
      case _FileAction.remove:
        store.removeFile(index);
    }
  }

  /// الضغطة اليمنى تفتح القائمة عند المؤشّر لا عند حافّة الصفّ.
  Future<void> _openAt(Offset position) async {
    setState(() => _menuOpen = true);
    final chosen = await showAppMenu<_FileAction>(
      context: context,
      at: position,
      items: _items(),
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (chosen != null) await _run(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final store = widget.store;
    final file = store.files[widget.index];
    final selected = store.activeIndex == widget.index;
    final changes = store.changeCountAt(widget.index);
    final shown = _hover || selected || _menuOpen;

    return _Guides(
      depth: widget.depth,
      child: Material(
        // **الصفّ يبقى معلَّمًا وقائمته مفتوحة.** بدونها تُفتح القائمة على
        // صفٍّ لا شيء يشير إليه، فلا يعرف المستخدم أي ملفّ يخاطب.
        color: selected
            ? Shade.mirrorDeep
            : (_menuOpen ? Shade.surfaceHover : Colors.transparent),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onSecondaryTapDown: (details) => _openAt(details.globalPosition),
            child: InkWell(
              onTap: () => store.selectDocument(widget.index),
              hoverColor: Shade.surfaceHover,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  _indent(widget.depth) + 17,
                  2,
                  4,
                  2,
                ),
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
                        widget.name,
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
                    if (file.reviewed)
                      Tooltip(
                        message: t.fileReviewed,
                        child: const Icon(
                          LucideIcons.check,
                          size: 13,
                          color: Shade.textMuted,
                        ),
                      ),
                    if (file.note case final note?)
                      Tooltip(
                        message: note,
                        child: const Padding(
                          padding: EdgeInsetsDirectional.only(start: 4),
                          child: Icon(
                            LucideIcons.messageSquare,
                            size: 12,
                            color: Shade.textMuted,
                          ),
                        ),
                      ),
                    if (file.locked)
                      Tooltip(
                        message: t.fileLocked,
                        child: const Padding(
                          padding: EdgeInsetsDirectional.only(start: 4),
                          child: Icon(
                            LucideIcons.lock,
                            size: 12,
                            color: Shade.textMuted,
                          ),
                        ),
                      ),
                    if (changes > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '$changes',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                    // **الباب يظهر عند التصويب.** زرٌّ دائم على كل صفّ يزاحم
                    // الاسم في شريطٍ عرضه ٢١٤، والضغطة اليمنى وحدها بابٌ لا
                    // يُرى.
                    SizedBox(
                      width: 22,
                      height: 22,
                      // **يبقى مركَّبًا ويختفي بالشفافية.** نزعُه من الشجرة
                      // عند انتهاء التصويب يُسقط اختيار القائمة المفتوحة.
                      // وما لا يُرى لا يُضغط، فالشفافية وحدها لا تمنع اللمس.
                      child: IgnorePointer(
                        ignoring: !shown,
                        child: AnimatedOpacity(
                          duration: Motion.instant,
                          curve: Motion.standard,
                          opacity: shown ? 1 : 0,
                          child: AppMenuButton<_FileAction>(
                            tooltip: t.fileActions,
                            items: _items,
                            onOpened: () => setState(() => _menuOpen = true),
                            onClosed: () {
                              if (mounted) setState(() => _menuOpen = false);
                            },
                            onSelected: _run,
                            child: const Icon(
                              LucideIcons.ellipsis,
                              size: 14,
                              color: Shade.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// حوار الملاحظة. يُرجع النصّ، أو `null` إن أُلغي.
Future<String?> _askNote(
  BuildContext context,
  String fileName,
  String? current,
) async {
  final controller = TextEditingController(text: current ?? '');
  final t = context.l10n;
  final written = await showAppDialog<String>(
    context,
    (context) => AlertDialog(
      title: Text(t.fileNote),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fileName, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            decoration: InputDecoration(hintText: t.fileNoteHint),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(t.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return written;
}

/// زرٌّ صغير في رأس الصندوق.
///
/// **بمقاسٍ مضبوط لا افتراضي**: `IconButton` يحجز ٤٠×٤٠ قبل أي كثافة، فيفيض
/// عن رأسٍ ارتفاعه أقلّ منه ويُنزل العنوان عن محوره.
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
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      hoverColor: Shade.surfaceHover,
      child: SizedBox(
        width: 26,
        height: 26,
        child: Icon(icon, size: 15, color: Shade.textMuted),
      ),
    ),
  );
}
