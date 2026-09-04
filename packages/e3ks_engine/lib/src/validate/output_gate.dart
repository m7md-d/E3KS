/// بوابة التحقّق قبل الكتابة — `02` §9.
///
/// **إخفاق واحد ⇒ لا كتابة.** مخرج مفقود أفضل من مخرج مكسور (`00` §١/٢).
///
/// كل فحص هنا مشتقّ من انكسار حقيقي وقع، لا من احتمال نظري.
library;

import 'package:xml/xml.dart';

import '../diagnostics/engine_issue.dart';
import '../ooxml/ooxml_names.dart';
import '../package/document_package.dart';

final class OutputGate {
  const OutputGate();

  /// يفحص الأجزاء التي تغيّرت فقط — ما لم يُمَس لا يحتاج فحصًا.
  ///
  /// يُرجع قائمة فارغة إذا كان المخرج صالحًا للكتابة.
  List<EngineIssue> check(DocumentPackage package) {
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

      final XmlDocument document;
      try {
        document = XmlDocument.parse(text);
      } on XmlException catch (e) {
        issues.add(
          EngineIssue(
            code: IssueCode.malformedXml,
            part: partName,
            detail: '$e',
          ),
        );
        continue;
      }

      issues.addAll(_checkEmptyText(partName, document));
      issues.addAll(_checkFields(partName, document));
    }

    return issues;
  }

  /// عنصر `w:t` بلا نص يُنهي مستورد Google Docs بـ NullPointerException:
  /// `getText()` يُرجع `null` ثم يُنادى `.trim()` عليها.
  ///
  /// Word يفتحه بلا شكوى — ولهذا بالضبط نحتاج هذا الفحص (`00` §١/٥، `02` §3).
  List<EngineIssue> _checkEmptyText(String partName, XmlDocument document) {
    var count = 0;
    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.name.namespaceUri != wNs || element.name.local != 't') {
        continue;
      }
      if (element.children.whereType<XmlText>().isEmpty) count++;
    }
    if (count == 0) return const [];
    return [
      EngineIssue(
        code: IssueCode.emptyTextNode,
        part: partName,
        args: {'count': count},
        detail:
            'remove the w:t element instead of emptying it; '
            'drop the run if only rPr remains',
      ),
    ];
  }

  /// حقول Word (`PAGE`، `TOC`، `REF`…) بنيتها `begin … separate … end`.
  ///
  /// اختلال التوازن يعني أن مرورًا ما حذف جزءًا من آلة الحقل، وأثره لا يظهر
  /// عند الفتح بل بعد الطباعة: رقم صفحة مجمَّد أو فهرس لا يتحدّث (`02` §4).
  List<EngineIssue> _checkFields(String partName, XmlDocument document) {
    var depth = 0;
    var minDepth = 0;
    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.name.namespaceUri != wNs) continue;
      if (element.name.local != 'fldChar') continue;
      switch (element.getAttribute('fldCharType', namespace: wNs)) {
        case 'begin':
          depth++;
        case 'end':
          depth--;
          if (depth < minDepth) minDepth = depth;
      }
    }
    if (depth == 0 && minDepth == 0) return const [];
    return [
      EngineIssue(
        code: IssueCode.unbalancedField,
        part: partName,
        detail: 'final depth=$depth, min depth=$minDepth',
      ),
    ];
  }
}
