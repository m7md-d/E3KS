/// صيغة PowerPoint — تجميع أجزائها خلف عقد [DocumentFormat].
library;

import '../../diagnostics/engine_result.dart';
import '../../inspect/inspection_report.dart';
import '../../package/document_package.dart';
import '../../preview/preview_model.dart';
import '../../transform/style_plan.dart';
import '../../transform/transform_report.dart';
import '../../validate/package_gate.dart';
import '../document_format.dart';
import 'pptx_gate.dart';
import 'pptx_inspector.dart';
import 'pptx_parts.dart';
import 'pptx_preview.dart';
import 'pptx_transformer.dart';

/// نوع محتوى العرض في `[Content_Types].xml`.
///
/// يغطّي `presentation.main+xml` و`slideshow.main+xml` و`template.main+xml`
/// معًا: ثلاثتها عروض بالبنية نفسها، ويختلف الامتداد وحده (pptx / ppsx / potx).
const String _presentationContentType = 'presentationml.';

final class PptxFormat implements DocumentFormat {
  const PptxFormat();

  @override
  FormatId get id => FormatId.pptx;

  @override
  bool claims(DocumentPackage package) =>
      declaresContentType(package, _presentationContentType);

  @override
  bool owns(String partName) => ownsPptxPart(partName);

  @override
  EngineResult<InspectionReport> inspect(DocumentPackage package) =>
      const PptxInspector().inspect(package);

  @override
  EngineResult<TransformReport> transform(
    DocumentPackage package,
    StylePlan plan,
  ) => const PptxTransformer().apply(package, plan);

  @override
  DocumentPreview preview(DocumentPackage package, {int? maxPages}) =>
      const PptxPreviewExtractor().extract(package, maxPages: maxPages);

  @override
  PartGate? gateFor(String partName) => PptxPartGate(partName);
}
