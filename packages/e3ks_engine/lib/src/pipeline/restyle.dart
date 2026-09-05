/// المسار الكامل: افتح ← تعرّف على الصيغة ← بدّل ← تحقّق ← ابنِ.
///
/// الترتيب ملزِم. **لا يُبنى مخرج لم يمرّ على البوابة** (`00` §١/٢).
///
/// المسار **لا يعرف صيغة بعينها**: لا `if` باسم Word ولا باسم PowerPoint.
/// كل ما يخصّ صيغةً يسكن في ملفّها خلف عقد [DocumentFormat].
library;

import 'dart:typed_data';

import '../diagnostics/engine_issue.dart';
import '../diagnostics/engine_result.dart';
import '../format/document_format.dart';
import '../format/format_registry.dart';
import '../package/document_package.dart';
import '../transform/style_plan.dart';
import '../transform/transform_report.dart';
import '../validate/package_gate.dart';

/// مخرج ناجح: البايتات الجاهزة للكتابة، ومعها تقرير بما جرى.
final class RestyleOutcome {
  const RestyleOutcome({
    required this.bytes,
    required this.report,
    required this.format,
  });

  final Uint8List bytes;
  final TransformReport report;
  final FormatId format;
}

/// يعيد تنسيق مستند وفق [plan] ويُرجع بايتات جاهزة للكتابة.
///
/// المحرّك لا يكتب على القرص — هذا شأن المستدعي (`00` §4).
EngineResult<RestyleOutcome> restyle(Uint8List source, StylePlan plan) {
  final opened = DocumentPackage.open(source);
  if (opened case Failed(:final issues)) return Failed(issues);
  final package = (opened as Ok<DocumentPackage>).value;

  final detected = formatFor(package);
  if (detected case Failed(:final issues)) return Failed(issues);
  final format = (detected as Ok<DocumentFormat>).value;

  final applied = format.transform(package, plan);
  if (applied case Failed(:final issues)) return Failed(issues);
  final report = (applied as Ok<TransformReport>).value;

  // حارس العزل: صيغة لا تكتب إلا فيما تملك. خللٌ هنا خطأ برمجي عندنا،
  // ويوقف الكتابة قبل أن يصل إلى ملفّ المستخدم.
  final foreign = [
    for (final part in package.touchedParts)
      if (!format.owns(part)) part,
  ];
  if (foreign.isNotEmpty) {
    return Failed([
      for (final part in foreign)
        EngineIssue(
          code: IssueCode.foreignPartTouched,
          part: part,
          detail: 'format ${format.id.name} does not own this part',
        ),
    ]);
  }

  final blockers = [...checkPackage(package), ...format.validate(package)];
  if (blockers.isNotEmpty) return Failed(blockers);

  final built = package.build();
  if (built case Failed(:final issues)) return Failed(issues);

  return Ok(
    RestyleOutcome(
      bytes: (built as Ok<Uint8List>).value,
      report: report,
      format: format.id,
    ),
    warnings: [
      ...applied.issues.where((i) => i.severity == IssueSeverity.warning),
    ],
  );
}
