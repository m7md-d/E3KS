// يفكّك كلفة جزء XML واحد إلى مراحله، ويقارن الشجرة بالتدفّق.
//
// **هذه الأداة هي التي قلبت التشخيص.** كان الظنّ أن البطء في منطقنا أو في
// Dart؛ والقياس قال إن المرور على الشجرة ٢١٦ms بينما **بناؤها** ٢٧٧٧ms على
// نفس الجزء — ثلاثة عشر ضعفًا لما نفعله بها. ولا لغةٌ تصلح ما سبّبه الهيكل.
//
// وتقيس معها المسار البديل: `parseEvents` بلا شجرة، فيُعرف السقف الممكن
// قبل أن يُدفع ثمنٌ معماري لتجاوزه.
//
//   dart tool/measure_xml_cost.dart <ملف.docx> [اسم الجزء]
//
// الجزء الافتراضي `word/document.xml` — وهو تسعة أعشار بايتات المستند عادةً.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('الاستعمال: measure_xml_cost.dart <ملف.docx> [جزء]');
    exit(64);
  }
  final partName = args.length > 1 ? args[1] : 'word/document.xml';
  final bytes = Uint8List.fromList(File(args[0]).readAsBytesSync());

  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) {
    stderr.writeln('تعذّر الفتح: ${issues.first.code.name}');
    exit(1);
  }
  final package = (opened as Ok<DocumentPackage>).value;

  final watch = Stopwatch()..start();
  final raw = package.bytesOf(partName);
  if (raw == null) {
    stderr.writeln('لا جزء بهذا الاسم: $partName');
    exit(1);
  }
  final inflate = watch.elapsedMilliseconds;

  watch.reset();
  final text = utf8.decode(raw);
  final decode = watch.elapsedMilliseconds;

  watch.reset();
  final document = XmlDocument.parse(text);
  final parse = watch.elapsedMilliseconds;

  watch.reset();
  var elements = 0;
  var attributes = 0;
  for (final node in document.descendants) {
    if (node is XmlElement) {
      elements++;
      attributes += node.attributes.length;
    }
  }
  final walk = watch.elapsedMilliseconds;

  watch.reset();
  document.toXmlString();
  final serialise = watch.elapsedMilliseconds;
  final treeRss = ProcessInfo.currentRss;

  watch.reset();
  var events = 0;
  for (final event in parseEvents(text)) {
    if (event is XmlStartElementEvent) events += event.attributes.length;
    events++;
  }
  final streamed = watch.elapsedMilliseconds;

  stdout.writeln('''
$partName — ${(raw.length / 1e6).toStringAsFixed(1)}MB،
  $elements عنصرًا و$attributes سمة

  فكّ الضغط        ${inflate}ms
  فكّ الترميز      ${decode}ms
  بناء الشجرة      ${parse}ms      ← الكلفة الكبرى
  المرور عليها     ${walk}ms       ← منطقنا
  تسلسلها          ${serialise}ms
  ---
  تدفّق بلا شجرة   ${streamed}ms   ($events حدثًا وسمة)
  ذاكرة مع الشجرة  ${(treeRss / 1e6).round()}MB''');
}
