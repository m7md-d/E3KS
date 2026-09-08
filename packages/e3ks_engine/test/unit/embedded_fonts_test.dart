/// الخطّ المضمَّن في المستند: أصدق ما تُرسَم به معاينته.
///
/// **الحارس على النتيجة لا على النيّة**: التشويش خوارزمية بترتيب بايتات
/// موضع خلاف بين التطبيقات، فالمقياس أن تخرج بايتات الخطّ كما دخلت،
/// وأن يُترك ما لا يُفكّ بدل تسجيله خطًّا فاسدًا.
library;

import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';
import '../fixtures/pptx_fixture.dart';

InspectionReport reportOf(Uint8List bytes) {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) fail('فتح: ${issues.join("، ")}');
  final package = (opened as Ok<DocumentPackage>).value;
  final detected = formatFor(package);
  if (detected case Failed(:final issues)) fail('الصيغة: ${issues.join("، ")}');
  final result = (detected as Ok<DocumentFormat>).value.inspect(package);
  if (result case Failed(:final issues)) fail('فحص: ${issues.join("، ")}');
  return (result as Ok<InspectionReport>).value;
}

void main() {
  test('الخطّ المضمَّن يخرج كما دخل', () {
    final report = reportOf(buildEmbeddedFontDocx());

    expect(report.embeddedFonts, hasLength(1));
    final font = report.embeddedFonts.single;
    expect(font.family, equals(embeddedFontFamily));
    expect(font.face, equals(FontFace.regular));
    expect(font.subsetted, isTrue, reason: 'الجزئيّة تُقال ولا تُخفى');
    expect(font.bytes, equals(fakeEmbeddedTtf()));
  });

  test('ما لا يُفكّ يُترك ولا يُسجَّل', () {
    // مفتاحٌ غير مفتاحه: الفكّ يخرج بايتات بلا توقيع خطّ.
    final report = reportOf(
      buildEmbeddedFontDocx(fontKey: '{11111111-2222-3333-4444-555555555555}'),
    );

    expect(report.embeddedFonts, isEmpty, reason: 'سجّل خطًّا فاسدًا');
  });

  test('مستندٌ بلا تضمين لا يدّعي شيئًا', () {
    expect(reportOf(buildFixtureDocx()).embeddedFonts, isEmpty);
    expect(reportOf(buildFixturePptx()).embeddedFonts, isEmpty);
  });

  test('عرض PowerPoint يضمّن بلا تشويش، فيُقرأ كما هو', () {
    final report = reportOf(buildEmbeddedFontPptx());

    expect(report.embeddedFonts, hasLength(1));
    expect(report.embeddedFonts.single.family, equals(embeddedPptxFamily));
    expect(report.embeddedFonts.single.face, equals(FontFace.regular));
  });
}
