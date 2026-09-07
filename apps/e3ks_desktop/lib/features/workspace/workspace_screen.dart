/// الشاشة الوحيدة: شريط علوي، وشريط جانبي، ولوحة تحكّم، ومعاينة.
///
/// **لا شاشة فتح منفصلة.** الواجهة كاملة من اللحظة الأولى، ومكان المعاينة هو
/// نفسه مكان إسقاط الملف — فلا ينتقل المستخدم بين تخطيطين ولا يفقد سياقه.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/document_loader.dart';
import '../../data/font_service.dart';
import '../../data/identity_store.dart';
import '../../data/openable_files.dart';
import '../../data/output_writer.dart';
import '../../data/settings_store.dart';
import '../../data/window_frame.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/app_menu.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/panel.dart';
import '../export/export_set_sheet.dart';
import '../identity/identities_panel.dart';
import '../mapping/color_picker.dart';
import '../mapping/colors_panel.dart';
import '../mapping/fonts_panel.dart';
import '../mapping/marks_panel.dart';
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
    this.frame = flatWindowFrame,
  });

  final WorkspaceStore store;
  final IdentityStore identities;
  final SettingsStore settings;
  final FontService fonts;

  /// ما يحجزه إطار النافذة المخصّص. الافتراضي بلا حجز — للاختبارات.
  final WindowFrame frame;

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

  /// الامتدادات هنا للحوار وحده؛ الصيغة الفعلية يقرّرها المحرّك من محتوى
  /// الملفّ (`formatFor`)، فملفّ أُعيدت تسميته لا يُعالَج بالاسم الخطأ.
  static const _openable = XTypeGroup(
    label: 'E3KS', // e3ks:not-ui
    extensions: openableExtensions,
  );

  /// **ملفات لا ملفًّا.** المجموعة تُبنى من أربعة أبواب، وهذا أوّلها
  /// (`ADR 0005` §١)، و`openFiles` موجودة في الحزمة ولم تكن مستعملة.
  Future<void> _browse() async {
    final files = await openFiles(acceptedTypeGroups: const [_openable]);
    for (final file in files) {
      await _open(file.path);
    }
  }

  /// الباب الثاني: مجلدٌ وما تحته. يصير جذرًا في الشجرة.
  Future<void> _browseFolder() async {
    final path = await getDirectoryPath(
      confirmButtonText: context.l10n.batchConfirmSource,
    );
    if (path == null || !mounted) return;
    await _openDirectory(path);
  }

  Future<void> _openDirectory(String path) async {
    widget.store.addDirectory(path);
    for (final found in findDocuments(Directory(path))) {
      await _open(found.path);
    }
  }

  /// الباب الثالث: الإفلات — **كلّ ما أُفلت** لا أوّله.
  ///
  /// كان يأخذ أوّل ملفٍّ مطابق ثم يخرج، فيهمل البقيّة ويهمل المجلدات معًا.
  Future<void> _dropped(DropDoneDetails details) async {
    setState(() => _dragging = false);
    for (final item in details.files) {
      if (Directory(item.path).existsSync()) {
        await _openDirectory(item.path);
        continue;
      }
      final name = item.path.toLowerCase();
      if (openableExtensions.any((e) => name.endsWith('.$e'))) {
        await _open(item.path);
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

    if (result.failure != null) {
      // البوابة رفضت — لا ملف يُكتب، والسبب يُعرَض كاملًا (`00` §١/٢).
      setState(() => _exporting = false);
      await showExportBlocked(context, result.failure!);
      return;
    }

    // **الكتابة تُلتقَط.** كانت تقع خارج أي مُلتقِط، فيبقى الزرّ يدور ولا
    // يظهر ملفّ ولا سبب. والصمت ممنوع (`00` §5): ما لا يُكتب يُقال.
    try {
      await writeOutput(location.path, result.bytes!);
    } on FileSystemException catch (error) {
      if (!mounted) return;
      setState(() => _exporting = false);
      await showExportFailed(context, location.path, error.osError?.message);
      return;
    }

    if (!mounted) return;
    setState(() => _exporting = false);
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
                frame: widget.frame,
                store: store,
                settings: widget.settings,
                onSettings: () => showSettings(context, widget.fonts),
                onOpenFolder: _browseFolder,
                exporting: _exporting,
                onExport: _export,
                onExportSet: () => showSetExport(context, store),
                onBrowse: _browse,
                onClose: store.closeTab,
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
                        child: Sidebar(
                          store: store,
                          compact: compactSidebar,
                          onAddFiles: _browse,
                          onAddFolder: _browseFolder,
                        ),
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
    // **الاختيار السريع من الهويات المحفوظة وحدها.**
    //
    // كان يضيف هوية كل ملفّ مفتوح مستخرَجةً في حينها. على ملفٍّ أو ملفَّين
    // بدا مفيدًا، وعلى مجلدٍ ملأ النافذة بعشرات الصفوف حتى تعذّر اعتماد لون —
    // **والقائمة التي تطول بطول المجموعة ليست اقتراحًا بل حائط.** ومن أراد
    // ستايل ملفٍّ فطريقه أن يحفظه هوية، وهو بابٌ قائم في لوحة الهويات.
    final suggestions = <QuickPickGroup>[
      for (final identity in widget.identities.items)
        (source: identity.name, colors: identity.colors),
    ];

    final Widget child;
    if (!store.hasDocument && store.tab != WorkspaceTab.identities) {
      final t = context.l10n;
      child = Padding(
        padding: const EdgeInsets.all(Metrics.gutter),
        child: EmptyNote(
          text: switch (store.tab) {
            WorkspaceTab.colors => t.emptyColors,
            WorkspaceTab.marks => t.emptyMarks,
            _ => t.emptyFonts,
          },
          icon: switch (store.tab) {
            WorkspaceTab.colors => LucideIcons.palette,
            WorkspaceTab.marks => LucideIcons.highlighter,
            _ => LucideIcons.type,
          },
        ),
      );
    } else {
      child = switch (store.tab) {
        WorkspaceTab.colors => ColorsPanel(
          store: store,
          suggestions: suggestions,
        ),
        WorkspaceTab.fonts => FontsPanel(store: store),
        WorkspaceTab.marks => MarksPanel(store: store),
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
      // **الملفّ المقفل يقول قفله فوق لوحاته الثلاث.** بدونه يكتب المستخدم
      // قاعدةً عامّة من شاشته فلا يرى أثرًا، ولا شيء يقول لماذا.
      child: store.locked
          ? Column(
              children: [
                const _LockedBanner(),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}

/// شريطٌ فوق لوحات التحكّم: هذا الملفّ مقفل عن الخطة العامّة.
///
/// **الحال يُقال حيث يقع أثره.** القفل يُضبَط من الشجرة، وأثره هنا: كل قاعدة
/// تُكتب في هذه اللوحات تخصّ هذا الملفّ وحده.
class _LockedBanner extends StatelessWidget {
  const _LockedBanner();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: const BoxDecoration(
      color: Shade.mirrorDeep,
      border: Border(bottom: BorderSide(color: Shade.border)),
    ),
    child: Row(
      children: [
        const Icon(LucideIcons.lock, size: 13, color: Shade.mirror),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.lockedBanner,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    ),
  );
}

/// مسافة الشريط عن حوافّه — **نفسها فوق وتحت ويمينًا ويسارًا**.
///
/// المسافة الرأسية غير الأفقية تُرى ولو لم تُقَس: الزرّ يبدو ملتصقًا بحافّة
/// وطافيًا عن أخرى.
const double _topBarInset = 12;

/// ارتفاع الشريط: زرٌّ مضغوط (٣٢) وحافّتاه.
const double _minTopBar = 32 + _topBarInset * 2;

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.frame,
    required this.store,
    required this.settings,
    required this.onSettings,
    required this.onOpenFolder,
    required this.exporting,
    required this.onExport,
    required this.onExportSet,
    required this.onBrowse,
    required this.onClose,
  });

  final WindowFrame frame;
  final WorkspaceStore store;
  final SettingsStore settings;
  final VoidCallback onSettings;
  final VoidCallback onOpenFolder;
  final bool exporting;
  final VoidCallback onExport;
  final VoidCallback onExportSet;
  final VoidCallback onBrowse;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    final document = store.document;

    // **صفٌّ واحد.** أزرار النظام تسكن أعلى الشريط، ومحتواه يحاذيها في
    // السطر نفسه. وصفّان — علامةٌ فوق وأفعالٌ تحت — يتركان أحد الطرفين
    // فارغًا أيًّا كان ترتيبهما.
    //
    // والسحب من خلفية الشريط (`isMovableByWindowBackground`)، فلا نحتاج
    // حزامًا مخصّصًا له ولا يُحرَم زرٌّ من نقرته.
    // الشريط يسع أزرار النظام كاملةً وإلّا تدلّت تحت حدّه.
    final needed = frame.titlebarHeight + _topBarInset;

    // **والانتقال بحركة لا بقفزة.** الحجز يتغيّر حين يُخفي النظام أزراره
    // عند ملء الشاشة ويعيدها عند الخروج، فتنزلق العلامة والأزرار بمقداره.
    // والقفزة تجعل الشريط يبدو منكسرًا في اللحظة التي يستقرّ فيها كل شيء آخر.
    //
    // وزمنه `slow`: ما يُطلقه تغيّرُ شاشةٍ كاملة يُقاس بمقياسها لا بمقياس
    // زرّ (`07` §7). ومنحناه `standard` — تغيّرٌ في مكانه.
    return AnimatedContainer(
      duration: Motion.slow,
      curve: Motion.standard,
      height: needed < _minTopBar ? _minTopBar : needed,
      padding: EdgeInsets.only(
        // الجهة من النظام لا من اتجاه الواجهة: أزرار النافذة تنتقل مع لغة
        // النظام، وقد تكون غير لغة التطبيق.
        left: _topBarInset + frame.reserveLeft,
        right: _topBarInset + frame.reserveRight,
        top: _topBarInset,
        bottom: _topBarInset,
      ),
      decoration: const BoxDecoration(
        color: Shade.surface,
        border: Border(bottom: BorderSide(color: Shade.border)),
      ),
      child: Theme(
        // كثافة مضغوطة: الزرّ ٣٢ بدل ٤٠، فيملأ ما بين الحافّتين ولا يترك
        // فرقًا بين المسافة الرأسية والأفقية.
        data: theme.copyWith(visualDensity: VisualDensity.compact),
        child: Row(
          children: [
            // **الطرف الأيسر مرنٌ واحد، والفائض لا يُقسَم.**
            //
            // كان هنا `Flexible` لاسم الملف و`Spacer` بعده، ولكلٍّ منهما
            // مرونة ١. و`RenderFlex` يقسم الفضاء الحرّ بينهما بالتساوي،
            // فيأخذ الاسم حاجته وحدها ويسقط باقي نصيبه **في آخر الصفّ**:
            // الطرف الأيمن ينزاح عن حافّته بنصف ما يفيض عن الاسم — فراغٌ
            // يتّسع باتّساع النافذة، وقد بلغ ٣٢٣ بكسل في لقطات README حتى
            // بدا كأنه حجزٌ لأزرار نظامٍ غائبة.
            //
            // مرنٌ واحد يبتلع الفضاء كلّه، فيلتصق الطرف الأيمن بحافّته
            // مهما طال الاسم أو قصر، ويبقى القصّ داخل الصفّ الداخلي.
            Expanded(
              child: Row(
                children: [
                  Text(
                    t.appName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: Type.display,
                      letterSpacing: 4,
                      color: Shade.mirror,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: Shade.border,
                  ),
                  if (document == null)
                    Text(t.tagline, style: theme.textTheme.labelSmall)
                  else ...[
                    const Icon(
                      LucideIcons.fileText,
                      size: 14,
                      color: Shade.textMuted,
                    ),
                    const SizedBox(width: 7),
                    // اسم الملف قد يطول؛ يُقصّ ولا يدفع شيئًا خارج النافذة.
                    Flexible(
                      child: Text(
                        document.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (store.openTabs.length < 2)
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(LucideIcons.x, size: 15),
                        color: Shade.textFaint,
                        visualDensity: VisualDensity.compact,
                        tooltip: t.close,
                      ),
                  ],
                  const SizedBox(width: 12),
                ],
              ),
            ),
            _LanguageMenu(settings: settings),
            const SizedBox(width: 4),
            // الدفعة بجوار الإعدادات: كلاهما فعلٌ يفتح حوارًا، ولا يزاحم
            // زرَّ التصدير الذي يخصّ الملف المفتوح وحده.
            // **الباب قبل الغرفة.** زرّ «أضف مجلدًا» يسكن رأس شجرة الملفات،
            // والشجرة لا تظهر إلا بملفَّين — فلا سبيل إلى فتح مجلد إلا بعد
            // فتح مجلد. وهذا الزرّ هو المخرج من تلك الحلقة.
            IconButton(
              onPressed: onOpenFolder,
              icon: const Icon(LucideIcons.folderOpen, size: 16),
              color: Shade.textMuted,
              tooltip: t.openFolder,
            ),
            IconButton(
              onPressed: onSettings,
              icon: const Icon(LucideIcons.settings, size: 16),
              color: Shade.textMuted,
              tooltip: t.settings,
            ),
            const SizedBox(width: 10),
            if (store.hasChanges) ...[
              // **زرّ المحو يقول أيّ طبقة يمحو.** الطبقتان قائمتان معًا،
              // ومحوُ الخاصّة وحدها يُبقي العدّاد على حاله — فيبدو الزرّ
              // عاطلًا وهو يعمل.
              if (store.hasGeneralEdits)
                AppMenuButton<EditScope>(
                  tooltip: t.reset,
                  onSelected: store.resetChanges,
                  items: () => [
                    AppMenuChoice(
                      value: EditScope.file,
                      label: t.resetFileEdits,
                    ),
                    AppMenuChoice(
                      value: EditScope.general,
                      label: t.resetGeneralEdits,
                    ),
                  ],
                  // **الزرّ نفسه لا نسخةٌ منه.** تأليف نمطه بيدي أسقط منه
                  // `height` وتوزيعَ الفراغ المتساوي، فبُتر ذيل «تراجع عن
                  // الكل» — وهو الخلل الموصوف في `07` §2/1 عائدًا من باب
                  // آخر. و`textButtonTheme` يحمله كاملًا.
                  child: IgnorePointer(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(t.reset, overflow: TextOverflow.visible),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: store.resetChanges,
                  child: Text(t.reset, overflow: TextOverflow.visible),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
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
              const SizedBox(width: 12),
            ],
            // **`TextOverflow.visible` هنا ليست ترفًا.** `RenderParagraph`
            // يقصّ عند حدود صندوقه متى فاض النصّ عن قيوده ولو بجزء من
            // بكسل، **والقصّ يأخذ معه ذيل الحرف النازل** — راء «اختر»
            // كانت تخرج مبتورة. والزرّ هنا وحده يبلغ هذا الحدّ: صفٌّ
            // ضيّق داخل زرٍّ مضغوط الكثافة في شريط بارتفاع مضبوط.
            if (document == null)
              FilledButton.icon(
                onPressed: store.busy ? null : onBrowse,
                icon: const Icon(LucideIcons.folderOpen, size: 16),
                label: Text(t.chooseFile, overflow: TextOverflow.visible),
              )
            else ...[
              // **الوجهتان تُسألان لا تُخمَّنان.** بمجموعةٍ مفتوحة قد يريد
              // المستخدم ملفَّه وحده وقد يريدها كلّها، والزرّ الواحد يقرّر
              // عنه أحدهما.
              if (store.canScope && store.anyChanges)
                AppMenuButton<bool>(
                  tooltip: t.export,
                  onSelected: (whole) => whole ? onExportSet() : onExport(),
                  items: () => [
                    AppMenuChoice(value: false, label: t.exportThisFile),
                    AppMenuChoice(value: true, label: t.exportWholeSet),
                  ],
                  // **الزرّ مظهرٌ لا فعل**: تعطيلُه يُبهته وهو متاح،
                  // وتركُه عاملًا يبتلع الضغطة فلا تُفتح القائمة.
                  child: IgnorePointer(
                    child: _ExportLabel(exporting: exporting),
                  ),
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
                  label: Text(
                    exporting ? t.exporting : t.export,
                    overflow: TextOverflow.visible,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// وجه زرّ التصدير حين تُفتح وجهتاه من قائمة.
class _ExportLabel extends StatelessWidget {
  const _ExportLabel({required this.exporting});
  final bool exporting;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return FilledButton.icon(
      onPressed: exporting ? null : () {},
      icon: exporting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.share, size: 16),
      label: Text(
        exporting ? t.exporting : t.export,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppMenuButton<Locale>(
      tooltip: t.language,
      onSelected: settings.setLocale,
      items: () => [
        for (final locale in SettingsStore.supported)
          AppMenuChoice(
            value: locale,
            // اسم كل لغة بلغتها نفسها — أوضح ما يمكن لمن لا يقرأ الحالية.
            label: nativeLanguageName(locale),
            selected: locale == settings.locale,
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
