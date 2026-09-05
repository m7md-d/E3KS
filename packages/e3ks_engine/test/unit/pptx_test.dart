/// صيغة PowerPoint: التعرّف، والفحص، والتبديل، والمعاينة، والعزل.
library;

import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';
import '../fixtures/pptx_fixture.dart';

DocumentPackage openOrFail(Uint8List bytes) {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) fail('فتح: ${issues.join("، ")}');
  return (opened as Ok<DocumentPackage>).value;
}

DocumentFormat formatOrFail(DocumentPackage package) {
  final detected = formatFor(package);
  if (detected case Failed(:final issues)) fail('الصيغة: ${issues.join("، ")}');
  return (detected as Ok<DocumentFormat>).value;
}

InspectionReport inspectOrFail(DocumentPackage package) {
  final result = formatOrFail(package).inspect(package);
  if (result case Failed(:final issues)) fail('فحص: ${issues.join("، ")}');
  return (result as Ok<InspectionReport>).value;
}

ColorUsage colorOf(InspectionReport report, String hex) =>
    report.colors.firstWhere(
      (c) => c.color.value == hex,
      orElse: () => fail('اللون $hex غير موجود'),
    );

void main() {
  group('التعرّف على الصيغة', () {
    test('العرض يُعرَف من نوع محتواه لا من امتداده', () {
      expect(
        formatOrFail(openOrFail(buildFixturePptx())).id,
        equals(FormatId.pptx),
      );
      expect(
        formatOrFail(openOrFail(buildFixtureDocx())).id,
        equals(FormatId.docx),
      );
    });

    test('كل صيغة تدّعي حاويتها وحدها', () {
      // ادّعاء مزدوج يعني أن الترتيب في السجلّ يقرّر المصير — وهو هشّ.
      for (final entry in {
        FormatId.docx: buildFixtureDocx(),
        FormatId.pptx: buildFixturePptx(),
      }.entries) {
        final package = openOrFail(entry.value);
        final claiming = [
          for (final format in supportedFormats)
            if (format.claims(package)) format.id,
        ];
        expect(claiming, equals([entry.key]));
      }
    });
  });

  group('العزل بين الصيغ', () {
    test('لا جزء تملكه صيغتان', () {
      // الحارس الذي يجعل «صيغة لا تكسر أخرى» ضمانًا لا نيّة.
      const parts = [
        'word/document.xml',
        'word/styles.xml',
        'ppt/slides/slide1.xml',
        'ppt/theme/theme1.xml',
        '[Content_Types].xml',
        'docProps/core.xml',
        '_rels/.rels',
      ];
      for (final part in parts) {
        final owners = [
          for (final format in supportedFormats)
            if (format.owns(part)) format.id,
        ];
        expect(owners.length, lessThanOrEqualTo(1), reason: '$part: $owners');
      }
    });

    test('ما هو خارج مسار الستايل لا تملكه صيغة', () {
      // `docProps/` خارج النطاق عند الجميع (`00` §2)، والحاوية تكتب البقيّة.
      for (final format in supportedFormats) {
        expect(format.owns('docProps/core.xml'), isFalse);
        expect(format.owns('docProps/app.xml'), isFalse);
        expect(format.owns('[Content_Types].xml'), isFalse);
        expect(format.owns('_rels/.rels'), isFalse);
      }
    });

    test('تبديل عرض لا يمسّ جزءًا خارج ppt/', () {
      final package = openOrFail(buildFixturePptx());
      final result = formatOrFail(
        package,
      ).transform(package, const StylePlan());
      expect(result, isA<Ok<TransformReport>>());
      for (final part in package.touchedParts) {
        expect(part, startsWith('ppt/'));
      }
    });
  });

  group('الفحص', () {
    late InspectionReport report;
    setUpAll(() => report = inspectOrFail(openOrFail(buildFixturePptx())));

    test('يفصل ألوان الشرائح عن الموروثة من النماذج والثيم', () {
      final content = report.contentColors.map((c) => c.color.value);
      final inherited = report.inheritedColors.map((c) => c.color.value);

      expect(content, contains('#1B7F79'), reason: 'لون في شريحة');
      expect(content, contains('#EEF3F2'), reason: 'تعبئة شكل في شريحة');
      expect(inherited, contains('#4F81BD'), reason: 'لا يظهر إلا في الماستر');
      expect(inherited, contains('#9BBB59'), reason: 'لوحة الثيم');
      expect(content, isNot(contains('#4F81BD')));
    });

    test('الدور يُقرأ من موضع اللون في شجرة DrawingML', () {
      expect(
        colorOf(report, '#EEF3F2').dominantRole,
        equals(ColorRole.shapeFill),
      );
      expect(colorOf(report, '#667085').dominantRole, equals(ColorRole.text));
      expect(
        colorOf(report, '#9BBB59').dominantRole,
        equals(ColorRole.themePalette),
      );
    });

    test('العيّنة النصّية تصل مع اللون', () {
      expect(colorOf(report, '#1B7F79').samples, isNotEmpty);
      expect(colorOf(report, '#667085').samples.first, contains('theme'));
    });

    test('العربي يُقرأ من a:cs لا من a:latin', () {
      final arabic = report.fonts.firstWhere(
        (f) => f.name == 'Traditional Arabic',
        orElse: () => fail('الخط العربي لم يُلتقط'),
      );
      expect(arabic.bySlot[FontSlot.complexScript], greaterThan(0));
      expect(arabic.bySlot[FontSlot.ascii], isNull);
    });

    test('إحالة الثيم ليست اسم عائلة', () {
      // `+mj-lt` إحالة إلى خطّ الثيم؛ عرضها للمستخدم كخطّ هراء.
      expect(report.fonts.map((f) => f.name), isNot(contains('+mj-lt')));
    });

    test('a:schemeClr ليست لونًا صريحًا', () {
      // إحالة إلى الثيم، لا قيمة. عدّها لونًا يُخرج «accent1» في الجدول.
      expect(report.colors.every((c) => c.color.value.startsWith('#')), isTrue);
    });

    test('الخطوط أحادية العرض تُرشَّح للحماية هنا أيضًا', () {
      expect(
        report.monospacedCandidates.map((f) => f.name),
        contains('DejaVu Sans Mono'),
      );
    });
  });

  group('التبديل', () {
    test('يبدّل اللون والخطّ ويمرّ من البوابة', () {
      final plan = StylePlan(
        colors: {HexColor.tryParse('1B7F79')!: HexColor.tryParse('00403C')!},
        fonts: const FontPlan(latin: 'Inter', arabic: 'IBM Plex Sans Arabic'),
        preserveFonts: const {'DejaVu Sans Mono'},
      );
      final result = restyle(buildFixturePptx(), plan);
      if (result case Failed(:final issues)) {
        fail('تبديل: ${issues.join("، ")}');
      }
      final outcome = (result as Ok<RestyleOutcome>).value;

      expect(outcome.format, equals(FormatId.pptx));
      expect(outcome.report.totalColorReplacements, greaterThan(0));
      expect(outcome.report.fontReplacements['Cairo'], equals(1));
      expect(outcome.report.fontReplacements['Traditional Arabic'], equals(1));
      expect(outcome.report.preservedFonts['DejaVu Sans Mono'], equals(1));

      final after = inspectOrFail(openOrFail(outcome.bytes));
      expect(after.colors.map((c) => c.color.value), contains('#00403C'));
      expect(
        after.colors.map((c) => c.color.value),
        isNot(contains('#1B7F79')),
      );
      expect(after.fonts.map((f) => f.name), contains('DejaVu Sans Mono'));
    });

    test('خانة خطّ فارغة في الثيم لا تمنع الكتابة', () {
      // ثيم Office القياسي يكتب `<a:ea typeface=""/>` في كل عرض. كانت
      // البوابة ترفضه، فيسقط أول عرض حقيقي يمرّ على المحرّك بعيبٍ لم نصنعه.
      final result = restyle(
        buildFixturePptx(),
        const StylePlan(fonts: FontPlan(latin: 'Inter')),
      );
      expect(result, isA<Ok<RestyleOutcome>>());

      // وتبقى الخانة الفارغة كما جاءت: لا نملؤها ولا نحذفها.
      final after = openOrFail((result as Ok<RestyleOutcome>).value.bytes);
      final theme = after.textOf('ppt/theme/theme1.xml')!;
      expect(theme, contains('<a:ea typeface=""/>'));
    });

    test('اسم خطّ فارغ في الخطة لا يمسح الخانة', () {
      // الطريق الوحيد إلى `typeface=""` من عندنا خطةٌ باسم فارغ.
      const blank = FontPlan(latin: '   ', arabic: '');
      expect(blank.latin, isNull);
      expect(blank.arabic, isNull);
      expect(blank.isEmpty, isTrue);

      final result = restyle(buildFixturePptx(), const StylePlan(fonts: blank));
      final after = openOrFail((result as Ok<RestyleOutcome>).value.bytes);
      expect(
        after.textOf('ppt/slides/slide1.xml'),
        contains('typeface="Cairo"'),
      );
    });

    test('إحالة الثيم تبقى إحالة', () {
      // `+mj-lt` تعني «اتبع الثيم»؛ استبدالها باسم صريح يفصل الشكل عن ثيمه.
      final result = restyle(
        buildFixturePptx(),
        const StylePlan(fonts: FontPlan(latin: 'Inter')),
      );
      final outcome = (result as Ok<RestyleOutcome>).value;
      expect(outcome.report.fontReplacements.containsKey('+mj-lt'), isFalse);

      final after = openOrFail(outcome.bytes);
      final names = inspectOrFail(after).fonts.map((f) => f.name);
      expect(names, contains('Inter'), reason: 'Cairo بُدِّل فعلًا');
      expect(names, isNot(contains('+mj-lt')));
      // الإحالة باقية في الملفّ نصًّا، وإن لم تُعَدّ عائلة.
      expect(after.textOf('ppt/slides/slide1.xml'), contains('+mj-lt'));
    });

    test('خطّة فارغة لا تغيّر بايتًا واحدًا', () {
      // نفس ضمان Word (`00` §١/١): لا يُكتب ما لم يتغيّر.
      final result = restyle(buildFixturePptx(), const StylePlan());
      final outcome = (result as Ok<RestyleOutcome>).value;
      expect(outcome.report.changedParts, isEmpty);
    });
  });

  group('المعاينة', () {
    late DocumentPreview preview;
    setUpAll(() {
      final package = openOrFail(buildFixturePptx());
      preview = formatOrFail(package).preview(package);
    });

    test('الشريحة صفحة بمقاسها المعلَن', () {
      expect(preview.sections, hasLength(1));
      expect(preview.sections.first.kind, equals(PreviewSectionKind.slides));
      expect(preview.pageCount, equals(1));

      // 12192000×6858000 EMU = 960×540 نقطة.
      final geometry = preview.sections.first.pages.first.geometry;
      expect(geometry.widthPt, closeTo(960, 0.01));
      expect(geometry.heightPt, closeTo(540, 0.01));
      expect(geometry.marginLeftPt, equals(0), reason: 'الشريحة بلا هوامش');
    });

    test('الشكل يحمل إطاره المعلَن', () {
      final blocks = preview.sections.first.pages.first.blocks;
      final body = blocks.whereType<ShapeBlock>().firstWhere(
        (b) => b.fill?.value == '#EEF3F2',
      );
      // 838200 EMU = 66pt، و2286000 = 180pt.
      expect(body.frame!.leftPt, closeTo(66, 0.01));
      expect(body.frame!.topPt, closeTo(180, 0.01));
      expect(body.frame!.widthPt, closeTo(828, 0.01));
    });

    test('الشكل النائب يرث موضعه من التخطيط', () {
      // أكثر حالة شائعة في العروض الحقيقية: عنوان بلا a:xfrm.
      final blocks = preview.sections.first.pages.first.blocks;
      final title = blocks.whereType<ShapeBlock>().firstWhere(
        (b) => b.paragraphs.first.text.contains('هوية'),
      );
      expect(title.frame, isNotNull, reason: 'بلا وراثة يبقى العنوان بلا موضع');
      expect(title.frame!.topPt, closeTo(54, 0.01), reason: '685800 EMU');
    });

    test('خصائص المقطع تُقرأ كما صرّح بها', () {
      final blocks = preview.sections.first.pages.first.blocks;
      final title = blocks.whereType<ShapeBlock>().firstWhere(
        (b) => b.paragraphs.first.text.contains('هوية'),
      );
      final run = title.paragraphs.first.runs.first;
      expect(run.sizePt, equals(44), reason: 'sz=4400 بمئات النقاط');
      expect(run.bold, isTrue);
      expect(run.color?.value, equals('#1B7F79'));
      expect(run.arabicFont, equals('Traditional Arabic'));
      expect(title.paragraphs.first.align, equals(PreviewAlign.center));
    });

    test('الخطة تُطبَّق على المعاينة وتحفظ الإطارات', () {
      final restyled = restylePreview(
        preview,
        StylePlan(
          colors: {HexColor.tryParse('EEF3F2')!: HexColor.tryParse('101820')!},
        ),
      );
      final body = restyled.sections.first.pages.first.blocks
          .whereType<ShapeBlock>()
          .firstWhere((b) => b.fill != null);
      expect(body.fill?.value, equals('#101820'));
      expect(body.frame!.leftPt, closeTo(66, 0.01));
    });
  });
}
