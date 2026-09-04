/// المسار الكامل: افتح ← بدّل ← تحقّق ← ابنِ.
///
/// الترتيب ملزِم. **لا يُبنى مخرج لم يمرّ على البوابة** (`00` §١/٢).
library;

import 'dart:typed_data';

import '../diagnostics/engine_issue.dart';
import '../diagnostics/engine_result.dart';
import '../package/document_package.dart';
import '../transform/docx_transformer.dart';
import '../transform/style_plan.dart';
import '../transform/transform_report.dart';
import '../validate/output_gate.dart';

/// مخرج ناجح: البايتات الجاهزة للكتابة، ومعها تقرير بما جرى.
final class RestyleOutcome {
  const RestyleOutcome({required this.bytes, required this.report});

  final Uint8List bytes;
  final TransformReport report;
}

/// يعيد تنسيق مستند Word وفق [plan] ويُرجع بايتات جاهزة للكتابة.
///
/// المحرّك لا يكتب على القرص — هذا شأن المستدعي (`00` §4).
EngineResult<RestyleOutcome> restyleDocx(Uint8List source, StylePlan plan) {
  final opened = DocumentPackage.open(source);
  if (opened case Failed(:final issues)) return Failed(issues);
  final package = (opened as Ok<DocumentPackage>).value;

  final applied = const DocxTransformer().apply(package, plan);
  if (applied case Failed(:final issues)) return Failed(issues);
  final report = (applied as Ok<TransformReport>).value;

  final blockers = const OutputGate().check(package);
  if (blockers.isNotEmpty) return Failed(blockers);

  final built = package.build();
  if (built case Failed(:final issues)) return Failed(issues);

  return Ok(
    RestyleOutcome(bytes: (built as Ok<Uint8List>).value, report: report),
    warnings: [
      ...applied.issues.where((i) => i.severity == IssueSeverity.warning),
    ],
  );
}
