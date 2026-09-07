/// ما لم يتغيّر يخرج بذاته — وعليه تقوم سلاسة الواجهة.
///
/// **الخلل الذي وُلد منه هذا الاختبار:** كل تبديل لون كان يبني نموذج معاينة
/// جديدًا كاملًا، فتصير كل صفحةٍ كائنًا جديدًا، فتُعاد ودجتُها، فيُعاد تخطيط
/// **كل صفحة مرئية** ولو لم يكن اللون فيها. والإطار كان ٢٤–٣٠ms والميزانية
/// ١٦. وحين تُعاد الصفحة بذاتها يتخطّاها Flutter كاملةً.
library;

import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';

/// `!` مضمون: القيم أدناه بصيغة `#RRGGBB` صحيحة.
HexColor hex(String value) => HexColor.tryParse(value)!;

DocumentPreview previewOf(List<int> bytes) {
  final package =
      (DocumentPackage.open(Uint8List.fromList(bytes)) as Ok<DocumentPackage>)
          .value;
  return (formatFor(package) as Ok<DocumentFormat>).value.preview(package);
}

void main() {
  late DocumentPreview preview;

  setUpAll(() => preview = previewOf(buildFixtureDocx()));

  test('خطة فارغة تُرجع المعاينة نفسها', () {
    expect(
      identical(restylePreview(preview, const StylePlan()), preview),
      isTrue,
    );
  });

  test('لون لا وجود له لا يبني شيئًا جديدًا', () {
    final plan = StylePlan(colors: {hex('#ABCDEF'): hex('#123456')});
    expect(identical(restylePreview(preview, plan), preview), isTrue);
  });

  test('تبديل لون يُعيد بناء ما فيه وحده', () {
    // `#4C2FB8` لون نصّ في أول فقرة من المتن.
    final plan = StylePlan(colors: {hex('#4C2FB8'): hex('#0F3D3E')});
    final after = restylePreview(preview, plan);
    expect(identical(after, preview), isFalse, reason: 'لم يتغيّر شيء أصلًا');

    final before = [for (final s in preview.sections) ...s.pages];
    final now = [for (final s in after.sections) ...s.pages];
    expect(now, hasLength(before.length));

    final rebuilt = [
      for (var i = 0; i < now.length; i++)
        if (!identical(now[i], before[i])) i,
    ];
    expect(rebuilt, isNotEmpty, reason: 'لم تُبنَ أي صفحة فيها اللون');
    expect(
      rebuilt.length,
      lessThan(now.length),
      reason: 'أُعيد بناء كل الصفحات: الهُويّة لا تُحفَظ',
    );
  });

  test('حماية الخطّ تُبقي المقطع بذاته', () {
    final plan = StylePlan(
      fonts: const FontPlan(latin: 'Inter'),
      preserveFonts: const {'DejaVu Sans Mono'},
    );
    final after = restylePreview(preview, plan);
    // المستند فيه خطّ محميّ وخطوط غيره، فبعضه يتغيّر وبعضه لا.
    expect(identical(after, preview), isFalse);
  });
}
