/// تصدير المجموعة: مراجعةٌ قبل الكتابة، ثم تقدّم، ثم حصيلة.
///
/// **الشاشة الأولى هي الغرض** (`03`): «لا زرّ ينفّذ عملية غير قابلة للتراجع
/// دون معاينة قبلها». الحوار القديم كان يكتب أربعين ملفًا بضغطةٍ واحدة، بلا
/// أن يقول أين تُكتب ولا ما الذي يتغيّر في كلٍّ منها ولا أيّها يُكتب فوق
/// ملفٍّ قائم.
library;

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/set_exporter.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/app_dialog.dart';

Future<void> showSetExport(BuildContext context, WorkspaceStore store) =>
    showAppDialog<void>(context, (_) => _SetExport(store: store));

class _SetExport extends StatefulWidget {
  const _SetExport({required this.store});
  final WorkspaceStore store;

  @override
  State<_SetExport> createState() => _SetExportState();
}

class _SetExportState extends State<_SetExport> {
  late final List<ExportJob> _jobs = widget.store.exportJobs();

  String? _destination;

  /// المسارات المشغولة في المخرَج المختار — تُقرأ عند اختياره لا عند الكتابة.
  Set<String> _occupied = const {};

  bool _running = false;
  int _done = 0;
  SetExport? _result;

  Future<void> _chooseDestination() async {
    final path = await getDirectoryPath(
      confirmButtonText: context.mounted
          ? context.l10n.batchConfirmOutput
          : null,
      canCreateDirectories: true,
    );
    if (path == null || !mounted) return;
    setState(() {
      _destination = path;
      _occupied = {
        for (final job in _jobs)
          if (File(
            '$path${Platform.pathSeparator}${job.relative}',
          ).existsSync())
            job.relative,
      };
    });
  }

  Future<void> _run() async {
    final destination = _destination;
    if (destination == null) return;
    setState(() {
      _running = true;
      _done = 0;
    });

    final result = await exportSet(
      jobs: _jobs,
      outDirectory: destination,
      onProgress: (done, _) {
        if (mounted) setState(() => _done = done);
      },
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Dialog(
      backgroundColor: Shade.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Metrics.radius),
        side: const BorderSide(color: Shade.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.exportSetTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.exportSetHint,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Flexible(
              child: _result == null ? _review(t) : _outcome(t, _result!),
            ),
            _Footer(
              running: _running,
              progress: _running ? t.batchProgress(_done, _jobs.length) : null,
              value: _jobs.isEmpty ? 0 : _done / _jobs.length,
              done: _result != null,
              canRun: _destination != null && _jobs.isNotEmpty && !_running,
              onRun: _run,
            ),
          ],
        ),
      ),
    );
  }

  Widget _review(L t) => ListView(
    // **يحتضن محتواه ولا يمتدّ إلى سقفه.** `ListView` يملأ ما أُتيح له،
    // فيترك حوارًا فيه ثلاثة أسطر وفراغًا بطول الشاشة تحتها.
    shrinkWrap: true,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    children: [
      _DestinationRow(
        path: _destination,
        onChoose: _running ? null : _chooseDestination,
      ),
      const SizedBox(height: 14),
      if (_jobs.isEmpty)
        Text(t.exportSetEmpty, style: Theme.of(context).textTheme.bodySmall)
      else ...[
        if (_occupied.isNotEmpty)
          _Note(text: t.exportOverwriteCount(_occupied.length)),
        const SizedBox(height: 8),
        // **كل ملفّ بسطره**: أين يُكتب، وكم يتغيّر فيه، وما حاله. وهذا هو
        // ما يجعل الضغطة التالية قرارًا لا مقامرة.
        for (var i = 0; i < _jobs.length; i++)
          _JobRow(
            job: _jobs[i],
            changes: widget.store.changeCountAt(i),
            locked: widget.store.files[i].locked,
            reviewed: widget.store.files[i].reviewed,
            overwrites: _occupied.contains(_jobs[i].relative),
            renamed:
                _jobs[i].relative != _jobs[i].name &&
                !_jobs[i].relative.endsWith(_jobs[i].name),
          ),
      ],
      const SizedBox(height: 10),
    ],
  );

  Widget _outcome(L t, SetExport outcome) {
    final report = outcome.report;
    final never = report.unmatchedEverywhere;
    final text = Theme.of(context).textTheme;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Row(
          children: [
            _Tally(label: t.batchWritten, value: report.written.length),
            _Tally(
              label: t.batchFailedCount,
              value: report.failed.length + outcome.mishaps.length,
            ),
            _Tally(label: t.batchUnchanged, value: report.unchanged.length),
          ],
        ),
        for (final entry in report.failed) ...[
          const SizedBox(height: 8),
          _Failure(
            name: entry.name,
            reasons: [for (final issue in entry.issues) issueText(t, issue)],
          ),
        ],
        // **وعطل القرص يُقال باسمه**: رسالة النظام كما قالها، لا تخمينًا
        // لسببها (`00` §5).
        for (final mishap in outcome.mishaps) ...[
          const SizedBox(height: 8),
          _Failure(
            name: mishap.name,
            reasons: ['${t.exportDiskFailed}: ${mishap.reason}'],
          ),
        ],
        if (never.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Note(
            text:
                '${t.batchNeverMatched}: '
                '${never.map((c) => c.value).join('، ')}',
          ),
        ],
        const SizedBox(height: 10),
        Text(
          '${t.batchOutput}: ${_destination ?? ''}',
          style: text.labelSmall,
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.path, required this.onChoose});

  final String? path;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        border: Border.all(color: Shade.border),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.folderOpen, size: 15, color: Shade.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.batchOutput,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  path ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: path == null ? null : TextDirection.ltr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChoose, child: Text(t.batchChoose)),
        ],
      ),
    );
  }
}

/// سطر ملفٍّ في المراجعة: أين يُكتب، وكم يتغيّر فيه، وما حاله.
class _JobRow extends StatelessWidget {
  const _JobRow({
    required this.job,
    required this.changes,
    required this.locked,
    required this.reviewed,
    required this.overwrites,
    required this.renamed,
  });

  final ExportJob job;
  final int changes;
  final bool locked;
  final bool reviewed;
  final bool overwrites;
  final bool renamed;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final notes = <String>[
      if (changes == 0) t.exportNoChanges,
      if (locked) t.fileLocked,
      if (overwrites) t.exportOverwrite,
      if (renamed) t.exportRenamedPath,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        border: Border.all(color: Shade.border),
      ),
      child: Row(
        children: [
          if (reviewed) ...[
            Tooltip(
              message: t.fileReviewed,
              child: const Icon(
                LucideIcons.check,
                size: 13,
                color: Shade.textMuted,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.relative,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: overwrites ? Shade.danger : Shade.textFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (changes > 0)
            Text(
              t.changesBadge(changes),
              style: text.labelSmall?.copyWith(color: Shade.mirror),
            ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.name, required this.reasons});

  final String name;
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        border: Border.all(color: Shade.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: text.bodyMedium),
          const SizedBox(height: 4),
          for (final reason in reasons)
            Text(reason, style: text.labelSmall?.copyWith(color: Shade.danger)),
        ],
      ),
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

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(LucideIcons.info, size: 13, color: Shade.textMuted),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      ),
    ],
  );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.running,
    required this.progress,
    required this.value,
    required this.done,
    required this.canRun,
    required this.onRun,
  });

  final bool running;
  final String? progress;
  final double value;
  final bool done;
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
      child: Column(
        children: [
          // **شريط التقدّم بالعدد** (`ADR 0005` §٨): مع عدّة مسارات لا يُعرف
          // أيّها يسبق، ونسبةٌ لملفٍّ بعينه تتقافز بلا معنى.
          if (running) ...[
            LinearProgressIndicator(
              value: value,
              minHeight: 3,
              backgroundColor: Shade.surfaceHover,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (progress != null)
                Text(progress!, style: Theme.of(context).textTheme.labelSmall),
              const Spacer(),
              TextButton(
                onPressed: running ? null : () => Navigator.of(context).pop(),
                child: Text(t.close),
              ),
              const SizedBox(width: 8),
              if (!done)
                FilledButton(
                  onPressed: canRun ? onRun : null,
                  child: Text(t.exportSetRun),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
