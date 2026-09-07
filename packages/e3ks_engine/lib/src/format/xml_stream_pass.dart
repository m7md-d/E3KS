/// المرور على أجزاء XML **بلا شجرة**: أحداثٌ تُستهلَك وتُرمى.
///
/// **لماذا:** القياس قال إن بناء الشجرة يكلّف ٢٨٨٢ms على جزءٍ بحجم ٤٥MB
/// بينما المرور عليها ٣٨٩ms — سبعة أضعافٍ لما نفعله بها. والذاكرة أسوأ:
/// مليون وأربعمئة ألف كائن عنصر ومليون وستمئة ألف كائن سمة. والفحص **قراءة
/// محضة** لا يحتاج شجرةً أصلًا.
///
/// **وما يحتاجه الفاحص من الشجرة ثلاثة، وكلّها تُبنى من مكدّس:**
///
/// 1. **اسم الأب** — `w:shd` في `rPr` نصٌّ وفي `tcPr` خليّة (`02` §5).
/// 2. **وجود جدٍّ بعينه** — `a:srgbClr` داخل `a:clrScheme` لوحة ثيم لا استعمال.
/// 3. **عيّنة النصّ** — وهي العقدة: النصّ يأتي **بعد** اللون في التدفّق.
///    فتُؤجَّل: يُسجَّل طلبُ العيّنة، ويُلبّى عند إغلاق الـ`run` أو الفقرة.
///    والنتيجة مطابقة لصعود الشجرة: أقرب `run` فإن خلا نصّه فالفقرة.
///
/// **ومساحات الأسماء تُحلّ لا تُخمَّن.** الأحداث تعطي الاسم المؤهَّل خامًّا
/// (`w:color`)، فنتتبّع إعلانات `xmlns` في المكدّس ونردّ البادئة إلى مسارها.
/// المطابقة بالبادئة وحدها تفترض أن Word لن يسمّيها يومًا بغير `w` (`02` §2).
library;

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import '../diagnostics/engine_issue.dart';
import '../inspect/part_class.dart';
import '../package/document_package.dart';

/// يصنّف جزءًا داخل الحاوية. [PartClass.other] يعني «لا يُفحَص».
typedef PartClassifier = PartClass Function(String partName);

/// أين تسكن نصوص هذه الصيغة: مساحة الاسم، والـ`run`، والفقرة، وعنصر النصّ.
///
/// Word يكتبها `w:r`/`w:p`/`w:t` و PowerPoint `a:r`/`a:p`/`a:t` — نفس البنية
/// بمساحتين، فتُمرَّر ولا تُكرَّر.
final class TextShape {
  const TextShape({
    required this.namespace,
    this.run = 'r',
    this.paragraph = 'p',
    this.text = 't',
  });

  final String namespace;
  final String run;
  final String paragraph;
  final String text;
}

/// عنصرٌ مقروء من التدفّق، ومعه ما يلزم من سياقه.
final class ScannedElement {
  ScannedElement._(this._pass, this._event, this._namespace);

  final _StreamPass _pass;
  final XmlStartElementEvent _event;
  final String? _namespace;

  String get localName => _local(_event.name);

  /// مسار مساحة اسم العنصر، أو `null` إن لم يُعلَن لبادئته شيء.
  String? get namespaceUri => _namespace;

  /// الاسم المحلّي للعنصر الحاوي، أو `null` عند الجذر.
  String? get parentLocalName => _pass.parentLocalName;

  /// هل يعلو هذا العنصرَ جدٌّ بهذا الاسم المحلّي؟
  bool hasAncestor(String localName) => _pass.hasAncestor(localName);

  /// اسم **أقرب** جدٍّ من [names]، أو `null` إن لم يكن فيهم أحد.
  ///
  /// القرب هو المعنى كلّه: لونٌ داخل `a:rPr` نصٌّ ولو كان الشكل حوله
  /// `a:spPr`. والمكدّس مرتَّب من الجذر، فيُقرأ من آخره.
  String? nearestAncestor(Set<String> names) => _pass.nearestAncestor(names);

  /// قيمة سمة. [namespace] فارغة تعني سمةً بلا بادئة — وهو معنى XML نفسه:
  /// المساحة الافتراضية لا تسري على السمات.
  String? attribute(String name, {String? namespace}) {
    for (final attribute in _event.attributes) {
      final raw = attribute.name;
      if (namespace == null) {
        if (raw == name) return attribute.value;
        continue;
      }
      final colon = raw.indexOf(':');
      if (colon < 0 || raw.substring(colon + 1) != name) continue;
      if (_pass.resolve(raw.substring(0, colon)) == namespace) {
        return attribute.value;
      }
    }
    return null;
  }

  /// يطلب عيّنة نصّ لِما سُجِّل الآن، تُسلَّم حين يُعرَف نصّ الـ`run` أو الفقرة.
  ///
  /// خارج أي `run` أو فقرة **لا تُسلَّم عيّنة** — وهو ما تفعله الشجرة تمامًا:
  /// تظليل خليّةٍ لا يجد فوقه فقرةً فيرجع بلا عيّنة.
  void deferSample(void Function(String sample) assign) =>
      _pass.deferSample(assign);
}

/// يُستدعى لكل عنصر في جزء مفحوص.
typedef StreamScanner =
    void Function(ScannedElement element, String partName, PartClass partClass);

/// مرور قراءة بلا شجرة. يملأ [scannedParts] ويُرجع تحذيرات الأجزاء التالفة.
///
/// **الجزء التالف لا يُسقط الفحص ولا يُبتلَع صامتًا** (`00` §5) — كما في
/// مرور الشجرة تمامًا، فالسلوك واحد والوسيلة وحدها تغيّرت.
List<EngineIssue> scanXmlPartsStreamed(
  DocumentPackage package,
  PartClassifier classify,
  StreamScanner onElement, {
  required List<String> scannedParts,
  required TextShape textShape,
}) {
  final warnings = <EngineIssue>[];

  for (final partName in package.partNames) {
    final partClass = classify(partName);
    if (partClass == PartClass.other) continue;

    final text = package.textOf(partName);
    if (text == null) continue;

    final pass = _StreamPass(textShape);
    try {
      for (final event in parseEvents(text, validateNesting: true)) {
        pass.handle(event, (element) {
          onElement(element, partName, partClass);
        });
      }
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
    // الجزء الذي بلغ آخره سليمًا هو الذي يُعدّ مفحوصًا: التالف يُستثنى بعد
    // تحذيره، كما يستثنيه مرور الشجرة حين يسقط تحليله.
    scannedParts.add(partName);
  }

  return warnings;
}

String _local(String qualified) {
  final colon = qualified.indexOf(':');
  return colon < 0 ? qualified : qualified.substring(colon + 1);
}

/// إطار نصّ مفتوح: `run` أو فقرة، بنصّه المتجمّع وطلبات عيّناته.
final class _TextFrame {
  _TextFrame(this.isRun);
  final bool isRun;
  final StringBuffer buffer = StringBuffer();
  final List<void Function(String)> pending = [];
}

/// أقصى ما يُجمَع من نصّ قبل التوقّف — نفس حدّ العيّنة في مرور الشجرة.
const int _sampleBudget = 60;

final class _StreamPass {
  _StreamPass(this.shape);

  final TextShape shape;

  /// أسماء العناصر المفتوحة، من الجذر إلى الحالي، ومسارات مساحاتها معها.
  ///
  /// **المساحة تُحفظ لا تُستنتج من الاسم**: عنصرٌ اسمه `r` في مساحة أخرى
  /// ليس `run`، وإغلاقه بالاسم وحده يُنهي إطار نصٍّ لم يفتحه.
  final List<String> _open = [];
  final List<String?> _openNamespace = [];

  /// إعلانات `xmlns` سارية، الأحدث آخرًا. `''` بادئةُ المساحة الافتراضية.
  final List<Map<String, String>> _scopes = [];

  /// لكل عنصر مفتوح: هل دفع نطاق مساحات أسماء؟ فيُرفَع عند إغلاقه.
  final List<bool> _pushedScope = [];

  final List<_TextFrame> _frames = [];

  String? get parentLocalName =>
      _open.length < 2 ? null : _open[_open.length - 2];

  bool hasAncestor(String localName) {
    // آخر عنصر هو الحالي نفسه، فلا يُعدّ جدًّا لنفسه.
    for (var i = 0; i < _open.length - 1; i++) {
      if (_open[i] == localName) return true;
    }
    return false;
  }

  String? nearestAncestor(Set<String> names) {
    for (var i = _open.length - 2; i >= 0; i--) {
      if (names.contains(_open[i])) return _open[i];
    }
    return null;
  }

  String? resolve(String prefix) {
    for (var i = _scopes.length - 1; i >= 0; i--) {
      final uri = _scopes[i][prefix];
      if (uri != null) return uri;
    }
    return null;
  }

  void deferSample(void Function(String) assign) {
    if (_frames.isEmpty) return;
    _frames.last.pending.add(assign);
  }

  void handle(XmlEvent event, void Function(ScannedElement) visit) {
    switch (event) {
      case XmlStartElementEvent():
        _start(event, visit);
        if (event.isSelfClosing) _end(_local(event.name));
      case XmlEndElementEvent():
        _end(_local(event.name));
      case XmlTextEvent():
        _text(event.value);
      case XmlCDATAEvent():
        _text(event.value);
      default:
        break;
    }
  }

  void _start(XmlStartElementEvent event, void Function(ScannedElement) visit) {
    final declarations = <String, String>{};
    for (final attribute in event.attributes) {
      final raw = attribute.name;
      if (raw == 'xmlns') {
        declarations[''] = attribute.value;
      } else if (raw.startsWith('xmlns:')) {
        declarations[raw.substring(6)] = attribute.value;
      }
    }
    if (declarations.isNotEmpty) _scopes.add(declarations);
    _pushedScope.add(declarations.isNotEmpty);

    final name = event.name;
    final colon = name.indexOf(':');
    final namespace = resolve(colon < 0 ? '' : name.substring(0, colon));

    _open.add(colon < 0 ? name : name.substring(colon + 1));
    _openNamespace.add(namespace);

    if (namespace == shape.namespace) {
      final local = _open.last;
      if (local == shape.run) {
        _frames.add(_TextFrame(true));
      } else if (local == shape.paragraph) {
        _frames.add(_TextFrame(false));
      }
    }

    visit(ScannedElement._(this, event, namespace));
  }

  void _end(String localName) {
    final namespace = _openNamespace.isEmpty ? null : _openNamespace.last;
    if (_frames.isNotEmpty &&
        namespace == shape.namespace &&
        (localName == shape.run || localName == shape.paragraph)) {
      _closeFrame();
    }
    if (_pushedScope.isNotEmpty && _pushedScope.removeLast()) {
      _scopes.removeLast();
    }
    if (_open.isNotEmpty) _open.removeLast();
    if (_openNamespace.isNotEmpty) _openNamespace.removeLast();
  }

  /// يُغلق إطارًا ويسلّم عيّناته.
  ///
  /// **هذا هو المكافئ الدقيق لصعود الشجرة**: نصّ الـ`run` إن وُجد، وإلّا
  /// ارتفع الطلب إلى الفقرة، وإلّا سقط بلا عيّنة.
  void _closeFrame() {
    final frame = _frames.removeLast();
    final text = frame.buffer.toString().trim();

    if (text.isNotEmpty) {
      final sample = text.length <= _sampleBudget
          ? text
          : '${text.substring(0, _sampleBudget)}…';
      for (final assign in frame.pending) {
        assign(sample);
      }
      return;
    }
    // نصٌّ خالٍ: طلبات الـ`run` ترتفع إلى فقرته، وطلبات الفقرة تسقط.
    if (frame.isRun && _frames.isNotEmpty) {
      _frames.last.pending.addAll(frame.pending);
    }
  }

  void _text(String value) {
    if (_frames.isEmpty || _open.isEmpty) return;
    if (_open.last != shape.text) return;
    if (_openNamespace.last != shape.namespace) return;
    for (final frame in _frames) {
      if (frame.buffer.length < _sampleBudget) frame.buffer.write(value);
    }
  }
}
