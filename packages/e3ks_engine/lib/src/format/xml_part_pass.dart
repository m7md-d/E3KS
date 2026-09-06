/// المرور على أجزاء XML: قراءةً للفحص، وكتابةً للتحويل.
///
/// **لماذا هنا لا في كل صيغة:** هذا المرور يحمل قاعدتين لا يجوز أن تُنسى
/// إحداهما في صيغة جديدة:
///
/// 1. **جزء تالف لا يُسقط الفحص كلّه، ولا يُبتلع صامتًا** (`00` §5).
/// 2. **لا يُكتب جزء لم تتغيّر بايتاته** (`00` §١/١). المقارنة بالبايتات لا
///    بالنيّة، وهي ممكنة لأن [serializeOoxml] يجعل دورة التحليل/التسلسل
///    مطابقة حرفيًا.
///
/// فتصير إضافة صيغة جديدة: مصنِّف أجزاء + زائر عناصر. لا أكثر.
library;

import 'package:xml/xml.dart';

import '../diagnostics/engine_issue.dart';
import '../diagnostics/engine_result.dart';
import '../inspect/part_class.dart';
import '../ooxml/ooxml_entity_mapping.dart';
import '../package/document_package.dart';

/// يصنّف جزءًا داخل الحاوية. [PartClass.other] يعني «لا يُفحَص ولا يُبدَّل».
typedef PartClassifier = PartClass Function(String partName);

/// يُستدعى لكل عنصر في جزء مفحوص.
typedef ElementScanner =
    void Function(XmlElement element, String partName, PartClass partClass);

/// يُستدعى لكل عنصر في جزء قيد التحويل.
typedef ElementRewriter = void Function(XmlElement element);

/// مرور قراءة. يملأ [scannedParts] ويُرجع تحذيرات الأجزاء التالفة.
List<EngineIssue> scanXmlParts(
  DocumentPackage package,
  PartClassifier classify,
  ElementScanner onElement, {
  required List<String> scannedParts,
}) {
  final warnings = <EngineIssue>[];

  for (final partName in package.partNames) {
    final partClass = classify(partName);
    if (partClass == PartClass.other) continue;

    final text = package.textOf(partName);
    if (text == null) continue;

    final XmlDocument document;
    try {
      document = XmlDocument.parse(text);
    } on XmlException catch (e) {
      warnings.add(
        EngineIssue(
          code: IssueCode.malformedXml,
          severity: IssueSeverity.warning,
          part: partName,
          detail: '$e',
        ),
      );
      continue;
    }

    scannedParts.add(partName);
    for (final element in document.descendants.whereType<XmlElement>()) {
      onElement(element, partName, partClass);
    }
  }

  return warnings;
}

/// مرور كتابة. يُرجع أسماء الأجزاء التي تغيّرت بايتاتها فعلًا.
///
/// جزء تالف هنا **يوقف كل شيء**: الفحص يتسامح لأنه قراءة، والتحويل لا
/// يتسامح لأنه سيكتب (`00` §١/٢).
///
/// **والقائمة تُثبَّت قبل المرور.** الزائر قد يحذف عنصرًا — رفع علامة تمييز
/// مثلًا — وحذفٌ أثناء تكرارٍ كسول على الشجرة سلوكٌ غير معرَّف: عنصر يُتخطّى
/// أو استثناء تعديلٍ متزامن.
EngineResult<List<String>> rewriteXmlParts(
  DocumentPackage package,
  PartClassifier classify,
  ElementRewriter onElement,
) {
  final changed = <String>[];

  for (final partName in package.partNames) {
    if (classify(partName) == PartClass.other) continue;

    final original = package.textOf(partName);
    if (original == null) continue;

    final XmlDocument document;
    try {
      document = XmlDocument.parse(original);
    } on XmlException catch (e) {
      return Failed([
        EngineIssue(code: IssueCode.malformedXml, part: partName, detail: '$e'),
      ]);
    }

    for (final element in document.descendants.whereType<XmlElement>().toList(
      growable: false,
    )) {
      onElement(element);
    }

    final rebuilt = serializeOoxml(document);
    if (rebuilt == original) continue;

    final written = package.putText(partName, rebuilt);
    if (written case Failed(:final issues)) return Failed(issues);
    changed.add(partName);
  }

  return Ok(changed);
}
