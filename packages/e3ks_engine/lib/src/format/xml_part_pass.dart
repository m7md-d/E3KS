/// المرور على أجزاء XML **كتابةً**: التحويل وحده.
///
/// **والقراءة انتقلت إلى [scanXmlPartsStreamed]** في `xml_stream_pass.dart`:
/// الفحص لا يعدّل شيئًا فلا يحتاج شجرة، وبناؤها كان يكلّف أربعة أضعاف
/// المرور عليها وأربعة أضعاف ذاكرته.
///
/// **والشجرة تبقى هنا لأن التحويل يكتب.** يعدّل سمةً ويحذف عنصرًا ثم
/// يُسلسِل، ويحمل قاعدةً لا يجوز أن تُنسى في صيغة جديدة: **لا يُكتب جزء لم
/// تتغيّر بايتاته** (`00` §١/١) — والمقارنة بالبايتات لا بالنيّة، وهي ممكنة
/// لأن [serializeOoxml] يجعل دورة التحليل/التسلسل مطابقة حرفيًا.
library;

import 'package:xml/xml.dart';

import '../diagnostics/engine_issue.dart';
import '../diagnostics/engine_result.dart';
import '../inspect/part_class.dart';
import '../ooxml/ooxml_entity_mapping.dart';
import '../package/document_package.dart';
import 'xml_stream_pass.dart';

/// يُستدعى لكل عنصر في جزء قيد التحويل.
typedef ElementRewriter = void Function(XmlElement element);

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
