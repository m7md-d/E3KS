/// عقد الصيغة المدعومة.
///
/// **الغرض الأول: ألّا تكسر صيغةٌ صيغةً أخرى.** كل صيغة تعلن أجزاءها في
/// [owns]، والمسار يرفض أي كتابة خارجها. فخللٌ في PowerPoint لا يبلغ
/// `word/` أبدًا، ولو أراد كاتبه ذلك سهوًا.
///
/// **والغرض الثاني: أن تكون إضافة صيغة عملًا محدودًا.** الصيغة الجديدة تُنشئ
/// ملفًّا واحدًا يُنفّذ هذا العقد ويُسجَّل في `format_registry.dart`. لا شيء
/// في المسار ولا في الواجهة ولا في المحرّك المشترك يتغيّر.
library;

import '../diagnostics/engine_result.dart';
import '../inspect/inspection_report.dart';
import '../package/document_package.dart';
import '../validate/package_gate.dart';
import '../preview/preview_model.dart';
import '../transform/style_plan.dart';
import '../transform/transform_report.dart';

/// الصيغ التي يعرفها المحرّك. الاسم رمز لا نصّ معروض (`01`).
enum FormatId { docx, pptx }

abstract interface class DocumentFormat {
  FormatId get id;

  /// هل هذه الحاوية من هذه الصيغة؟
  ///
  /// **يُقرَّر من محتوى `[Content_Types].xml`، لا من امتداد الملف.** الامتداد
  /// كذبة يكتبها المستخدم بإعادة تسمية؛ نوع المحتوى يكتبه المحرِّر نفسه.
  bool claims(DocumentPackage package);

  /// هل هذا الجزء ملك هذه الصيغة؟ **حارس العزل.**
  ///
  /// يشمل كل ما قد تكتبه الصيغة، ولا يشمل شيئًا مشتركًا: `docProps/` خارج
  /// مسار الستايل عند الجميع (`00` §2)، و`[Content_Types].xml` تكتبه الحاوية
  /// لا الصيغة.
  bool owns(String partName);

  EngineResult<InspectionReport> inspect(DocumentPackage package);

  EngineResult<TransformReport> transform(
    DocumentPackage package,
    StylePlan plan,
  );

  /// نموذج المعاينة. [maxPages] يقف عند حدٍّ من الصفحات لكل جزء.
  ///
  /// **الحدّ لأجل أوّل رسمة**: المستخدم يرى الصفحة التي يقف عليها، ولا
  /// ينتظر آخر المستند ليراها. والاستخراج كسول، فالوقوف عنده يوقف القراءة.
  DocumentPreview preview(DocumentPackage package, {int? maxPages});

  /// فاحص ما قبل الكتابة الخاصّ بهذه الصيغة، لجزءٍ ممسوس واحد.
  ///
  /// كل فحصٍ فيه مشتقّ من انكسار حقيقي وقع، لا من احتمال نظري.
  ///
  /// **ويمرّ على تدفّق البوابة المشتركة** بدل أن يفتح مرورًا ثانيًا: كان
  /// الجزء يُحلَّل مرّتين، وقياسهما على ثمانمئة صفحة ٧٫٩ ثانية — أغلى من
  /// التبديل نفسه. و`null` تعني أن هذا الجزء لا يعني هذه الصيغة.
  PartGate? gateFor(String partName);
}

/// هل يعلن `[Content_Types].xml` نوع المحتوى [contentType]؟
///
/// أداة مشتركة لكل صيغة تُنفّذ [DocumentFormat.claims].
bool declaresContentType(DocumentPackage package, String contentType) {
  final text = package.textOf(DocumentPackage.contentTypesPart);
  return text != null && text.contains(contentType);
}
