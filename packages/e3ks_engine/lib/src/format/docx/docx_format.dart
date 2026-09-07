/// صيغة Word — تجميع أجزائها خلف عقد [DocumentFormat].
///
/// هذا الملفّ **كل** ما يعرفه المسار عن Word. لا شرط `if` باسم الصيغة في
/// المسار ولا في الواجهة.
library;

import '../../diagnostics/engine_result.dart';
import '../../inspect/inspection_report.dart';
import '../../package/document_package.dart';
import '../../preview/preview_model.dart';
import '../../transform/style_plan.dart';
import '../../transform/transform_report.dart';
import '../../validate/package_gate.dart';
import '../document_format.dart';
import 'docx_gate.dart';
import 'docx_inspector.dart';
import 'docx_parts.dart';
import 'docx_preview.dart';
import 'docx_transformer.dart';

/// نوع محتوى المتن في `[Content_Types].xml`. الامتداد لا يُسأل (`claims`).
const String _documentContentType = 'wordprocessingml.document.main+xml';

final class DocxFormat implements DocumentFormat {
  const DocxFormat();

  @override
  FormatId get id => FormatId.docx;

  @override
  bool claims(DocumentPackage package) =>
      declaresContentType(package, _documentContentType);

  @override
  bool owns(String partName) => ownsDocxPart(partName);

  @override
  EngineResult<InspectionReport> inspect(DocumentPackage package) =>
      const DocxInspector().inspect(package);

  @override
  EngineResult<TransformReport> transform(
    DocumentPackage package,
    StylePlan plan,
  ) => const DocxTransformer().apply(package, plan);

  @override
  DocumentPreview preview(DocumentPackage package, {int? maxPages}) =>
      const DocxPreviewExtractor().extract(package, maxPages: maxPages);

  @override
  PartGate? gateFor(String partName) => DocxPartGate(partName);
}
