/// الدفعة: حصيلة مجموعة ملفات بخطة واحدة.
library;

import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';
import '../fixtures/pptx_fixture.dart';

/// `!` مضمون: القيم أدناه بصيغة `#RRGGBB` صحيحة.
HexColor hex(String value) => HexColor.tryParse(value)!;

BatchEntry run(String name, Uint8List bytes, StylePlan plan) =>
    BatchEntry.of(name, restyle(bytes, plan));

void main() {
  final purple = hex('#4C2FB8');
  final teal = hex('#00635D');

  test('ملف تالف لا يُوقف البقيّة', () {
    // أربعون ملفًا فيها واحد تالف تعني تسعة وثلاثين مخرَجًا وتقريرًا
    // بالأخير، لا صفرًا وشكوى.
    final plan = StylePlan(colors: {purple: teal});
    final report = BatchReport([
      run('سليم.docx', buildFixtureDocx(), plan),
      run('تالف.docx', Uint8List.fromList([1, 2, 3, 4]), plan),
    ]);

    expect(report.written.map((e) => e.name), equals(['سليم.docx']));
    expect(report.failed.map((e) => e.name), equals(['تالف.docx']));
    expect(report.failed.single.issues, isNotEmpty);
    expect(report.totalColorReplacements, greaterThan(0));
  });

  test('لون لا يُطابق أي ملف يُعلَن، ولون يُطابق واحدًا لا يُعلَن', () {
    final ghost = hex('#ABCDEF');
    final plan = StylePlan(colors: {purple: teal, ghost: teal});

    final report = BatchReport([
      run('واحد.docx', buildFixtureDocx(), plan),
      run('اثنان.docx', buildFixtureDocx(), plan),
    ]);

    expect(report.unmatchedEverywhere, contains(ghost));
    expect(report.unmatchedEverywhere, isNot(contains(purple)));
  });

  test('صيغتان في دفعة واحدة', () {
    // الدفعة لا تعرف صيغة: المسار يتعرّف على كل ملف بمحتواه.
    final plan = StylePlan(
      colors: {purple: teal, hex('#1B7F79'): hex('#00403C')},
    );
    final report = BatchReport([
      run('مستند.docx', buildFixtureDocx(), plan),
      run('عرض.pptx', buildFixturePptx(), plan),
    ]);

    expect(report.written.length, equals(2));
    expect(report.filesByColor[purple], equals(1));
    expect(report.filesByColor[hex('#1B7F79')], equals(1));
  });

  test('ملف لا يحتاج تغييرًا يُحسب ولا يُعدّ سقوطًا', () {
    final report = BatchReport([
      run('كما هو.docx', buildFixtureDocx(), const StylePlan()),
    ]);

    expect(report.failed, isEmpty);
    expect(report.unchanged.map((e) => e.name), equals(['كما هو.docx']));
    expect(report.totalColorReplacements, equals(0));
  });

  test('دفعة كلها ساقطة لا تحكم على الخطة', () {
    // بلا ملفٍّ ناجح لا مقياس: الصمت أصدق من ادّعاء أن الخطة خطأ.
    final report = BatchReport([
      run(
        'تالف.docx',
        Uint8List.fromList([0]),
        StylePlan(colors: {purple: teal}),
      ),
    ]);

    expect(report.unmatchedEverywhere, isEmpty);
    expect(report.filesByColor, isEmpty);
  });
}
