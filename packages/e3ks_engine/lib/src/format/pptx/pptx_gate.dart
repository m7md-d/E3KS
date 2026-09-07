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

import 'package:xml/xml_events.dart';

import '../../diagnostics/engine_issue.dart';
import '../../ooxml/ooxml_names.dart';
import '../../validate/package_gate.dart';
import '../xml_stream_pass.dart';

final RegExp _sixHex = RegExp(r'^[0-9A-Fa-f]{6}$');

/// فاحص جزءٍ من عرض PowerPoint.
final class PptxPartGate implements PartGate {
  PptxPartGate(this.partName);

  final String partName;
  final XmlNamespaces _namespaces = XmlNamespaces();
  int _badColors = 0;

  @override
  void visit(XmlEvent event) {
    switch (event) {
      case XmlStartElementEvent():
        final namespace = _namespaces.open(event);
        if (namespace == aNs && localNameOf(event.name) == 'srgbClr') {
          // لون بست خانات ست عشرية أو لا شيء: قيمة مشوّهة تجعل PowerPoint
          // يعرض حوار «الملف تالف، هل نصلحه؟» — وهو أسوأ ما قد يراه المستخدم.
          String? value;
          for (final attribute in event.attributes) {
            if (attribute.name == 'val') value = attribute.value;
          }
          if (value == null || !_sixHex.hasMatch(value)) _badColors++;
        }
        if (event.isSelfClosing) _namespaces.close();

      case XmlEndElementEvent():
        _namespaces.close();

      default:
        break;
    }
  }

  @override
  List<EngineIssue> finish() => [
    if (_badColors > 0)
      EngineIssue(
        code: IssueCode.malformedXml,
        part: partName,
        args: {'count': _badColors},
        detail: 'a:srgbClr/@val must be exactly six hex digits',
      ),
  ];
}
