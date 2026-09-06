/// الشريحة لوحة لا تدفّق: الشكل يُرسَم حيث أعلن موضعه.
///
/// يختبر مسار الرسم مباشرةً بنموذج معاينة مصنوع — فلا يحتاج ملفّ عرض،
/// ويقيس ما يراه المستخدم فعلًا لا ما يقوله المحرّك.
library;

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/openable_files.dart';
import 'package:e3ks_desktop/features/preview/document_paper.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 16:9 بالنقاط، بلا هوامش — كما تقرأها `PptxPreviewExtractor`.
const _slide = PageGeometry(
  widthPt: 960,
  heightPt: 540,
  marginTopPt: 0,
  marginRightPt: 0,
  marginBottomPt: 0,
  marginLeftPt: 0,
);

PreviewParagraph line(String text) =>
    PreviewParagraph(runs: [PreviewRun(text: text, sizePt: 18)]);

void main() {
  testWidgets('الشكل يُرسَم في موضعه ومقاسه المعلَنين', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const page = PreviewPage(
      number: 1,
      geometry: _slide,
      blocks: [
        ShapeBlock(
          paragraphs: [
            PreviewParagraph(runs: [PreviewRun(text: 'عنوان', sizePt: 44)]),
          ],
          frame: BlockFrame(leftPt: 66, topPt: 54, widthPt: 828, heightPt: 90),
        ),
      ],
    );

    const zoom = 0.5;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DocumentPaper(
              page: page,
              zoom: zoom,
              startNumber: 1,
              showNumbers: false,
            ),
          ),
        ),
      ),
    );

    const scale = zoom * Metrics.pxPerPoint;
    final paper = tester.getRect(find.byType(DocumentPaper));
    expect(paper.width, closeTo(960 * scale, 0.5));
    expect(paper.height, closeTo(540 * scale, 0.5));

    // الموضع نسبةً إلى الورقة، لا إلى الشاشة.
    final shape = tester.getRect(find.text('عنوان'));
    expect(shape.left - paper.left, greaterThanOrEqualTo(66 * scale));
    expect(shape.top - paper.top, greaterThanOrEqualTo(54 * scale));
    expect(shape.left - paper.left, lessThan((66 + 20) * scale));
  });

  testWidgets('التدفّق والوضع المعلَن يجتمعان على صفحة واحدة', (tester) async {
    // صفحة Word لا إطارات فيها، وصفحة الشريحة كلّها إطارات. الراسم واحد،
    // فيجب أن يحتمل الحالتين بلا أن تزيح إحداهما الأخرى.
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final page = PreviewPage(
      number: 1,
      geometry: _slide,
      blocks: [
        ParagraphBlock(line('تدفّق')),
        ShapeBlock(
          paragraphs: [line('موضوع')],
          frame: const BlockFrame(
            leftPt: 400,
            topPt: 300,
            widthPt: 300,
            heightPt: 60,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DocumentPaper(
              page: page,
              zoom: 0.5,
              startNumber: 1,
              showNumbers: false,
            ),
          ),
        ),
      ),
    );

    const scale = 0.5 * Metrics.pxPerPoint;
    final paper = tester.getRect(find.byType(DocumentPaper));
    final flowing = tester.getRect(find.text('تدفّق'));
    final placed = tester.getRect(find.text('موضوع'));

    expect(flowing.top - paper.top, lessThan(40 * scale), reason: 'من الأعلى');
    expect(placed.top - paper.top, greaterThanOrEqualTo(300 * scale));
    expect(tester.takeException(), isNull);
  });

  group('اسم المخرج', () {
    test('يحفظ امتداد المصدر', () {
      // تثبيته على `.docx` كان يُخرج عرضًا باسم مستند فيرفضه النظام.
      expect(suggestedOutputName('عرض.pptx'), equals('عرض_E3KS.pptx'));
      expect(suggestedOutputName('manual.docx'), equals('manual_E3KS.docx'));
      expect(suggestedOutputName('deck.ppsx'), equals('deck_E3KS.ppsx'));
    });

    test('يحتمل اسمًا بلا امتداد أو بنقاط كثيرة', () {
      expect(suggestedOutputName('report'), equals('report_E3KS'));
      expect(
        suggestedOutputName('v1.2.final.pptx'),
        equals('v1.2.final_E3KS.pptx'),
      );
    });
  });
}
