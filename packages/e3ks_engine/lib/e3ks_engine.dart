// E3KS — اعكس. محرّك فحص وتبديل الهوية البصرية في مستندات OOXML.
// Copyright (C) 2026  m7md-d
//
// برنامج حرّ تحت رخصة جنو العمومية العامة، الإصدار الثالث أو أيّ إصدار
// لاحق. يُوزَّع بلا أيّ ضمان. النصّ الكامل في `LICENSE` بجذر المشروع.

/// الواجهة العامة الوحيدة لمحرّك E3KS.
///
/// كل ما تحت `src/` خاص. لا يُستورد من خارج الحزمة — القاعدة `01`.
///
/// **لا تُصدَّر أجزاء صيغة بعينها.** المستدعي يتعامل مع [DocumentFormat] و
/// [formatFor]، فلا يعرف اسم `DocxInspector` ولا `PptxTransformer`. هذا ما
/// يجعل إضافة صيغة لا تغيّر سطرًا عند المستدعي.
library;

export 'src/diagnostics/engine_issue.dart';
export 'src/diagnostics/engine_result.dart';
export 'src/format/document_format.dart';
export 'src/format/format_registry.dart';
export 'src/inspect/color_usage.dart';
export 'src/inspect/font_usage.dart';
export 'src/inspect/hex_color.dart';
export 'src/inspect/inspection_report.dart';
export 'src/inspect/part_class.dart';
export 'src/package/document_package.dart';
export 'src/palette/tonal_ramp.dart';
export 'src/pipeline/batch.dart';
export 'src/pipeline/restyle.dart';
export 'src/preview/preview_model.dart';
export 'src/preview/preview_restyler.dart';
export 'src/transform/style_plan.dart';
export 'src/transform/transform_report.dart';
export 'src/validate/package_gate.dart';
