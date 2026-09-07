// يقيس **ذروة الذاكرة** لفحص مستند بأربعة نُهُج، لتُقارَن أرضياتها.
//
// **الرقم الذي غيّر التصميم:** مستند بثمانمئة صفحة كان يبلغ ٩٢٦MB بشجرة
// XML، فصار ٢٠٠MB بالفحص التدفّقي، والأرضية الممكنة ١٤٢MB بتدفّقٍ من القرص
// أيضًا. والمعاينة المحفوظة رخيصة (نحو ٥MB لمئة صفحة)؛ الغالي **بناؤها**.
//
//   dart compile exe tool/measure_memory.dart -o /tmp/mem
//   /usr/bin/time -l /tmp/mem <ملف.docx> <tree|text|stream|preview> [عدد]
//
// **تُترجَم قبل القياس ولا تُشغَّل بـ`dart run`:** المشغّل يحمل المترجم
// ونواته معه، فيضيف نحو ١٧٠MB إلى الذروة ويغرق ما نقيسه. الأساس
// المُترجَم ١١MB.
//
//   engine   ما يفعله المحرّك الآن: الملف بايتاتٍ كاملة، ثم فحصٌ بالتدفّق
//   text     أحداثٌ بلا شجرة، لكن الجزء كلّه نصٌّ واحد في الذاكرة
//   stream   تدفّق كامل: الحاوية من القرص، والجزء مقاطع، ولا نصّ كامل قطّ
//   preview  ما تزنه معاينةٌ محفوظة — تُبنى [عدد] مرّة وتُمسَك كلّها

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:xml/xml_events.dart';

Stream<List<int>> _chunks(InputStream input, {int size = 64 * 1024}) async* {
  // `length` في هذه الحزمة هو **الباقي** لا الكلّي؛ طرح الموضع منه يُنقصه مرّتين.
  while (!input.isEOS) {
    final left = input.length;
    yield input.readBytes(left < size ? left : size).toUint8List();
  }
}

Future<void> main(List<String> args) async {
  final path = args[0];
  final mode = args[1];
  final watch = Stopwatch()..start();
  var colors = 0;

  switch (mode) {
    // أ — المحرّك كما هو: الملف كلّه بايتات، والفحص عليها.
    case 'engine':
      final bytes = Uint8List.fromList(File(path).readAsBytesSync());
      final package =
          (DocumentPackage.open(bytes) as Ok<DocumentPackage>).value;
      final format = (formatFor(package) as Ok<DocumentFormat>).value;
      colors =
          (format.inspect(package) as Ok<InspectionReport>).value.colors.length;

    // ب — تدفّق، لكن الجزء كلّه نصٌّ واحد في الذاكرة.
    case 'text':
      final bytes = Uint8List.fromList(File(path).readAsBytesSync());
      final package =
          (DocumentPackage.open(bytes) as Ok<DocumentPackage>).value;
      for (final part in package.partNames) {
        if (!part.endsWith('.xml')) continue;
        final text = package.textOf(part);
        if (text == null) continue;
        for (final event in parseEvents(text)) {
          if (event is XmlStartElementEvent) colors += event.attributes.length;
        }
      }

    // ج — تدفّق كامل: الحاوية من القرص، والجزء مقاطع، ولا نصّ كامل قطّ.
    case 'stream':
      final input = InputFileStream(path);
      final archive = ZipDecoder().decodeStream(input);
      for (final file in archive.files) {
        if (!file.name.endsWith('.xml') || !file.isFile) continue;
        final content = file.getContent();
        if (content == null) continue;
        await for (final events in _chunks(
          content,
        ).transform(utf8.decoder).toXmlEvents()) {
          for (final event in events) {
            if (event is XmlStartElementEvent) {
              colors += event.attributes.length;
            }
          }
        }
        file.closeSync();
      }
      await input.close();

    // د — ما تزنه المعاينة وحدها محفوظةً، وهو ما تحمله المجموعة لكل ملفّ مفتوح.
    case 'preview':
      final previews = <DocumentPreview>[];
      final count = args.length > 2 ? int.parse(args[2]) : 1;
      for (var i = 0; i < count; i++) {
        final bytes = Uint8List.fromList(File(path).readAsBytesSync());
        final package =
            (DocumentPackage.open(bytes) as Ok<DocumentPackage>).value;
        final format = (formatFor(package) as Ok<DocumentFormat>).value;
        previews.add(format.preview(package));
      }
      colors = previews.fold(0, (sum, p) => sum + p.pageCount);
  }

  stdout.writeln(
    '$mode  ${watch.elapsedMilliseconds}ms  '
    'حصيلة $colors  ذاكرة ${(ProcessInfo.currentRss / 1e6).round()}MB',
  );
}
