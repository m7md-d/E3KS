/// فحوص الحاوية قبل الكتابة — مشتركة بين كل الصيغ.
///
/// **إخفاق واحد ⇒ لا كتابة.** مخرج مفقود أفضل من مخرج مكسور (`00` §١/٢).
///
/// ما هنا يصحّ على أي حاوية OOXML: ترتيب المُدخَلات، وسلامة XML. أمّا ما
/// يخصّ صيغةً بعينها فيسكن مع صيغته — `format/<الصيغة>/*_gate.dart`.
library;

import 'package:xml/xml.dart';

import '../diagnostics/engine_issue.dart';
import '../package/document_package.dart';

/// يفحص الحاوية والأجزاء التي تغيّرت فقط — ما لم يُمَس لا يحتاج فحصًا.
List<EngineIssue> checkPackage(DocumentPackage package) {
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
    try {
      XmlDocument.parse(text);
    } on XmlException catch (e) {
      issues.add(
        EngineIssue(code: IssueCode.malformedXml, part: partName, detail: '$e'),
      );
    }
  }

  return issues;
}

/// يمرّ على الأجزاء المتغيّرة المحلَّلة — أداة لبوّابات الصيغ.
///
/// الجزء الذي لا يُحلَّل تبلّغ عنه [checkPackage]، فلا يُبلَّغ عنه مرّتين.
void forEachTouchedDocument(
  DocumentPackage package,
  void Function(String partName, XmlDocument document) visit,
) {
  for (final partName in package.touchedParts) {
    final text = package.textOf(partName);
    if (text == null) continue;
    final XmlDocument document;
    try {
      document = XmlDocument.parse(text);
    } on XmlException {
      continue;
    }
    visit(partName, document);
  }
}
