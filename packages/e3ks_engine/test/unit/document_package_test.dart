/// اختبار الأمانة — القاعدة `04` §1.
///
/// هذا أهم اختبار في المشروع. لو سقط، فالمحرّك يعبث بأجزاء لا شأن له بها،
/// وهذا كسرٌ ينتظر وقته.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';

/// يفتح الحاوية أو يُسقط الاختبار برسالة المشكلة.
DocumentPackage openOrFail(Uint8List bytes) {
  final result = DocumentPackage.open(bytes);
  switch (result) {
    case Ok(:final value):
      return value;
    case Failed(:final issues):
      fail('تعذّر فتح المستند: ${issues.join("، ")}');
  }
}

Uint8List buildOrFail(DocumentPackage pkg) {
  final result = pkg.build();
  switch (result) {
    case Ok(:final value):
      return value;
    case Failed(:final issues):
      fail('تعذّر بناء المستند: ${issues.join("، ")}');
  }
}

/// يؤكّد أن كل جزء في [after] مطابق لمقابله في [before] عدا ما في [expectChanged].
void expectPartsIdentical(
  DocumentPackage before,
  DocumentPackage after, {
  Set<String> expectChanged = const {},
}) {
  expect(
    after.partNames,
    equals(before.partNames),
    reason: 'ترتيب الأجزاء أو عددها تغيّر',
  );

  for (final name in before.partNames) {
    final a = before.bytesOf(name);
    final b = after.bytesOf(name);
    if (expectChanged.contains(name)) {
      expect(b, isNot(equals(a)), reason: 'الجزء $name كان يُفترض أن يتغيّر');
    } else {
      expect(b, equals(a), reason: 'الجزء $name تغيّر دون أن نطلب ذلك');
    }
  }
}

void main() {
  group('الأمانة البايتية', () {
    test('دورة بلا تعديل تُخرج كل جزء كما ورد', () {
      final source = buildFixtureDocx();
      final pkg = openOrFail(source);

      final rebuilt = buildOrFail(pkg);

      expect(pkg.touchedParts, isEmpty, reason: 'لم نطلب أي تعديل');
      expectPartsIdentical(pkg, openOrFail(rebuilt));
    });

    test('قراءة كل الأجزاء لا تُفسد تمريرها كما هي', () {
      // فكّ الضغط أثناء الفحص يجب ألّا يُبطل نسخ التدفّق الأصلي.
      final source = buildFixtureDocx();
      final pkg = openOrFail(source);
      for (final name in pkg.partNames) {
        pkg.bytesOf(name);
      }

      expectPartsIdentical(pkg, openOrFail(buildOrFail(pkg)));
    });

    test('تعديل جزء واحد لا يمسّ البقية', () {
      final source = buildFixtureDocx();
      // مرجع مستقلّ للمقارنة: `pkg` سيتغيّر، وهذا يبقى على الحال الأصلي.
      final original = openOrFail(source);
      final pkg = openOrFail(source);

      final edited = pkg
          .textOf('word/header1.xml')!
          .replaceAll('4C2FB8', '00635D');
      expect(pkg.putText('word/header1.xml', edited).isOk, isTrue);
      expect(pkg.touchedParts, equals({'word/header1.xml'}));

      final after = openOrFail(buildOrFail(pkg));
      expectPartsIdentical(
        original,
        after,
        expectChanged: const {'word/header1.xml'},
      );
      expect(after.textOf('word/header1.xml'), contains('00635D'));
      expect(after.textOf('word/header1.xml'), isNot(contains('4C2FB8')));
    });

    test('يحفظ ترتيب الأجزاء و[Content_Types].xml أولًا', () {
      final pkg = openOrFail(buildFixtureDocx());
      expect(pkg.partNames.first, equals(DocumentPackage.contentTypesPart));
      expect(pkg.partNames, equals(fixtureParts.keys.toList()));
    });

    test('لا يضيف علامة BOM عند كتابة نص', () {
      final pkg = openOrFail(buildFixtureDocx());
      pkg.putText('word/header1.xml', '<w:hdr/>');
      final bytes = pkg.bytesOf('word/header1.xml')!;
      expect(bytes.take(3), isNot(equals(const [0xEF, 0xBB, 0xBF])));
      expect(utf8.decode(bytes), equals('<w:hdr/>'));
    });
  });

  group('رفض المدخلات غير الصالحة', () {
    test('ملف ليس أرشيفًا', () {
      final result = DocumentPackage.open(
        Uint8List.fromList(utf8.encode('هذا نصّ عادي وليس ملفًا')),
      );
      expect(result, isA<Failed<DocumentPackage>>());
      expect(result.issues.single.code, equals(IssueCode.notAnArchive));
    });

    test('أرشيف صالح لكن بلا [Content_Types].xml', () {
      final archive = Archive()
        ..add(
          ArchiveFile.bytes('word/document.xml', utf8.encode('<w:document/>')),
        );
      final result = DocumentPackage.open(ZipEncoder().encodeBytes(archive));

      expect(result, isA<Failed<DocumentPackage>>());
      expect(result.issues.single.code, equals(IssueCode.missingContentTypes));
    });

    test('استبدال جزء غير موجود يُرفض ولا يُضيفه', () {
      final pkg = openOrFail(buildFixtureDocx());
      final before = pkg.partNames.length;
      final result = pkg.putBytes('word/ghost.xml', Uint8List(0));

      expect(result, isA<Failed<void>>());
      expect(result.issues.single.code, equals(IssueCode.partNotFound));
      expect(pkg.partNames.length, equals(before));
      expect(pkg.touchedParts, isEmpty);
    });
  });

  group('مستند حقيقي', () {
    // ملفات العملاء لا تدخل المستودع (`04` §4). إن وُجد الملف محليًا نستعمله،
    // وإلّا تخطّينا — الاختبار الحقيقي أقوى بكثير من أي مستند مصنوع.
    const realPath =
        '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';

    test('دورة بلا تعديل على مستند Word حقيقي', () {
      final file = File(realPath);
      if (!file.existsSync()) {
        markTestSkipped('لا يوجد مستند حقيقي في $realPath');
        return;
      }

      final pkg = openOrFail(file.readAsBytesSync());
      expect(pkg.partNames.length, greaterThan(5));

      expectPartsIdentical(pkg, openOrFail(buildOrFail(pkg)));
    });
  });
}
