/// فحوص ما قبل الكتابة الخاصّة بـPowerPoint.
///
/// **نطاقها محدّد: ما قد نكسره نحن.** لا نفحص عيوبًا في ملفّ المستخدم لم
/// نصنعها — رفض الكتابة بسببها يمنعه من عمله بلا ذنب منّا. ولذلك لا مقابل
/// هنا لفحص `w:t` الفارغ: مسارنا في PowerPoint لا يلمس النصّ أصلًا.
///
/// **وكان هنا فحصٌ يخالف هذا الحدّ:** يرفض كل `@typeface` فارغة. وثيم Office
/// القياسي يكتب `<a:ea typeface=""/>` و`<a:cs typeface=""/>` في كل عرض، فكان
/// المحرّك يرفض الكتابة لأول عرض حقيقي مرّ عليه — وعيبٌ لم نصنعه. المحوّل
/// أصلًا لا يلمس خانة فارغة، والخطر الوحيد اسمُ خطٍّ فارغ في الخطة، وحارسه
/// في `FontPlan` لا هنا.
library;

import 'package:xml/xml.dart';

import '../../diagnostics/engine_issue.dart';
import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';
import '../../validate/package_gate.dart';

final RegExp _sixHex = RegExp(r'^[0-9A-Fa-f]{6}$');

List<EngineIssue> checkPptx(DocumentPackage package) {
  final issues = <EngineIssue>[];

  forEachTouchedDocument(package, (partName, document) {
    var badColors = 0;

    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.name.namespaceUri != aNs) continue;

      // لون بست خانات ست عشرية أو لا شيء: قيمة مشوّهة تجعل PowerPoint
      // يعرض حوار «الملف تالف، هل نصلحه؟» — وهو أسوأ ما قد يراه المستخدم.
      if (element.name.local == 'srgbClr') {
        final value = element.getAttribute('val');
        if (value == null || !_sixHex.hasMatch(value)) badColors++;
      }
    }

    if (badColors > 0) {
      issues.add(
        EngineIssue(
          code: IssueCode.malformedXml,
          part: partName,
          args: {'count': badColors},
          detail: 'a:srgbClr/@val must be exactly six hex digits',
        ),
      );
    }
  });

  return issues;
}
