/// اختبارات التحويل، وبقيّة اختبارات الانحدار الإلزامية — `04` §3.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';

HexColor hex(String v) => HexColor.tryParse(v)!;

RestyleOutcome restyleOrFail(Uint8List source, StylePlan plan) {
  final result = restyle(source, plan);
  if (result case Failed(:final issues)) fail('تحويل: ${issues.join("، ")}');
  return (result as Ok<RestyleOutcome>).value;
}

DocumentPackage openOrFail(Uint8List bytes) {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) fail('فتح: ${issues.join("، ")}');
  return (opened as Ok<DocumentPackage>).value;
}

/// البوابة كما يستدعيها المسار: فحوص الحاوية المشتركة ثم فحوص الصيغة.
List<EngineIssue> gateOf(DocumentPackage package) => [
  ...checkPackage(package),
  ...formatOrFail(package).validate(package),
];

/// يمرّ عبر الواجهة العامة لا عبر أصناف الصيغة مباشرةً: هكذا يستدعيها
/// التطبيق، وهكذا يُختبَر التعرّف على الصيغة مع كل اختبار.
DocumentFormat formatOrFail(DocumentPackage package) {
  final detected = formatFor(package);
  if (detected case Failed(:final issues)) fail('الصيغة: ${issues.join("، ")}');
  return (detected as Ok<DocumentFormat>).value;
}

void main() {
  group('الأمانة أثناء التحويل', () {
    test('خطة فارغة لا تغيّر أي جزء', () {
      // أقوى برهان على أن التحويل لا يعبث بما لم يُطلَب — `04` §1.
      final source = buildFixtureDocx();
      final outcome = restyleOrFail(source, const StylePlan());

      expect(outcome.report.changedNothing, isTrue);
      final before = openOrFail(source);
      final after = openOrFail(outcome.bytes);
      for (final name in before.partNames) {
        expect(
          after.bytesOf(name),
          equals(before.bytesOf(name)),
          reason: 'الجزء $name تغيّر بخطة فارغة',
        );
      }
    });

    test('تبديل لون واحد يمسّ الأجزاء التي فيها ذلك اللون فقط', () {
      final source = buildFixtureDocx();
      final outcome = restyleOrFail(
        source,
        StylePlan(colors: {hex('4F81BD'): hex('00635D')}),
      );

      // 4F81BD لا يوجد إلا في styles.xml.
      expect(outcome.report.changedParts, equals(['word/styles.xml']));

      final before = openOrFail(source);
      final after = openOrFail(outcome.bytes);
      for (final name in before.partNames) {
        if (name == 'word/styles.xml') continue;
        expect(
          after.bytesOf(name),
          equals(before.bytesOf(name)),
          reason: 'الجزء $name تغيّر بلا سبب',
        );
      }
    });
  });

  group('انحدار إلزامي', () {
    test('#2 — حقل PAGE يخرج سليمًا بناءً وناتجًا', () {
      // تجميد رقم الصفحة خلل لا يظهر عند الفتح، بل بعد الطباعة — `02` §4.
      final outcome = restyleOrFail(
        buildFixtureDocx(),
        const StylePlan(fonts: FontPlan(latin: 'IBM Plex Sans')),
      );
      final footer = openOrFail(outcome.bytes).textOf('word/footer1.xml')!;

      expect('begin'.allMatches(footer).length, equals(1));
      expect('end"'.allMatches(footer).length, equals(1));
      expect(
        footer,
        contains('<w:instrText xml:space="preserve"> PAGE </w:instrText>'),
      );
      expect(
        footer,
        contains('<w:t>1</w:t>'),
        reason: 'ناتج الحقل المخزَّن يجب ألّا يُمَس',
      );
    });

    test('#4 — docProps لا تُمَس في مسار الستايل', () {
      // فصل الاهتمامات — `00` §2.
      final outcome = restyleOrFail(
        buildFixtureDocx(),
        StylePlan(colors: {hex('4C2FB8'): hex('00635D')}),
      );
      expect(
        outcome.report.changedParts.any((p) => p.startsWith('docProps')),
        isFalse,
      );
    });

    test('#5 — الخط أحادي العرض محميّ ولا يُبدَّل', () {
      final outcome = restyleOrFail(
        buildFixtureDocx(),
        const StylePlan(
          fonts: FontPlan(
            latin: 'IBM Plex Sans',
            arabic: 'IBM Plex Sans Arabic',
          ),
          preserveFonts: {'DejaVu Sans Mono'},
        ),
      );
      final body = openOrFail(outcome.bytes).textOf('word/document.xml')!;

      expect(body, contains('DejaVu Sans Mono'), reason: 'كتلة الكود انكسرت');
      expect(
        outcome.report.preservedFonts['DejaVu Sans Mono'],
        greaterThan(0),
        reason: 'الحماية يجب أن تُذكر في التقرير لا أن تجري بصمت',
      );
    });

    test('#6 — سمة الثيم تُحذف عند تبديل اللون الصريح', () {
      // بقاؤها قد يُعيد اللون القديم في بعض المستوردات — `02` §6.
      final outcome = restyleOrFail(
        buildFixtureDocx(),
        StylePlan(colors: {hex('4C2FB8'): hex('00635D')}),
      );
      final body = openOrFail(outcome.bytes).textOf('word/document.xml')!;

      expect(body, contains('w:val="00635D"'));
      expect(body, isNot(contains('w:themeColor')));
      expect(outcome.report.themeAttributesRemoved, greaterThan(0));
    });

    test('#8 — العربي يُبدَّل عبر cs لا ascii وحدها', () {
      final outcome = restyleOrFail(
        buildFixtureDocx(),
        const StylePlan(
          fonts: FontPlan(
            latin: 'IBM Plex Sans',
            arabic: 'IBM Plex Sans Arabic',
          ),
        ),
      );
      final body = openOrFail(outcome.bytes).textOf('word/document.xml')!;

      expect(body, contains('w:cs="IBM Plex Sans Arabic"'));
      expect(body, contains('w:ascii="IBM Plex Sans"'));
      expect(body, isNot(contains('Traditional Arabic')));
      expect(
        outcome.report.fontReplacements['Traditional Arabic'],
        greaterThan(0),
      );
    });

    test('#3 — الترويسة تُحوَّل مثل المتن', () {
      final outcome = restyleOrFail(
        buildFixtureDocx(),
        StylePlan(colors: {hex('4C2FB8'): hex('00635D')}),
      );
      expect(outcome.report.changedParts, contains('word/header1.xml'));
      expect(
        openOrFail(outcome.bytes).textOf('word/header1.xml'),
        contains('00635D'),
      );
    });
  });

  group('التقرير لا يصمت', () {
    test('لون في الخطة بلا مقابل في المستند يُبلَّغ', () {
      final result = restyle(
        buildFixtureDocx(),
        StylePlan(colors: {hex('ABCDEF'): hex('123456')}),
      );
      expect(result.isOk, isTrue, reason: 'تنبيه لا يمنع النجاح');
      expect(result.issues.single.code, equals(IssueCode.unmatchedMapping));
      expect(
        (result as Ok<RestyleOutcome>).value.report.unmatchedColors,
        contains(hex('ABCDEF')),
      );
    });

    test('"auto" لا تُبدَّل ولو رُسمت في الخريطة', () {
      final outcome = restyleOrFail(
        buildFixtureDocx(),
        StylePlan(colors: {hex('000000'): hex('00635D')}),
      );
      expect(
        openOrFail(outcome.bytes).textOf('word/document.xml'),
        contains('<w:color w:val="auto"/>'),
      );
    });
  });

  group('البوابة ترفض المخرج المكسور', () {
    test('تكشف <w:t> بلا نص وتمنع الكتابة', () {
      // محاكاة الخلل الذي أوقع مستورد Google Docs — `02` §3.
      final package = openOrFail(buildFixtureDocx());
      final broken = package
          .textOf('word/header1.xml')!
          .replaceAll(
            '<w:t>Header line</w:t>',
            '<w:t xml:space="preserve"></w:t>',
          );
      package.putText('word/header1.xml', broken);

      final issues = gateOf(package);
      expect(issues, hasLength(1));
      expect(issues.single.code, equals(IssueCode.emptyTextNode));
      expect(issues.single.part, equals('word/header1.xml'));
    });

    test('تكشف حقلًا غير متوازن', () {
      final package = openOrFail(buildFixtureDocx());
      final broken = package
          .textOf('word/footer1.xml')!
          .replaceAll('<w:r><w:fldChar w:fldCharType="end"/></w:r>', '');
      package.putText('word/footer1.xml', broken);

      final issues = gateOf(package);
      expect(issues.single.code, equals(IssueCode.unbalancedField));
    });

    test('مخرج سليم يمرّ بلا اعتراض', () {
      final package = openOrFail(buildFixtureDocx());
      expect(gateOf(package), isEmpty);
    });
  });

  group('مستند حقيقي', () {
    const realPath =
        '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';

    test('إعادة تنسيق كاملة تمرّ من البوابة وتُبقي ما لم يُطلَب', () {
      final file = File(realPath);
      if (!file.existsSync()) {
        markTestSkipped('لا يوجد مستند حقيقي في $realPath');
        return;
      }
      final source = Uint8List.fromList(file.readAsBytesSync());
      final outcome = restyleOrFail(
        source,
        StylePlan(
          colors: {
            hex('4C2FB8'): hex('00635D'),
            hex('33206F'): hex('00403C'),
            hex('667085'): hex('5B6B69'),
          },
          fonts: const FontPlan(
            latin: 'IBM Plex Sans',
            arabic: 'IBM Plex Sans Arabic',
          ),
          preserveFonts: const {'DejaVu Sans Mono', 'Courier', 'Symbol'},
        ),
      );

      expect(outcome.report.totalColorReplacements, greaterThan(150));
      expect(outcome.report.unmatchedColors, isEmpty);
      expect(
        outcome.report.preservedFonts.keys,
        containsAll(<String>['DejaVu Sans Mono']),
      );

      // المخرج يُفتح ويحوي نفس عدد الأجزاء، والبوابة راضية عنه.
      final after = openOrFail(outcome.bytes);
      expect(after.partNames, equals(openOrFail(source).partNames));
      expect(gateOf(after), isEmpty);

      // ما لم يكن في الخطة لم يُمَس.
      final report = formatOrFail(after).inspect(after);
      final colors = (report as Ok<InspectionReport>).value.colors.map(
        (c) => c.color.value,
      );
      expect(colors, contains('#00635D'));
      expect(colors, isNot(contains('#4C2FB8')));
      expect(colors, contains('#FDECEC'), reason: 'لون لم يُطلب تبديله');
    });
  });
}
