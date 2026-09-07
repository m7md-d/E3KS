// يبني نسخًا مكبَّرة من مستندٍ حقيقي لقياس كلفة المستند الطويل.
//
// **لماذا يُصنَع بدل أن يُجمَع:** مستندات العملاء لا تدخل المستودع (`03`)،
// ومستندات `fixtures/` صغيرة عمدًا. فيبقى قياس الثمانمئة صفحة معلَّقًا على
// ملفٍّ لا يُشارَك — ما لم يُصنَع من ملفٍّ يملكه من يقيس.
//
// الطريقة: تكرار أبناء `<w:body>` مع إبقاء `<w:sectPr>` آخرًا — فيخرج مستند
// صحيح البنية بحجمٍ مضبوط، وبقيّة الأجزاء تُنسخ كما هي عبر `DocumentPackage`.
//
//   dart tool/grow_document.dart <مستند.docx> <مجلد المخرَج> 1 2 4 8
//
// **والناتج خارج الشجرة**: مجلد مؤقّت، لا `fixtures/`.

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';

const _bodyOpen = '<w:body';
const _bodyClose = '</w:body>';

void main(List<String> args) {
  if (args.length < 3) {
    stderr.writeln('الاستعمال: grow_document.dart <مستند> <مجلد> <مضاعفات…>');
    exit(64);
  }
  final source = File(args[0]);
  final outDirectory = Directory(args[1])..createSync(recursive: true);
  final factors = [for (final a in args.skip(2)) int.parse(a)];

  final bytes = Uint8List.fromList(source.readAsBytesSync());
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) {
    stderr.writeln('تعذّر فتح المصدر: ${issues.map((i) => i.code.name)}');
    exit(1);
  }
  final text = (opened as Ok<DocumentPackage>).value.textOf(
    'word/document.xml',
  );
  if (text == null) {
    stderr.writeln('لا `word/document.xml` في المصدر — المستند ليس Word.');
    exit(1);
  }

  final bodyStart = text.indexOf('>', text.indexOf(_bodyOpen)) + 1;
  final bodyEnd = text.lastIndexOf(_bodyClose);
  final head = text.substring(0, bodyStart);
  final tail = text.substring(bodyEnd);
  final body = text.substring(bodyStart, bodyEnd);

  // `sectPr` الأخير يصف القسم الذي ينتهي عنده (`02` §7/1)، فيبقى آخرًا
  // ولا يتكرّر — تكراره يُدخل أقسامًا وهمية ويغيّر مقاسات الصفحات.
  final sectionAt = body.lastIndexOf('<w:sectPr');
  final repeatable = sectionAt < 0 ? body : body.substring(0, sectionAt);
  final section = sectionAt < 0 ? '' : body.substring(sectionAt);

  for (final factor in factors) {
    // نسخة جديدة لكل مضاعف: `putText` تعلّم الجزء ممسوسًا، والحاوية تُبنى مرّة.
    final package = (DocumentPackage.open(bytes) as Ok<DocumentPackage>).value;
    final grown = head + (repeatable * factor) + section + tail;
    package.putText('word/document.xml', grown);

    final built = package.build();
    if (built case Failed(:final issues)) {
      stderr.writeln('$factor×: ${issues.map((i) => i.code.name)}');
      continue;
    }
    final out = File('${outDirectory.path}/grown_${factor}x.docx')
      ..writeAsBytesSync((built as Ok<Uint8List>).value);

    final paragraphs = RegExp('<w:p[ >]').allMatches(grown).length;
    stdout.writeln(
      '${factor}x  حاوية ${(out.lengthSync() / 1e6).toStringAsFixed(1)}MB  '
      'xml ${(grown.length / 1e6).toStringAsFixed(1)}MB  '
      'فقرات $paragraphs',
    );
  }
}
