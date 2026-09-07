/// الدفعة: خطة واحدة على مجلد كامل.
///
/// **حوارٌ لا لوحة.** الدفعة فعلٌ له بداية ونهاية، لا عرضٌ يبقى معروضًا؛
/// ولوحةٌ رابعة في الشريط تزاحم عمل المستخدم على ملفه المفتوح بلا مقابل.
///
/// وترتيب الحقول هو ترتيب القرار: من أين، وبأي خطة، وإلى أين. ثم زرٌّ واحد.
library;

import 'dart:io';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/batch_runner.dart';
import '../../data/identity.dart';
import '../../data/identity_store.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/panel.dart';

Future<void> showBatch(
  BuildContext context,
  WorkspaceStore store,
  IdentityStore identities,
) => showAppDialog<void>(
  context,
  (_) => Dialog(
    backgroundColor: Shade.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Metrics.radius),
      side: const BorderSide(color: Shade.border),
    ),
    // **الارتفاع يتبع المحتوى بسقف.** حوارٌ ثابت الارتفاع يترك فراغًا
    // ميّتًا قبل التشغيل، ويضيق عن الحصيلة بعده.
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 560),
      child: SizedBox(
        width: 620,
        child: _BatchBody(store: store, identities: identities),
      ),
    ),
  ),
);

class _BatchBody extends StatefulWidget {
  const _BatchBody({required this.store, required this.identities});

  final WorkspaceStore store;
  final IdentityStore identities;

  @override
  State<_BatchBody> createState() => _BatchBodyState();
}

class _BatchBodyState extends State<_BatchBody> {
  String? _source;
  String? _output;
  List<BatchFile> _files = const [];

  /// `null` = خطة الملف المفتوح.
  Identity? _identity;

  bool _running = false;
  int _done = 0;
  BatchReport? _result;

  StylePlan get _plan {
    final identity = _identity;
    if (identity == null) return widget.store.plan;
    return StylePlan(
      colors: Map.of(identity.map),
      fonts: FontPlan(latin: identity.latinFont, arabic: identity.arabicFont),
      preserveFonts: Set.of(identity.preserveFonts),
    );
  }

  String? get _blocker {
    final t = context.l10n;
    if (_source == null || _output == null) return null;
    if (File(_source!).absolute.path == File(_output!).absolute.path) {
      return t.batchSameFolder;
    }
    if (_files.isEmpty) return t.batchEmptyFolder;
    if (_plan.isEmpty) return t.batchNoPlan;
    return null;
  }

  Future<void> _pickSource() async {
    final path = await getDirectoryPath(
      confirmButtonText: context.l10n.batchConfirmSource,
    );
    if (path == null || !mounted) return;
    setState(() {
      _source = path;
      _files = findDocuments(Directory(path));
      _result = null;
    });
  }

  Future<void> _pickOutput() async {
    // **`canCreateDirectories` صريحة هنا.** `NSOpenPanel` يخفي زرّ «مجلد
    // جديد» افتراضًا — الافتراض مصنوع لاختيار ما هو قائم — فكان المستخدم
    // يُطالَب بمجلد مخرَج ولا يُعطى وسيلةً لصنعه، فيخرج من التطبيق ليصنعه
    // ثم يعود. والراية تمرّ من `getDirectoryPath` إلى `NSSavePanel` منها.
    final path = await getDirectoryPath(
      canCreateDirectories: true,
      confirmButtonText: context.l10n.batchConfirmOutput,
      // يفتح عند المصدر: مجلد المخرَج يُصنع بجواره في الغالب.
      initialDirectory: _source,
    );
    if (path == null || !mounted) return;
    setState(() {
      _output = path;
      _result = null;
    });
  }

  Future<void> _run() async {
    final output = _output;
    if (output == null || _files.isEmpty) return;

    setState(() {
      _running = true;
      _done = 0;
      _result = null;
    });

    final report = await runBatch(
      files: _files,
      outDirectory: output,
      plan: _plan,
      onProgress: (done, _, _) {
        if (mounted) setState(() => _done = done);
      },
    );

    if (!mounted) return;
    setState(() {
      _running = false;
      _result = report;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final identities = widget.identities.items;
    final blocker = _blocker;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: SectionHeader(title: t.batchTitle, hint: t.batchHint),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            children: [
              _PathRow(
                icon: LucideIcons.folderOpen,
                label: t.batchSource,
                value: _source,
                note: _source == null ? null : t.batchDocuments(_files.length),
                onChoose: _running ? null : _pickSource,
              ),
              const SizedBox(height: 10),
              _PathRow(
                icon: LucideIcons.folderDown,
                label: t.batchOutput,
                value: _output,
                onChoose: _running ? null : _pickOutput,
              ),
              const SizedBox(height: 18),
              Text(t.batchPlan, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              _PlanChoice(
                label: t.batchFromOpen,
                selected: _identity == null,
                enabled: !_running && widget.store.hasChanges,
                onTap: () => setState(() => _identity = null),
              ),
              for (final identity in identities)
                _PlanChoice(
                  label: identity.name,
                  selected: _identity?.name == identity.name,
                  enabled: !_running,
                  onTap: () => setState(() => _identity = identity),
                ),
              if (blocker != null) ...[
                const SizedBox(height: 14),
                _Note(text: blocker),
              ],
              if (_result case final report?) ...[
                const SizedBox(height: 18),
                _Result(report: report),
              ],
            ],
          ),
        ),
        _Footer(
          running: _running,
          progress: _running ? t.batchProgress(_done, _files.length) : null,
          canRun: !_running && blocker == null && _output != null,
          onRun: _run,
        ),
      ],
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChoose,
    this.note,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? note;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radius),
        border: Border.all(color: Shade.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Shade.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(width: 10),
            Text(note!, style: text.labelSmall),
          ],
          const SizedBox(width: 10),
          TextButton(
            onPressed: onChoose,
            child: Text(context.l10n.batchChoose),
          ),
        ],
      ),
    );
  }
}

class _PlanChoice extends StatelessWidget {
  const _PlanChoice({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: selected ? Shade.mirrorDeep : Shade.canvas,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 16,
                color: selected
                    ? Shade.mirror
                    : (enabled ? Shade.textMuted : Shade.textFaint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled ? Shade.text : Shade.textFaint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(LucideIcons.info, size: 15, color: Shade.textMuted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      ),
    ],
  );
}

/// الحصيلة: ما كُتب وما سقط، وسببُ كل ساقط باسمه.
class _Result extends StatelessWidget {
  const _Result({required this.report});
  final BatchReport report;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final never = report.unmatchedEverywhere;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Tally(label: t.batchWritten, value: report.written.length),
            _Tally(label: t.batchFailedCount, value: report.failed.length),
            _Tally(label: t.batchUnchanged, value: report.unchanged.length),
          ],
        ),
        for (final entry in report.failed) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Shade.canvas,
              borderRadius: BorderRadius.circular(Metrics.radiusSmall),
              border: Border.all(color: Shade.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: text.bodyMedium),
                const SizedBox(height: 4),
                for (final issue in entry.issues)
                  Text(
                    issueText(t, issue),
                    style: text.labelSmall?.copyWith(color: Shade.danger),
                  ),
              ],
            ),
          ),
        ],
        // لونٌ لا يُطابق ملفًّا واحدًا عادي؛ ولا يُطابق المجموعة كلها خطأٌ
        // في الخطة، ولا يُرى إلا من فوقها.
        if (never.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Note(
            text:
                '${t.batchNeverMatched}: '
                '${never.map((c) => c.value).join('، ')}',
          ),
        ],
      ],
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          const SizedBox(height: 2),
          Text('$value', style: text.titleMedium),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.running,
    required this.progress,
    required this.canRun,
    required this.onRun,
  });

  final bool running;
  final String? progress;
  final bool canRun;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Shade.border)),
      ),
      child: Row(
        children: [
          if (progress != null) ...[
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(progress!, style: Theme.of(context).textTheme.labelSmall),
          ],
          const Spacer(),
          TextButton(
            onPressed: running ? null : () => Navigator.of(context).pop(),
            child: Text(t.close),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: canRun ? onRun : null,
            child: Text(t.batchRun),
          ),
        ],
      ),
    );
  }
}
