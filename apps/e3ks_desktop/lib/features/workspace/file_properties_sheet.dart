/// خصائص ملفٍّ من الشجرة.
///
/// **ما يُقرَّر به، لا ما يزيّن.** عدد الأجزاء المفحوصة رقمٌ لا يُبنى عليه
/// قرار؛ والذي يُبنى عليه: ماذا ستفعل الخطة بهذا الملفّ بالضبط، وأين يبلغ
/// أثرها منه، **وما الذي تركته**. الأخير أنفعها: لونٌ بارز في المحتوى بلا
/// قاعدة تبدّله هو الإشارة الأولى إلى ملفٍّ فلت من المراجعة.
library;

import 'dart:io';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/swatch.dart';

Future<void> showFileProperties(
  BuildContext context,
  WorkspaceStore store,
  int index,
) => showAppDialog<void>(
  context,
  (_) => _Properties(store: store, index: index),
);

/// آخر تعديلٍ للمصدر، أو `null` إن تعذّرت قراءته.
///
/// **من القرص لا من الذاكرة**: البايتات المحمَّلة نسخةُ لحظةِ الفتح، وقد
/// يكون الملفّ تغيّر بعدها — وهذا نفسه خبرٌ يستحقّ أن يُرى.
DateTime? _modifiedOf(String path) {
  try {
    return File(path).statSync().modified;
  } on FileSystemException {
    return null;
  }
}

class _Properties extends StatelessWidget {
  const _Properties({required this.store, required this.index});

  final WorkspaceStore store;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final file = store.files[index];
    final document = file.document;
    final report = document.report;
    final plan = store.planFor(index);

    final content = report?.contentColors ?? const <ColorUsage>[];
    final mapped = [
      for (final usage in content)
        if (plan.colors.containsKey(usage.color)) usage,
    ];
    final untouched = [
      for (final usage in content)
        if (!plan.colors.containsKey(usage.color)) usage,
    ];
    final spots = mapped.fold(0, (sum, usage) => sum + usage.count);
    // **أين يبلغ الأثر**: أجزاء الألوان المبدَّلة وحدها. وهذا ما يقول
    // للمستخدم إن التبديل يمسّ الترويسة والتذييل لا المتن فقط.
    final reaches = <String>{
      for (final usage in mapped)
        ...usage.byPart.keys.map((p) => partLabel(t, p)),
    };
    final marks = report?.marks ?? const <MarkUsage>[];
    final lifted = marks
        .where((usage) => plan.removeMarks.contains(usage.mark))
        .length;
    final modified = _modifiedOf(document.path);

    return Dialog(
      backgroundColor: Shade.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Metrics.radius),
        side: const BorderSide(color: Shade.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.propsTitle, style: text.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    document.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                children: [
                  _Facts(
                    rows: [
                      (
                        label: t.propsFormat,
                        value: formatLabel(t, document.format),
                      ),
                      (
                        label: t.propsSize,
                        value: _size(t, document.bytes.length),
                      ),
                      if (modified != null)
                        (label: t.propsModified, value: _stamp(modified)),
                      (
                        label: document.format == FormatId.pptx
                            ? t.propsSlides
                            : t.propsPages,
                        value:
                            t.localizedCount(document.preview.pageCount) +
                            (file.previewPartial ? '+' : ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    document.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: text.labelSmall,
                  ),
                  const SizedBox(height: 18),

                  Text(t.propsPlan, style: text.titleSmall),
                  const SizedBox(height: 8),
                  // **الفحص خارج مسار أوّل رسمة**، فقد يُفتح هذا قبل وصوله.
                  // ولوحةٌ بأصفارٍ في تلك اللحظة تكذب (`00` §5).
                  if (report == null)
                    Text(t.inspectingDocument, style: text.bodySmall)
                  else
                    _Facts(
                      rows: [
                        (
                          label: t.propsColorsLabel,
                          value: mapped.isEmpty
                              ? t.propsNothing
                              : t.propsColorsValue(
                                  mapped.length,
                                  content.length,
                                  spots,
                                ),
                        ),
                        if (reaches.isNotEmpty)
                          (label: t.propsReaches, value: reaches.join(' · ')),
                        (
                          label: t.arabicFont,
                          value: plan.fonts?.arabic ?? t.propsUnchanged,
                        ),
                        (
                          label: t.latinFont,
                          value: plan.fonts?.latin ?? t.propsUnchanged,
                        ),
                        if (marks.isNotEmpty)
                          (
                            label: t.propsMarksLabel,
                            value: t.propsOf(lifted, marks.length),
                          ),
                      ],
                    ),
                  if (file.locked) ...[
                    const SizedBox(height: 10),
                    Text(
                      t.lockedBanner,
                      style: text.labelSmall?.copyWith(color: Shade.mirror),
                    ),
                  ],

                  if (report != null) ...[
                    const SizedBox(height: 18),
                    Text(t.propsUntouched, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      untouched.isEmpty
                          ? t.propsAllMapped
                          : t.propsUntouchedHint,
                      style: text.labelSmall,
                    ),
                    if (untouched.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final usage in untouched.take(12))
                            _Leftover(usage: usage),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Shade.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.close, overflow: TextOverflow.visible),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تاريخٌ رقميّ لا مكتوب.
  ///
  /// **لأن النظامين كانا يختلطان في صندوق واحد**: `MaterialLocalizations`
  /// تكتب التاريخ بأرقام هندية للعربية، و`intl` تُصيّر أرقام `ar` لاتينيةً
  /// (`ar_EG` وحدها هندية) — مقيسًا. فيقع «الاثنين، ٧ سبتمبر» بجوار «4
  /// ك.ب» في الصندوق نفسه. والرقميّ يُقرأ في اللغتين ويتّسق مع بقيّة
  /// الأعداد.
  String _stamp(DateTime at) {
    String two(int value) => value < 10 ? '0$value' : '$value';
    return '${at.year}/${two(at.month)}/${two(at.day)}';
  }

  String _size(L t, int bytes) => bytes >= 1024 * 1024
      ? t.propsSizeMb((bytes / (1024 * 1024) * 10).round() / 10)
      : t.propsSizeKb((bytes / 1024).ceil());
}

/// صفوف «عنوان ← قيمة» في صندوق واحد.
class _Facts extends StatelessWidget {
  const _Facts({required this.rows});

  final List<({String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: Shade.canvas,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        border: Border.all(color: Shade.border),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(row.label, style: text.labelSmall),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: Shade.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// لونٌ في المحتوى بلا قاعدة: عيّنته وعدد مواضعه.
class _Leftover extends StatelessWidget {
  const _Leftover({required this.usage});

  final ColorUsage usage;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Tooltip(
      message: '${usage.color.value} · ${usage.color.describe(t)}',
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 5, 10, 5),
        decoration: BoxDecoration(
          color: Shade.canvas,
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          border: Border.all(color: Shade.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Swatch(color: usage.color, size: 18),
            const SizedBox(width: 8),
            Text(
              context.l10n.localizedCount(usage.count),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
