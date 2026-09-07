/// المخرَج الذهبي للمعاينة — `04` §2.
///
/// **حارسٌ لإعادة كتابة الاستخراج.** المعاينة تنتقل من شجرة كاملة إلى بناء
/// ابنٍ واحد في وقته، وهو تغيير في الوسيلة لا في النتيجة. فيُثبَّت الوصف
/// الكامل أوّلًا — كل صفحة بمقاسها، وكل فقرة بمحاذاتها ومسافاتها ونمطها،
/// وكل مقطع بلونه وخطّيه وعلامته — ويصير أي فرق سقوطًا لا مفاجأة.
///
/// لتحديث الذهبي بعد تغييرٍ **مقصود**: E3KS_UPDATE_GOLDEN=1 dart test
library;

import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';
import '../fixtures/pptx_fixture.dart';
import 'inspection_golden_test.dart' show expectGolden;

String describePreview(DocumentPreview preview) {
  final out = StringBuffer();
  for (final section in preview.sections) {
    out.writeln(
      '# ${section.partName}  نوع=${section.kind.name}  '
      'مقتطع=${section.truncated}',
    );
    for (final page in section.pages) {
      out.writeln('  صفحة ${page.number}  ${_geometry(page.geometry)}');
      for (final block in page.blocks) {
        _block(out, block, '    ');
      }
    }
  }
  return out.toString();
}

String _geometry(PageGeometry g) =>
    '${_n(g.widthPt)}×${_n(g.heightPt)}pt  '
    'هوامش ${_n(g.marginTopPt)}/${_n(g.marginRightPt)}/'
    '${_n(g.marginBottomPt)}/${_n(g.marginLeftPt)}';

String _n(double value) => value.toStringAsFixed(2);

void _block(StringBuffer out, PreviewBlock block, String pad) {
  switch (block) {
    case ParagraphBlock(:final paragraph):
      out
        ..write(pad)
        ..writeln('فقرة  صفحة‑جديدة=${block.startsPage}');
      _paragraph(out, paragraph, '$pad  ');
    case TableBlock(:final rows, :final isRtl, :final columnFractions):
      out.write(pad);
      out.writeln(
        'جدول  rtl=$isRtl  صفحة‑جديدة=${block.startsPage}  '
        'أعمدة=${columnFractions.map(_n).join("/")}  ${_frame(block.frame)}',
      );
      for (final row in rows) {
        out.writeln('$pad  صفّ  ترويسة=${row.isHeader}');
        for (final cell in row.cells) {
          out.writeln(
            '$pad    خليّة  تعبئة=${cell.fill?.value}  '
            'امتداد=${cell.columnSpan}',
          );
          for (final paragraph in cell.paragraphs) {
            _paragraph(out, paragraph, '$pad      ');
          }
        }
      }
    case ShapeBlock(:final paragraphs, :final fill):
      out.write(pad);
      out.writeln(
        'شكل  تعبئة=${fill?.value}  '
        'صفحة‑جديدة=${block.startsPage}  ${_frame(block.frame)}',
      );
      for (final paragraph in paragraphs) {
        _paragraph(out, paragraph, '$pad  ');
      }
  }
}

String _frame(BlockFrame? frame) => frame == null
    ? 'إطار=تدفّق'
    : 'إطار=${_n(frame.leftPt)},${_n(frame.topPt)} '
          '${_n(frame.widthPt)}×${_n(frame.heightPt)}';

void _paragraph(StringBuffer out, PreviewParagraph p, String pad) {
  out.write(pad);
  out.writeln(
    'ف: محاذاة=${p.align.name} rtl=${p.isRtl} '
    'نمط=${p.styleName} عنوان=${p.outlineLevel} تعبئة=${p.fill?.value} '
    'قبل=${_n(p.spaceBeforePt)} بعد=${_n(p.spaceAfterPt)} '
    'سطر=${p.lineHeight}',
  );
  for (final run in p.runs) {
    out.writeln(
      '$pad  مقطع «${run.text}» لون=${run.color?.value} '
      'لاتيني=${run.latinFont} عربي=${run.arabicFont} '
      'مقاس=${run.sizePt} ثقيل=${run.bold} مائل=${run.italic} '
      'تحته=${run.underline} تظليل=${run.shading?.value} '
      'تمييز=${run.highlight}',
    );
  }
}

DocumentPreview previewFor(Uint8List bytes) {
  final package = (DocumentPackage.open(bytes) as Ok<DocumentPackage>).value;
  return (formatFor(package) as Ok<DocumentFormat>).value.preview(package);
}

void main() {
  final cases = <String, Uint8List Function()>{
    'preview_docx_fixture': buildFixtureDocx,
    'preview_docx_sectioned': buildSectionedDocx,
    'preview_docx_marked': buildMarkedDocx,
    'preview_pptx_fixture': buildFixturePptx,
    'preview_pptx_marked': buildMarkedPptx,
  };

  cases.forEach((name, build) {
    test('المعاينة الذهبية — $name', () {
      expectGolden(name, describePreview(previewFor(build())));
    });
  });
}
