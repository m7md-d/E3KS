/// الواجهة العامة الوحيدة لمحرّك E3KS.
///
/// كل ما تحت `src/` خاص. لا يُستورد من خارج الحزمة — القاعدة `01`.
library;

export 'src/diagnostics/engine_issue.dart';
export 'src/diagnostics/engine_result.dart';
export 'src/inspect/color_usage.dart';
export 'src/inspect/docx_inspector.dart';
export 'src/inspect/font_usage.dart';
export 'src/inspect/hex_color.dart';
export 'src/inspect/inspection_report.dart';
export 'src/ooxml/part_classes.dart';
export 'src/package/document_package.dart';
export 'src/pipeline/restyle_docx.dart';
export 'src/preview/preview_extractor.dart';
export 'src/preview/preview_model.dart';
export 'src/preview/preview_restyler.dart';
export 'src/transform/docx_transformer.dart';
export 'src/transform/style_plan.dart';
export 'src/transform/transform_report.dart';
export 'src/validate/output_gate.dart';
