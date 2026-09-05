/// الشاشة الوحيدة: شريط علوي، وشريط جانبي، ولوحة تحكّم، ومعاينة.
///
/// **لا شاشة فتح منفصلة.** الواجهة كاملة من اللحظة الأولى، ومكان المعاينة هو
/// نفسه مكان إسقاط الملف — فلا ينتقل المستخدم بين تخطيطين ولا يفقد سياقه.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/document_loader.dart';
import '../../data/font_service.dart';
import '../../data/identity_store.dart';
import '../../data/openable_files.dart';
import '../../data/settings_store.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/panel.dart';
import '../identity/identities_panel.dart';
import '../mapping/colors_panel.dart';
import '../mapping/fonts_panel.dart';
import '../preview/drop_zone.dart';
import '../preview/font_notice.dart';
import '../preview/preview_panel.dart';
import '../settings/settings_sheet.dart';
import 'document_tabs.dart';
import 'export_result_sheet.dart';
import 'sidebar.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({
    super.key,
    required this.store,
    required this.identities,
    required this.settings,
    required this.fonts,
  });

  final WorkspaceStore store;
  final IdentityStore identities;
  final SettingsStore settings;
  final FontService fonts;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  bool _exporting = false;
  bool _dragging = false;

  Future<void> _open(String path) async {
    final bytes = Uint8List.fromList(await readFile(path));
    if (!mounted) return;
    await widget.store.open(path, path.split('/').last, bytes);

    // خطوط المستند تُحلّ بعد فتحه مباشرةً: المعاينة تَعِد بشكله الحقيقي،
    // والوعد لا يتحقّق بخطوط ناقصة.
    final report = widget.store.report;
    if (report == null) return;
    await widget.fonts.resolveAll([for (final font in report.fonts) font.name]);
  }

  Future<void> _browse() async {
    // الامتدادات هنا للحوار وحده؛ الصيغة الفعلية يقرّرها المحرّك من محتوى
    // الملفّ (`formatFor`)، فملفّ أُعيدت تسميته لا يُعالَج بالاسم الخطأ.
    const type = XTypeGroup(
      label: 'E3KS', // e3ks:not-ui
      extensions: openableExtensions,
    );
    final file = await openFile(acceptedTypeGroups: const [type]);
    if (file != null) await _open(file.path);
  }

  void _dropped(DropDoneDetails details) {
    setState(() => _dragging = false);
    for (final file in details.files) {
      final name = file.path.toLowerCase();
      if (openableExtensions.any((e) => name.endsWith('.$e'))) {
        _open(file.path);
        return;
      }
    }
  }

  Future<void> _export() async {
    final document = widget.store.document;
    if (document == null) return;

    // الامتداد يبقى امتداد المصدر: العرض يخرج عرضًا والمستند مستندًا.
    final suggested = suggestedOutputName(document.fileName);
    final location = await getSaveLocation(suggestedName: suggested);
    if (location == null) return;

    setState(() => _exporting = true);
    final result = await buildOutput(document.bytes, widget.store.plan);
    if (!mounted) return;
    setState(() => _exporting = false);

    if (result.failure != null) {
      // البوابة رفضت — لا ملف يُكتب، والسبب يُعرَض كاملًا (`00` §١/٢).
      await showExportBlocked(context, result.failure!);
      return;
    }

    // كتابة ذرّية: مؤقّت ثم إعادة تسمية (`00` §١/٣).
    File('${location.path}.part')
      ..writeAsBytesSync(result.bytes!)
      ..renameSync(location.path);

    if (!mounted) return;
    await showExportDone(context, location.path, result.report!);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return Scaffold(
      // الإفلات مقبول في أي مكان من النافذة، والأثر البصري في المعاينة.
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: _dropped,
        child: Column(
          children: [
            Entrance(
              child: _TopBar(
                store: store,
                settings: widget.settings,
                onSettings: () => showSettings(context, widget.fonts),
                exporting: _exporting,
                onExport: _export,
                onBrowse: _browse,
                onClose: store.closeDocument,
              ),
            ),
            DocumentTabs(store: store, onAdd: _browse),
            Expanded(
              // التخطيط يتكيّف مع عرض النافذة: المساحة الفائضة للمعاينة،
              // والشحّ يُقتطع من الشريط الجانبي أولًا ثم من لوحة التحكّم.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final compactSidebar = width < 1340;
                  final controlsWidth = width < 1280 ? 370.0 : 430.0;
                  // اللوحات تتشكّل بالترتيب الذي تُقرأ به: التنقّل، ثم
                  // أدوات العمل، ثم المعاينة. مرّةً واحدة عند الدخول —
                  // `Entrance` لا يعيد الحركة مع إعادة البناء.
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Entrance(
                        order: 1,
                        child: Sidebar(store: store, compact: compactSidebar),
                      ),
                      Entrance(
                        order: 2,
                        child: SizedBox(
                          width: controlsWidth,
                          child: _controls(store),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Shade.border),
                      Expanded(
                        child: Entrance(
                          order: 3,
                          child: Column(
                            children: [
                              // إشعار الخطوط فوق المعاينة مباشرةً: مكانه حيث
                              // يقع أثره، لا في ركن بعيد.
                              if (store.hasDocument)
                                FontNotice(
                                  service: widget.fonts,
                                  onDetails: () =>
                                      showSettings(context, widget.fonts),
                                ),
                              Expanded(
                                child: PreviewPanel(
                                  store: store,
                                  onOpen: _open,
                                  dragging: _dragging,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(WorkspaceStore store) {
    final suggestions = <HexColor>[
      for (final identity in widget.identities.items)
        for (final color in identity.colors) color.hex,
    ];

    final Widget child;
    if (!store.hasDocument && store.tab != WorkspaceTab.identities) {
      final t = context.l10n;
      child = Padding(
        padding: const EdgeInsets.all(Metrics.gutter),
        child: EmptyNote(
          text: store.tab == WorkspaceTab.colors ? t.emptyColors : t.emptyFonts,
          icon: store.tab == WorkspaceTab.colors
              ? LucideIcons.palette
              : LucideIcons.type,
        ),
      );
    } else {
      child = switch (store.tab) {
        WorkspaceTab.colors => ColorsPanel(
          store: store,
          suggestions: suggestions,
        ),
        WorkspaceTab.fonts => FontsPanel(store: store),
        WorkspaceTab.identities => IdentitiesPanel(
          store: store,
          identities: widget.identities,
        ),
      };
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Shade.canvas,
        border: Border(right: BorderSide(color: Shade.border)),
      ),
      child: child,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.store,
    required this.settings,
    required this.onSettings,
    required this.exporting,
    required this.onExport,
    required this.onBrowse,
    required this.onClose,
  });

  final WorkspaceStore store;
  final SettingsStore settings;
  final VoidCallback onSettings;
  final bool exporting;
  final VoidCallback onExport;
  final VoidCallback onBrowse;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    final document = store.document;

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Shade.surface,
        border: Border(bottom: BorderSide(color: Shade.border)),
      ),
      child: Row(
        children: [
          Text(
            t.appName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: Type.display,
              letterSpacing: 4,
              color: Shade.mirror,
            ),
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Shade.border,
          ),
          if (document == null)
            Text(t.tagline, style: theme.textTheme.bodySmall)
          else ...[
            const Icon(LucideIcons.fileText, size: 16, color: Shade.textMuted),
            const SizedBox(width: 8),
            // اسم الملف قد يطول؛ يُقصّ ولا يزحم الأزرار خارج النافذة.
            Flexible(
              child: Text(
                document.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: onBrowse, child: Text(t.openAnother)),
            if (store.tabs.length < 2)
              IconButton(
                onPressed: onClose,
                icon: const Icon(LucideIcons.x, size: 15),
                color: Shade.textFaint,
                visualDensity: VisualDensity.compact,
                tooltip: t.close,
              ),
          ],
          const SizedBox(width: 12),
          const Spacer(),
          _LanguageMenu(settings: settings),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(LucideIcons.settings, size: 16),
            color: Shade.textMuted,
            tooltip: t.settings,
          ),
          const SizedBox(width: 8),
          if (store.hasChanges) ...[
            TextButton(onPressed: store.resetChanges, child: Text(t.reset)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Shade.mirrorDeep,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Shade.mirrorSoft),
              ),
              child: Text(
                t.changesBadge(store.changeCount),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Shade.mirror,
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          if (document == null)
            FilledButton.icon(
              onPressed: store.busy ? null : onBrowse,
              icon: const Icon(LucideIcons.folderOpen, size: 16),
              label: Text(t.chooseFile),
            )
          else
            FilledButton.icon(
              onPressed: store.hasChanges && !exporting ? onExport : null,
              icon: exporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.share, size: 16),
              label: Text(exporting ? t.exporting : t.export),
            ),
        ],
      ),
    );
  }
}

/// مبدّل اللغة. في الشريط العلوي دائمًا: لا يبحث عنه المستخدم في إعدادات.
class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return PopupMenuButton<Locale>(
      tooltip: t.language,
      color: Shade.surfaceHigh,
      initialValue: settings.locale,
      onSelected: settings.setLocale,
      itemBuilder: (_) => [
        for (final locale in SettingsStore.supported)
          PopupMenuItem(
            value: locale,
            // اسم كل لغة بلغتها نفسها — أوضح ما يمكن لمن لا يقرأ الحالية.
            child: Text(nativeLanguageName(locale)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Shade.canvas,
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          border: Border.all(color: Shade.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.languages, size: 14, color: Shade.textMuted),
            const SizedBox(width: 6),
            Text(
              nativeLanguageName(settings.locale),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
