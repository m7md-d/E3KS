/// ترقيم الصفحات يأتي من Word لا من تخمين.
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

void main() {
  test('مستند بلا فواصل = صفحة واحدة لكل قسم', () {
    final preview = extractOrFail(buildFixtureDocx());
    for (final section in preview.sections) {
      expect(section.pages, hasLength(1), reason: section.partName);
      expect(section.pages.first.number, equals(1));
    }
  });

  test('الترقيم مأخوذ من فواصل Word المخزَّنة', () {
    const realPath =
        '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';
    final file = File(realPath);
    if (!file.existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي في $realPath');
      return;
    }

    final preview = extractOrFail(Uint8List.fromList(file.readAsBytesSync()));
    final body = preview.sections.firstWhere(
      (s) => s.kind == PreviewSectionKind.body,
    );

    // المستند فيه ٣٤ lastRenderedPageBreak و٢ فاصلًا صريحًا.
    expect(
      body.pages.length,
      greaterThan(25),
      reason: 'يجب أن نقرأ ترقيم Word لا أن نضع كل شيء في صفحة',
    );
    expect(body.pages.length, lessThan(45));

    // الترقيم متسلسل بلا فجوات، وكل صفحة فيها محتوى.
    for (var i = 0; i < body.pages.length; i++) {
      expect(body.pages[i].number, equals(i + 1));
      expect(body.pages[i].blocks, isNotEmpty);
    }

    // الترويسة والتذييل صفحة واحدة لكلٍّ منهما.
    for (final section in preview.sections) {
      if (section.kind == PreviewSectionKind.body) continue;
      expect(section.pages, hasLength(1), reason: section.partName);
    }
  });

  test('الخطة تُطبَّق على الصفحات وتحفظ ترقيمها', () {
    final source = extractOrFail(buildFixtureDocx());
    final after = restylePreview(
      source,
      StylePlan(
        colors: {HexColor.tryParse('4C2FB8')!: HexColor.tryParse('00635D')!},
      ),
    );
    expect(after.pageCount, equals(source.pageCount));
    for (var i = 0; i < after.sections.length; i++) {
      expect(
        after.sections[i].pages.map((p) => p.number),
        equals(source.sections[i].pages.map((p) => p.number)),
      );
    }
  });
}
