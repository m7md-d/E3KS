/// الشريط الجانبي: التنقّل بين اللوحات، وشجرة الملفات، ومعلومات المستند.
///
/// **الترتيب من فوق إلى تحت هو ترتيب الاستعمال**: التنقّل بين الأدوات، ثم
/// الملفّ الذي تعمل عليه، ثم حقائقه. والشجرة تملأ ما كان فراغًا بينهما.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';
import 'file_tree_panel.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.store,
    required this.onAddFiles,
    required this.onAddFolder,
    this.compact = false,
  });

  final WorkspaceStore store;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  /// نافذة ضيّقة: **الشريط يضيق ولا يُطوى**.
  ///
  /// كان يصير أيقوناتٍ بلا نصّ، فتختفي معه شجرة الملفات — وهي أداة عمل لا
  /// زينة. والشحّ ما زال يُقتطع من هنا أوّلًا (`03`)، لكن اقتطاعًا في العرض
  /// لا إخفاءً لما بداخله.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final report = store.report;
    final t = context.l10n;
    return Container(
      width: compact ? Metrics.sidebarNarrow : Metrics.sidebarWidth,
      decoration: const BoxDecoration(
        color: Shade.surface,
        border: Border(right: BorderSide(color: Shade.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          _NavItem(
            icon: LucideIcons.palette,
            label: t.tabColors,
            badge: report == null ? null : '${report.contentColors.length}',
            selected: store.tab == WorkspaceTab.colors,
            changes: store.colorMap.length,
            compact: compact,
            onTap: () => store.selectTab(WorkspaceTab.colors),
          ),
          _NavItem(
            icon: LucideIcons.type,
            label: t.tabFonts,
            badge: report == null ? null : '${report.fonts.length}',
            selected: store.tab == WorkspaceTab.fonts,
            changes:
                (store.latinFont != null ? 1 : 0) +
                (store.arabicFont != null ? 1 : 0),
            compact: compact,
            onTap: () => store.selectTab(WorkspaceTab.fonts),
          ),
          _NavItem(
            icon: LucideIcons.highlighter,
            label: t.tabMarks,
            badge: report == null ? null : '${report.marks.length}',
            selected: store.tab == WorkspaceTab.marks,
            changes: store.liftedMarks.length,
            compact: compact,
            onTap: () => store.selectTab(WorkspaceTab.marks),
          ),
          _NavItem(
            icon: LucideIcons.bookmark,
            label: t.tabIdentities,
            selected: store.tab == WorkspaceTab.identities,
            compact: compact,
            onTap: () => store.selectTab(WorkspaceTab.identities),
          ),
          // **الشجرة صندوقٌ كصندوق الحقائق**، بينه وبين خانة الهويات. وهي
          // تملأ الفراغ الذي كان معطَّلًا، وتُمرَّر داخلها حين تطول.
          //
          // **وتظهر دائمًا، فارغةً كانت أو ملأى.** إخفاؤها حتى تُفتح ملفات
          // يخفي معها زرَّيها — وهما الطريق إلى فتح الملفات أصلًا. وهذا
          // بعينه ما وقع أوّل مرّة: بابٌ داخل الغرفة التي يفتحها.
          Expanded(
            child: FileTreePanel(
              store: store,
              onAddFiles: onAddFiles,
              onAddFolder: onAddFolder,
            ),
          ),
          _DocumentFacts(store: store),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
    this.changes = 0,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final int changes;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(compact ? 8 : 10, 2, compact ? 8 : 10, 2),
    child: Material(
      color: selected ? Shade.mirrorDeep : Colors.transparent,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        hoverColor: Shade.surfaceHover,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 11 : 13,
          ),
          child: Row(
            children: [
              Tooltip(
                message: compact ? label : '',
                child: Icon(
                  icon,
                  size: 17,
                  color: selected ? Shade.mirror : Shade.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? Type.semiBold : Type.regular,
                    color: selected ? Shade.mirror : Shade.text,
                  ),
                ),
              ),
              if (changes > 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Shade.mirror,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$changes',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: Type.bold,
                      color: Shade.onMirror,
                    ),
                  ),
                )
              else if (badge != null)
                Text(badge!, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    ),
  );
}

/// حقائق المستند: ما وجدناه فيه. تبني ثقة المستخدم بأننا قرأناه فعلًا.
class _DocumentFacts extends StatelessWidget {
  const _DocumentFacts({required this.store});
  final WorkspaceStore store;

  @override
  Widget build(BuildContext context) {
    final report = store.report;
    final theme = Theme.of(context);
    final t = context.l10n;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.labelSmall)),
          Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        border: Border.all(color: Shade.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.documentFacts, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          // شرطات قبل فتح ملف: الشريط موجود ومكانه محجوز، فلا يقفز التخطيط.
          row(t.factDesignColors, '${report?.contentColors.length ?? "—"}'),
          row(
            t.factInheritedColors,
            '${report?.inheritedColors.length ?? "—"}',
          ),
          row(t.factFonts, '${report?.fonts.length ?? "—"}'),
          row(t.factScannedParts, '${report?.scannedParts.length ?? "—"}'),
        ],
      ),
    );
  }
}
