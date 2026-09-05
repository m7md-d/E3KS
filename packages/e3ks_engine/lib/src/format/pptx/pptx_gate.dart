/// فحوص ما قبل الكتابة الخاصّة بـPowerPoint.
///
/// **نطاقها محدّد: ما قد نكسره نحن.** لا نفحص عيوبًا في ملفّ المستخدم لم
/// نصنعها — رفض الكتابة بسببها يمنعه من عمله بلا ذنب منّا. ولذلك لا مقابل
/// هنا لفحص `w:t` الفارغ: مسارنا في PowerPoint لا يلمس النصّ أصلًا.
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
    var emptyTypefaces = 0;

    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.name.namespaceUri != aNs) continue;

      // لون بست خانات ست عشرية أو لا شيء: قيمة مشوّهة تجعل PowerPoint
      // يعرض حوار «الملف تالف، هل نصلحه؟» — وهو أسوأ ما قد يراه المستخدم.
      if (element.name.local == 'srgbClr') {
        final value = element.getAttribute('val');
        if (value == null || !_sixHex.hasMatch(value)) badColors++;
      }

      // اسم خطّ فارغ يُسقط النصّ إلى خطّ افتراضي بلا إشعار.
      if (const {'latin', 'cs', 'ea', 'sym'}.contains(element.name.local)) {
        final typeface = element.getAttribute('typeface');
        if (typeface != null && typeface.isEmpty) emptyTypefaces++;
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
    if (emptyTypefaces > 0) {
      issues.add(
        EngineIssue(
          code: IssueCode.malformedXml,
          part: partName,
          args: {'count': emptyTypefaces},
          detail: 'a:latin/@typeface and siblings must not be empty',
        ),
      );
    }
  });

  return issues;
}
