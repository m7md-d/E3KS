/// اختبارات الفحص، ومنها اختبارات انحدار إلزامية — `04` §3.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';

/// يمرّ عبر الواجهة العامة لا عبر أصناف الصيغة مباشرةً: هكذا يستدعيها
/// التطبيق، وهكذا يُختبَر التعرّف على الصيغة مع كل اختبار.
DocumentFormat formatOrFail(DocumentPackage package) {
  final detected = formatFor(package);
  if (detected case Failed(:final issues)) fail('الصيغة: ${issues.join("، ")}');
  return (detected as Ok<DocumentFormat>).value;
}

InspectionReport inspectOrFail(Uint8List bytes) {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) fail('فتح: ${issues.join("، ")}');
  final package = (opened as Ok<DocumentPackage>).value;
  final result = formatOrFail(package).inspect(package);
  if (result case Failed(:final issues)) fail('فحص: ${issues.join("، ")}');
  return (result as Ok<InspectionReport>).value;
}

ColorUsage colorOf(InspectionReport report, String hex) =>
    report.colors.firstWhere(
      (c) => c.color.value == hex,
      orElse: () => fail('اللون $hex غير موجود في التقرير'),
    );

FontUsage fontOf(InspectionReport report, String name) =>
    report.fonts.firstWhere(
      (f) => f.name == name,
      orElse: () => fail('الخط $name غير موجود في التقرير'),
    );

void main() {
  late InspectionReport report;
  setUpAll(() => report = inspectOrFail(buildFixtureDocx()));

  group('انحدار إلزامي', () {
    test('#3 — الترويسة والتذييل يُفحَصان فعلًا', () {
      // أجزاء منفصلة تُنسى كثيرًا، وهي أول ما ينكشف عند العميل — `02` §8.
      expect(report.scannedParts, contains('word/header1.xml'));
      expect(report.scannedParts, contains('word/footer1.xml'));

      final purple = colorOf(report, '#4C2FB8');
      expect(
        purple.byPart.keys,
        contains('word/header1.xml'),
        reason: 'لون الترويسة لم يُلتقط',
      );
    });

    test('#8 — الخط العربي يُقرأ من فتحة cs لا من ascii وحدها', () {
      // إغفال `cs` يعني أن العربي لن يتغيّر أبدًا — `02` §7.
      final arabic = fontOf(report, 'Traditional Arabic');
      expect(arabic.bySlot[FontSlot.complexScript], greaterThan(0));
      expect(
        arabic.bySlot[FontSlot.ascii],
        isNull,
        reason: 'هذا الخط مُعرَّف في cs فقط',
      );
    });

    test('#5 — الخطوط أحادية العرض تُرشَّح للحماية', () {
      final names = report.monospacedCandidates.map((f) => f.name);
      expect(names, contains('DejaVu Sans Mono'));
      expect(names, isNot(contains('Calibri')));
    });

    test('#6 — ارتباط الثيم يُكشف كي يُحذف عند التبديل', () {
      expect(
        colorOf(report, '#4C2FB8').themeLinked,
        isTrue,
        reason: 'مقترن بـ themeColor="accent1"',
      );
      expect(colorOf(report, '#667085').themeLinked, isFalse);
    });
  });

  group('تصنيف الألوان', () {
    test('يفصل ألوان المحتوى عن الموروثة من الأنماط', () {
      final content = report.contentColors.map((c) => c.color.value);
      final inherited = report.inheritedColors.map((c) => c.color.value);

      expect(content, contains('#4C2FB8'), reason: 'لون في المتن والترويسة');
      expect(content, contains('#EEF3F2'), reason: 'خلفية فقرة في المتن');
      expect(
        inherited,
        contains('#4F81BD'),
        reason: 'لا يظهر إلا في styles.xml — ضجيج ثيم Office',
      );
      expect(content, isNot(contains('#4F81BD')));
    });

    test('"auto" تفويض لا لون — لا يُحصى', () {
      expect(HexColor.tryParse('auto'), isNull);
      expect(report.colors.map((c) => c.color.value), isNot(contains('#AUTO')));
      // النص الذي حمل auto موجود، لكن بلا لون مسجَّل عليه.
      expect(report.colors.every((c) => c.color.value.startsWith('#')), isTrue);
    });

    test('الأدوار تُحدَّد من العنصر الأب', () {
      expect(
        colorOf(report, '#EEF3F2').dominantRole,
        equals(ColorRole.paragraphFill),
      );
      expect(colorOf(report, '#667085').dominantRole, equals(ColorRole.text));
      expect(colorOf(report, '#4F81BD').dominantRole, equals(ColorRole.border));
    });

    test('العيّنات النصّية تصل مع اللون', () {
      // بلا عيّنة يصير جدول الأثر أرقامًا صمّاء.
      expect(colorOf(report, '#4C2FB8').samples, isNotEmpty);
      expect(colorOf(report, '#667085').samples.first, contains('world'));
    });

    test('الترتيب تنازلي بعدد الاستعمال', () {
      final counts = report.colors.map((c) => c.count).toList();
      expect(
        counts,
        orderedEquals(List<int>.of(counts)..sort((a, b) => b - a)),
      );
    });
  });

  group('تطبيع اللون', () {
    test('يقبل الصيغ الواردة في OOXML ويرفض ما ليس لونًا', () {
      expect(HexColor.tryParse('4c2fb8')?.value, equals('#4C2FB8'));
      expect(HexColor.tryParse('#4C2FB8')?.value, equals('#4C2FB8'));
      expect(
        HexColor.tryParse('FF4C2FB8')?.value,
        equals('#4C2FB8'),
        reason: 'AARRGGBB — تُسقَط قناة الشفافية',
      );
      expect(HexColor.tryParse('4C2FB'), isNull);
      expect(HexColor.tryParse('ZZZZZZ'), isNull);
      expect(HexColor.tryParse(''), isNull);
      expect(HexColor.tryParse(null), isNull);
    });

    test('التباين يُحسب حسب WCAG', () {
      final white = HexColor.tryParse('FFFFFF')!;
      final black = HexColor.tryParse('000000')!;
      expect(white.contrastWith(black), closeTo(21.0, 0.01));
      expect(
        white.contrastWith(HexColor.tryParse('00635D')!),
        closeTo(7.14, 0.05),
      );
    });

    test('التصنيف العربي معقول', () {
      expect(HexColor.tryParse('A32834')!.family, equals(ColorFamily.red));
      expect(HexColor.tryParse('00403C')!.family, equals(ColorFamily.teal));
      expect(HexColor.tryParse('FFFFFF')!.family, equals(ColorFamily.neutral));
      expect(HexColor.tryParse('00403C')!.tone, equals(ColorTone.veryDark));
    });
  });

  group('مستند حقيقي', () {
    const realPath =
        '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';

    test('الفصل بين الهوية والضجيج يصمد على مستند فعلي', () {
      final file = File(realPath);
      if (!file.existsSync()) {
        markTestSkipped('لا يوجد مستند حقيقي في $realPath');
        return;
      }
      final real = inspectOrFail(file.readAsBytesSync());

      // ألوان الهوية قليلة ومقصودة؛ الموروثة كثيرة — هذا جوهر `02` §6.
      expect(
        real.contentColors.length,
        lessThan(30),
        reason: 'ألوان الهوية يجب أن تبقى قائمة يقرؤها إنسان',
      );
      expect(
        real.inheritedColors.length,
        greaterThan(real.contentColors.length),
        reason: 'ضجيج ثيم Office يفوق ألوان التصميم عادةً',
      );

      // ألوان Office 2007 الافتراضية يجب ألّا تُعرَض كهوية.
      final content = real.contentColors.map((c) => c.color.value);
      expect(content, isNot(contains('#4F81BD')));
      expect(content, isNot(contains('#9BBB59')));
    });
  });
}
