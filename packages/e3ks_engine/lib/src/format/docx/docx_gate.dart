/// فحوص ما قبل الكتابة الخاصّة بـWord.
///
/// كلاهما مشتقّ من انكسار حقيقي وقع عند مستورد لا يتسامح كما يتسامح Word
/// (`00` §١/٥). ولأنهما يخصّان `w:` وحده، **يسكنان مع صيغتهما**: لا يمرّان
/// على عرض PowerPoint ولا يُبطئانه ولا يُبلّغان عنه بالخطأ.
///
/// **وكلاهما تدفّقيّ بطبعه**: عدُّ `w:t` بلا نصّ، وموازنةُ `fldChar`. فيمرّان
/// على أحداث البوابة المشتركة بلا تحليلٍ ثانٍ للجزء.
library;

import 'package:xml/xml_events.dart';

import '../../diagnostics/engine_issue.dart';
import '../../ooxml/ooxml_names.dart';
import '../../validate/package_gate.dart';
import '../xml_stream_pass.dart';

/// فاحص جزءٍ من مستند Word.
final class DocxPartGate implements PartGate {
  DocxPartGate(this.partName);

  final String partName;

  final XmlNamespaces _namespaces = XmlNamespaces();

  /// عمق `w:t` المفتوح، أو `-1` إن لم يكن مفتوحًا.
  int _textDepth = -1;
  bool _textHasContent = false;
  int _depth = 0;

  int _emptyText = 0;
  int _fieldDepth = 0;
  int _fieldMinDepth = 0;

  @override
  void visit(XmlEvent event) {
    switch (event) {
      case XmlStartElementEvent():
        final namespace = _namespaces.open(event);
        final local = localNameOf(event.name);
        if (namespace == wNs) {
          if (local == 't') {
            if (event.isSelfClosing) {
              _emptyText++;
            } else {
              _textDepth = _depth;
              _textHasContent = false;
            }
          } else if (local == 'fldChar') {
            _field(event);
          }
        }
        if (event.isSelfClosing) {
          _namespaces.close();
        } else {
          _depth++;
        }

      case XmlEndElementEvent():
        _depth--;
        if (_textDepth == _depth) {
          if (!_textHasContent) _emptyText++;
          _textDepth = -1;
        }
        _namespaces.close();

      // **العقدة النصّية وحدها تُعدّ محتوًى.** `CDATA` ليست `XmlText` في
      // الشجرة، فلا تُعدّ هنا أيضًا — والفحصان يتطابقان.
      case XmlTextEvent():
        if (_textDepth >= 0) _textHasContent = true;

      default:
        break;
    }
  }

  void _field(XmlStartElementEvent event) {
    for (final attribute in event.attributes) {
      if (localNameOf(attribute.name) != 'fldCharType') continue;
      if (_namespaces.namespaceOfAttribute(attribute.name) != wNs) continue;
      switch (attribute.value) {
        case 'begin':
          _fieldDepth++;
        case 'end':
          _fieldDepth--;
          if (_fieldDepth < _fieldMinDepth) _fieldMinDepth = _fieldDepth;
      }
    }
  }

  @override
  List<EngineIssue> finish() => [
    // عنصر `w:t` بلا نص يُنهي مستورد Google Docs بـ NullPointerException:
    // `getText()` يُرجع `null` ثم يُنادى `.trim()` عليها. وWord يفتحه بلا
    // شكوى — ولهذا بالضبط نحتاج هذا الفحص (`00` §١/٥، `02` §3).
    if (_emptyText > 0)
      EngineIssue(
        code: IssueCode.emptyTextNode,
        part: partName,
        args: {'count': _emptyText},
        detail:
            'remove the w:t element instead of emptying it; '
            'drop the run if only rPr remains',
      ),
    // حقول Word (`PAGE`، `TOC`، `REF`…) بنيتها `begin … separate … end`.
    // واختلال التوازن يعني أن مرورًا ما حذف جزءًا من آلة الحقل، وأثره لا
    // يظهر عند الفتح بل بعد الطباعة: رقم صفحة مجمَّد أو فهرس لا يتحدّث.
    if (_fieldDepth != 0 || _fieldMinDepth != 0)
      EngineIssue(
        code: IssueCode.unbalancedField,
        part: partName,
        detail: 'final depth=$_fieldDepth, min depth=$_fieldMinDepth',
      ),
  ];
}
