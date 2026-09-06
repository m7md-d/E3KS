/// العلامات على النصّ: قلم التمييز وتظليل الخلفية — فحصًا ورفعًا ومعاينة.
///
/// **الحاجة التي تخدمها:** ملفّ يصل المستخدم وفيه أثر تحديدٍ لا يرفعه قلم
/// Word، لأنه ليس تمييزًا بل `w:shd` داخل `w:rPr`. الأداة ترفع الاثنين،
/// انتقاءً أو دفعةً واحدة.
library;

import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';
import '../fixtures/pptx_fixture.dart';

const TextMark _yellow = TextMark(MarkKind.highlight, 'yellow');
const TextMark _green = TextMark(MarkKind.highlight, 'green');
const TextMark _grayShade = TextMark(MarkKind.textShading, '#D9D9D9');

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

DocumentFormat formatOrFail(DocumentPackage package) {
  final detected = formatFor(package);
  if (detected case Failed(:final issues)) fail('الصيغة: ${issues.join("، ")}');
  return (detected as Ok<DocumentFormat>).value;
}

InspectionReport inspectOrFail(Uint8List bytes) {
  final package = openOrFail(bytes);
  final result = formatOrFail(package).inspect(package);
  if (result case Failed(:final issues)) fail('فحص: ${issues.join("، ")}');
  return (result as Ok<InspectionReport>).value;
}

List<EngineIssue> gateOf(DocumentPackage package) => [
  ...checkPackage(package),
  ...formatOrFail(package).validate(package),
];

MarkUsage? usageOf(InspectionReport report, TextMark mark) {
  for (final usage in report.marks) {
    if (usage.mark == mark) return usage;
  }
  return null;
}

/// كل مقاطع المعاينة في تسلسل واحد.
Iterable<PreviewRun> runsOf(DocumentPreview preview) sync* {
  for (final section in preview.sections) {
    for (final block in section.blocks) {
      switch (block) {
        case ParagraphBlock(:final paragraph):
          yield* paragraph.runs;
        case ShapeBlock(:final paragraphs):
          for (final p in paragraphs) {
            yield* p.runs;
          }
        case TableBlock(:final rows):
          for (final row in rows) {
            for (final cell in row.cells) {
              for (final p in cell.paragraphs) {
                yield* p.runs;
              }
            }
          }
      }
    }
  }
}

void main() {
  group('الفحص', () {
    test('القلم والتظليل يُحصيان بعيّناتهما، و«none» ليست علامة', () {
      final report = inspectOrFail(buildMarkedDocx());

      expect(usageOf(report, _yellow)?.count, equals(2));
      expect(usageOf(report, _green)?.count, equals(1));
      expect(usageOf(report, _grayShade)?.count, equals(2));

      // `w:highlight w:val="none"` قولٌ صريح بلا تمييز، لا علامة تُرفع.
      expect(
        report.marks.any((m) => m.mark.key == 'none'),
        isFalse,
        reason: '«بلا تمييز» حُسبت علامة',
      );

      // بلا عيّنة يصير الجدول أرقامًا صمّاء لا يُبنى عليها قرار (`00` §5).
      expect(usageOf(report, _yellow)!.samples, isNotEmpty);
      expect(usageOf(report, _grayShade)!.samples, isNotEmpty);
    });

    test('تظليل الفقرة لون يُبدَّل، لا علامة تُرفع', () {
      // خلفية الفقرة قرار تصميم؛ خلفية النصّ أثر لصقٍ في الغالب. خلطهما
      // يجعل «امسح التظليل» يمسح تصميم المستند.
      final report = inspectOrFail(buildMarkedDocx());
      final paragraphFill = HexColor.tryParse('#EEF3F2')!;

      expect(
        report.marks.any((m) => m.mark.key == paragraphFill.value),
        isFalse,
      );
      expect(
        report.colors.any((c) => c.color == paragraphFill),
        isTrue,
        reason: 'خلفية الفقرة سقطت من جدول الألوان',
      );
    });

    test('لون التظليل يظهر في الجدولين: يُبدَّل هنا ويُرفع هناك', () {
      final report = inspectOrFail(buildMarkedDocx());
      final gray = HexColor.tryParse('#D9D9D9')!;

      expect(report.colors.any((c) => c.color == gray), isTrue);
      expect(usageOf(report, _grayShade), isNotNull);
    });
  });

  group('الرفع', () {
    test('خطة فارغة لا ترفع علامة', () {
      final outcome = restyleOrFail(buildMarkedDocx(), const StylePlan());
      expect(outcome.report.markRemovals, isEmpty);
      expect(outcome.report.changedNothing, isTrue);
    });

    test('رفع علامة بعينها لا يمسّ أختها', () {
      final outcome = restyleOrFail(
        buildMarkedDocx(),
        StylePlan(removeMarks: {_yellow}),
      );

      expect(outcome.report.markRemovals[_yellow], equals(2));
      expect(outcome.report.totalMarkRemovals, equals(2));

      final after = inspectOrFail(outcome.bytes);
      expect(usageOf(after, _yellow), isNull);
      expect(usageOf(after, _green)?.count, equals(1));
      expect(usageOf(after, _grayShade)?.count, equals(2));
    });

    test('الراية ترفع القلم كلّه وتترك التظليل', () {
      final outcome = restyleOrFail(
        buildMarkedDocx(),
        const StylePlan(removeHighlight: true),
      );

      final after = inspectOrFail(outcome.bytes);
      expect(
        after.marks.any((m) => m.mark.kind == MarkKind.highlight),
        isFalse,
      );
      expect(usageOf(after, _grayShade)?.count, equals(2));
    });

    test('الراية الأخرى ترفع التظليل وتترك القلم', () {
      final outcome = restyleOrFail(
        buildMarkedDocx(),
        const StylePlan(removeTextShading: true),
      );

      final after = inspectOrFail(outcome.bytes);
      expect(usageOf(after, _grayShade), isNull);
      expect(usageOf(after, _yellow)?.count, equals(2));
    });

    test('التظليل يُحذف عنصره كاملًا، وتظليل الفقرة يبقى', () {
      // **`w:shd` يحمل `val` و`color` و`fill`**، وتفريغ الفيل وحده يترك
      // نمط تظليل يراه القارئ.
      final outcome = restyleOrFail(
        buildMarkedDocx(),
        const StylePlan(removeTextShading: true),
      );
      final xml = openOrFail(outcome.bytes).textOf('word/document.xml')!;

      expect(xml.contains('D9D9D9'), isFalse, reason: 'بقي أثر التظليل');
      expect(xml.contains('EEF3F2'), isTrue, reason: 'ذهبت خلفية الفقرة معه');
    });

    test('المخرَج يمرّ من البوابة، وما لم يُمسّ يبقى مطابقًا بايتًا ببايت', () {
      // القاعدة `00` §١/١ و§١/٢ على مسار الرفع كما على مسار التبديل.
      final source = buildMarkedDocx();
      final outcome = restyleOrFail(
        source,
        const StylePlan(removeHighlight: true, removeTextShading: true),
      );

      final after = openOrFail(outcome.bytes);
      expect(gateOf(after), isEmpty);
      expect(outcome.report.changedParts, equals(['word/document.xml']));

      final before = openOrFail(source);
      for (final name in before.partNames) {
        if (name == 'word/document.xml') continue;
        expect(
          after.bytesOf(name),
          equals(before.bytesOf(name)),
          reason: 'الجزء $name تغيّر بلا سبب',
        );
      }
    });

    test('رفع علامة على مقطع يحمل الاثنتين يترك الأخرى', () {
      // المقطع الأخير في المرجع يحمل قلمًا وتظليلًا معًا.
      final outcome = restyleOrFail(
        buildMarkedDocx(),
        StylePlan(removeMarks: {_grayShade}),
      );
      final xml = openOrFail(outcome.bytes).textOf('word/document.xml')!;

      expect(xml.contains('w:highlight w:val="yellow"'), isTrue);
      expect(xml.contains('D9D9D9'), isFalse);
    });
  });

  group('المعاينة', () {
    test('القلم يُقرأ، ورفعُه يُسقطه من المعاينة', () {
      final package = openOrFail(buildMarkedDocx());
      final preview = formatOrFail(package).preview(package);

      expect(
        runsOf(preview).where((r) => r.highlight == _yellow).length,
        equals(2),
      );
      expect(runsOf(preview).where((r) => r.shading != null).length, equals(2));

      final after = restylePreview(
        preview,
        const StylePlan(removeHighlight: true, removeTextShading: true),
      );
      expect(runsOf(after).every((r) => r.highlight == null), isTrue);
      expect(runsOf(after).every((r) => r.shading == null), isTrue);
    });

    test('المعاينة ترفع ما يرفعه المحوّل، لا أكثر', () {
      // اختلافهما يجعل المعاينة تَعِد بما لا يخرج.
      final package = openOrFail(buildMarkedDocx());
      final preview = formatOrFail(package).preview(package);
      final after = restylePreview(preview, StylePlan(removeMarks: {_yellow}));

      expect(after.sections, isNotEmpty);
      expect(runsOf(after).any((r) => r.highlight == _green), isTrue);
      expect(runsOf(after).any((r) => r.highlight == _yellow), isFalse);
      expect(runsOf(after).any((r) => r.shading != null), isTrue);
    });
  });

  group('PowerPoint', () {
    final pen = TextMark.coloredPen(HexColor.tryParse('#FFFF00')!);

    test('قلم `a:highlight` يُفحَص بلونه', () {
      final report = inspectOrFail(buildMarkedPptx());
      expect(usageOf(report, pen)?.count, equals(1));
    });

    test('رفعه يحذف العنصر ويمرّ من البوابة', () {
      final outcome = restyleOrFail(
        buildMarkedPptx(),
        StylePlan(removeMarks: {pen}),
      );
      final after = openOrFail(outcome.bytes);

      expect(outcome.report.markRemovals[pen], equals(1));
      expect(gateOf(after), isEmpty);
      expect(
        after.textOf('ppt/slides/slide1.xml')!.contains('a:highlight'),
        isFalse,
      );
      expect(usageOf(inspectOrFail(outcome.bytes), pen), isNull);
    });

    test('لون علامةٍ مرفوعة لا يُحصى تبديلًا', () {
      // العنصر انفصل عن الشجرة قبل أن نبلغ لونه؛ عدّه تبديلًا تقريرٌ كاذب.
      final outcome = restyleOrFail(
        buildMarkedPptx(),
        StylePlan(
          colors: {
            HexColor.tryParse('#FFFF00')!: HexColor.tryParse('#00FF00')!,
          },
          removeMarks: {pen},
        ),
      );

      expect(outcome.report.colorReplacements, isEmpty);
      expect(outcome.report.markRemovals[pen], equals(1));
      expect(
        openOrFail(
          outcome.bytes,
        ).textOf('ppt/slides/slide1.xml')!.contains('00FF00'),
        isFalse,
      );
    });
  });

  group('قراءة العلامة من نصّها', () {
    test('الصيغة نفسها التي يكتبها التقرير تُقرأ في الخطة', () {
      expect(TextMark.tryParse('$_yellow'), equals(_yellow));
      expect(TextMark.tryParse('$_grayShade'), equals(_grayShade));
    });

    test('مفتاح اللون يُطبَّع فلا يصير لونٌ واحد علامتين', () {
      expect(TextMark.tryParse('textShading:d9d9d9'), equals(_grayShade));
      expect(TextMark.tryParse('textShading:#d9d9d9'), equals(_grayShade));
    });

    test('ما لا يُعرَف يُرفض ولا يُخمَّن', () {
      expect(TextMark.tryParse('textShading:أزرق'), isNull);
      expect(TextMark.tryParse('weird:yellow'), isNull);
      expect(TextMark.tryParse('highlight'), isNull);
      expect(TextMark.tryParse('highlight:'), isNull);
      expect(TextMark.tryParse(null), isNull);
    });
  });
}
