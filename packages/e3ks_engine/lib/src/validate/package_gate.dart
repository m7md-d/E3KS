/// فحوص الحاوية قبل الكتابة — مشتركة بين كل الصيغ.
///
/// **إخفاق واحد ⇒ لا كتابة.** مخرج مفقود أفضل من مخرج مكسور (`00` §١/٢).
///
/// ما هنا يصحّ على أي حاوية OOXML: ترتيب المُدخَلات، وسلامة XML. أمّا ما
/// يخصّ صيغةً بعينها فيسكن مع صيغته — `format/<الصيغة>/*_gate.dart` — ويمرّ
/// **على التدفّق نفسه** بدل أن يفتح مرورًا ثانيًا.
///
/// **ولماذا مرورٌ واحد:** كانت البوابة تحلّل كل جزء ممسوس **مرّتين** —
/// مرّةً لتتأكّد أنه يُحلَّل ثم ترمي الشجرة، ومرّةً لبوابة الصيغة. وقياسها
/// على مستند بثمانمئة صفحة: ٢٫٨ ثانية + ٥٫١ = ٧٫٩، وهي أغلى من التبديل
/// نفسه. والآن مرورٌ تدفّقيّ واحد يفعل الاثنين.
///
/// **والتحليل الثالث لا يُحذف**: التبديل يحلّل ثم يُسلسِل، والبوابة يجب أن
/// تفحص **النصّ المكتوب** لا شجرة التبديل — وذاك غرضها كلّه.
library;

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import '../diagnostics/engine_issue.dart';
import '../package/document_package.dart';

/// فاحصُ صيغةٍ على تدفّق جزءٍ واحد.
///
/// يُنشَأ لكل جزء ممسوس، ويُغذّى بأحداثه، ثم يُسأل عمّا وجد. وحالتُه محصورة
/// في الجزء، فلا تتسرّب عدّةُ جزءٍ إلى تقرير غيره.
abstract interface class PartGate {
  void visit(XmlEvent event);

  /// ما وُجد في هذا الجزء. فارغة عند السلامة.
  List<EngineIssue> finish();
}

/// يُنشئ فاحص الصيغة لجزء، أو `null` إن كان لا يعنيها.
typedef PartGateFactory = PartGate? Function(String partName);

/// يفحص الحاوية والأجزاء التي تغيّرت فقط — ما لم يُمَس لا يحتاج فحصًا.
///
/// [gateFor] فاحص الصيغة، يمرّ على نفس الأحداث بلا مرورٍ ثانٍ.
List<EngineIssue> checkPackage(
  DocumentPackage package, {
  PartGateFactory? gateFor,
}) {
  final issues = <EngineIssue>[];

  if (package.partNames.isEmpty ||
      package.partNames.first != DocumentPackage.contentTypesPart) {
    issues.add(
      const EngineIssue(
        code: IssueCode.contentTypesNotFirst,
        part: DocumentPackage.contentTypesPart,
      ),
    );
  }

  for (final partName in package.touchedParts) {
    final text = package.textOf(partName);
    if (text == null) continue;

    final gate = gateFor?.call(partName);
    try {
      // `validateNesting` يجعل التدفّق يرفض ما يرفضه التحليل الكامل: وسمٌ
      // لا يُغلَق أو يُغلَق بغير اسمه. وبدونها يمرّ الخلل صامتًا.
      for (final event in parseEvents(text, validateNesting: true)) {
        gate?.visit(event);
      }
    } on XmlException catch (e) {
      issues.add(
        EngineIssue(code: IssueCode.malformedXml, part: partName, detail: '$e'),
      );
      // جزءٌ لا يُحلَّل لا تُصدَّق حصيلةُ فاحصه عليه.
      continue;
    }
    if (gate != null) issues.addAll(gate.finish());
  }

  return issues;
}
