/// مقاس الصفحة يُقرأ من المستند، لا يُفترض.
///
/// الورقة المرسومة بمقاس محتواها تختلف من صفحة إلى أخرى، فيفقد المستخدم
/// إحساس الصفحة. وهذه شكوى واقعية أبلغ عنها المالك.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';

DocumentPreview extractOrFail(Uint8List bytes) {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) fail('فتح: ${issues.join("، ")}');
  return const PreviewExtractor().extract(
    (opened as Ok<DocumentPackage>).value,
  );
}

PreviewSection bodyOf(DocumentPreview preview) =>
    preview.sections.firstWhere((s) => s.kind == PreviewSectionKind.body);

void main() {
  test('بلا sectPr مصرَّح يُفترَض A4 بهوامش بوصة', () {
    // الفخّ: صفر أو غياب لا يعني «بلا صفحة»، بل يعني افتراض Word.
    final body = bodyOf(extractOrFail(buildFixtureDocx()));
    expect(body.pages.first.geometry, equals(PageGeometry.a4));
    expect(PageGeometry.a4.isLandscape, isFalse);
  });

  group('مستند بقسمين', () {
    late DocumentPreview preview;
    setUpAll(() => preview = extractOrFail(buildSectionedDocx()));

    test('كل قسم يحمل مقاسه هو', () {
      final pages = bodyOf(preview).pages;
      expect(pages, hasLength(2), reason: 'فاصل الصفحة يفصل القسمين');

      // ‏Letter = 12240×15840 twip.
      expect(pages[0].geometry.widthPt, closeTo(612, 0.01));
      expect(pages[0].geometry.heightPt, closeTo(792, 0.01));
      expect(pages[0].geometry.isLandscape, isFalse);

      // ‏A4 أفقي = 16838×11906 twip.
      expect(pages[1].geometry.widthPt, closeTo(841.9, 0.01));
      expect(pages[1].geometry.heightPt, closeTo(595.3, 0.01));
      expect(pages[1].geometry.isLandscape, isTrue);
    });

    test('sectPr يصف القسم الذي ينتهي عنده لا الذي يليه', () {
      // أكثر خطأ متوقَّع هنا: قراءته كأنه يبدأ قسمًا.
      final first = bodyOf(preview).pages.first.geometry;
      expect(first.marginLeftPt, closeTo(90, 0.01), reason: 'left=1800 twip');
      expect(first.marginRightPt, closeTo(54, 0.01), reason: 'right=1080 twip');
    });

    test('التذييل يأخذ مقاس المتن لا A4 افتراضًا', () {
      // أجزاء مستقلّة بلا sectPr خاصّ — وترتيبها في الحاوية قد يسبق المتن.
      final footer = preview.sections.firstWhere(
        (s) => s.kind == PreviewSectionKind.footer,
      );
      expect(footer.pages.first.geometry.widthPt, closeTo(612, 0.01));
    });

    test('الخطة لا تُضيّع المقاس', () {
      final restyled = restylePreview(preview, const StylePlan());
      expect(bodyOf(restyled).pages[1].geometry.isLandscape, isTrue);
    });
  });

  test('مستند حقيقي: Letter لا A4', () {
    const realPath =
        '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';
    final file = File(realPath);
    if (!file.existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي في $realPath');
      return;
    }

    final body = bodyOf(
      extractOrFail(Uint8List.fromList(file.readAsBytesSync())),
    );
    // لو افترضنا A4 لظهر المستند كلّه بمقاس خاطئ بصمت.
    expect(body.pages.first.geometry.widthPt, closeTo(612, 0.01));
    expect(body.pages.first.geometry.heightPt, closeTo(792, 0.01));
    for (final page in body.pages) {
      expect(
        page.geometry,
        equals(body.pages.first.geometry),
        reason: 'المستند قسم واحد، فلا يجوز أن تختلف صفحاته',
      );
    }
  });
}
