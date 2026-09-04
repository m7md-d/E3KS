/// منطقة الإسقاط — تسكن داخل مساحة المعاينة.
///
/// لا شاشة فتح منفصلة: الواجهة الكاملة ظاهرة من اللحظة الأولى، فيرى المستخدم
/// إلى أين هو ذاهب قبل أن يبدأ. ومكان الملف بعد فتحه هو نفسه مكان إسقاطه.
library;

import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';

class DropZone extends StatelessWidget {
  const DropZone({
    super.key,
    required this.onOpen,
    required this.busy,
    required this.dragging,
    this.errors = const [],
  });

  final void Function(String path) onOpen;
  final bool busy;
  final bool dragging;

  /// أسباب الفشل مصاغةً بلغة المستخدم الحالية.
  final List<String> errors;

  Future<void> _browse() async {
    const type = XTypeGroup(label: 'Word', extensions: ['docx']);
    final file = await openFile(acceptedTypeGroups: const [type]);
    if (file != null) onOpen(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    return ColoredBox(
      color: Shade.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MirrorMark(name: t.appName),
                const SizedBox(height: 8),
                Text(t.tagline, style: theme.textTheme.bodySmall),
                const SizedBox(height: 36),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  decoration: BoxDecoration(
                    color: dragging ? Shade.mirrorDeep : Shade.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: dragging ? Shade.mirror : Shade.borderStrong,
                      width: dragging ? 2 : 1,
                    ),
                  ),
                  child: busy
                      ? Column(
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(height: 16),
                            Text(t.reading, style: theme.textTheme.titleMedium),
                          ],
                        )
                      : Column(
                          children: [
                            Icon(
                              dragging
                                  ? LucideIcons.download
                                  : LucideIcons.fileText,
                              size: 38,
                              color: dragging ? Shade.mirror : Shade.textFaint,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              t.dropHere,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              t.orDivider,
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _browse,
                              child: Text(t.chooseFile),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                Text(t.supported, style: theme.textTheme.labelSmall),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _ErrorNote(lines: errors),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// اسم التطبيق وتحته انعكاسه — المرآة في التفصيلة لا في الشعار.
class _MirrorMark extends StatelessWidget {
  const _MirrorMark({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 42,
      fontWeight: Type.display,
      color: Shade.text,
      letterSpacing: 8,
      height: 1,
    );

    return Column(
      children: [
        Text(name, style: style),
        SizedBox(
          height: 24,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Shade.mirror, Colors.transparent],
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: Transform.flip(flipY: true, child: Text(name, style: style)),
          ),
        ),
      ],
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Shade.danger.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      border: Border.all(color: Shade.danger.withValues(alpha: 0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.circleAlert, size: 17, color: Shade.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lines.first,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        for (final line in lines.skip(1)) ...[
          const SizedBox(height: 6),
          Text(line, style: Theme.of(context).textTheme.labelSmall),
        ],
      ],
    ),
  );
}

/// يقرأ الملف من القرص. يبقى في طبقة الواجهة لأنها من تملك الوصول للملفات.
Future<List<int>> readFile(String path) => File(path).readAsBytes();
