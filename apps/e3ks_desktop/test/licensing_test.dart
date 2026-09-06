/// الحقوق ليست ملفًّا يُنسى: الرخصة تُشحَن، والإصدار لا ينحرف عن الحزمة.
library;

import 'dart:io';

import 'package:e3ks_desktop/app/about.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e3ks_desktop/data/font_substitutes.dart';

void main() {
  test('الإصدار واحد في المواضع الأربعة', () {
    // رقم في أربعة مواضع ينحرف حتمًا، فيكذب «عن التطبيق» بصمت — والمستخدم
    // يبلّغ عن خلل برقم خاطئ. القاعدة `08` §3: المرجع الواحد يُحرَس آليًّا.
    String versionOf(String pubspec) => File(pubspec)
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('version:'))
        .split(':')[1]
        .trim();

    const packages = [
      'pubspec.yaml',
      '../../packages/e3ks_engine/pubspec.yaml',
      '../../tools/e3ks_cli/pubspec.yaml',
    ];
    for (final pubspec in packages) {
      expect(versionOf(pubspec), equals(appVersion), reason: pubspec);
    }
  });

  test('نصّ رخصة كل خطّ مشحون ومعلَن كأصل', () {
    // OFL 1.1 تُلزم بشحن النصّ مع الخطّ. غيابه مخالفة ترخيص لا سهو تنظيمي.
    // وتسعة خطوط تعني تسع رخص، لا رخصةً واحدة تنوب عنها.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final family in bundledFamilies) {
      final path = 'assets/fonts/OFL-${family.replaceAll(' ', '')}.txt';
      final ofl = File(path);
      expect(ofl.existsSync(), isTrue, reason: 'رخصة «$family» مفقودة');
      expect(
        ofl.readAsStringSync().toUpperCase(),
        contains('SIL OPEN FONT LICENSE'),
        reason: '«$path» ليس نصّ OFL',
      );
      expect(
        pubspec,
        contains(path),
        reason: 'مشحون لكن غير مقروء ⇒ لا يظهر في رخص المكوّنات',
      );
    }
  });

  test('رخصة المشروع موجودة في جذره', () {
    final license = File('../../LICENSE');
    expect(license.existsSync(), isTrue);
    expect(license.readAsStringSync(), contains('GNU GENERAL PUBLIC LICENSE'));
  });

  test('رابط المصدر يشير إلى حساب المالك', () {
    // GPL‑3 §5: البرنامج التفاعلي يعرض إشعاراته، ومنها أين يجد المستخدم
    // الشيفرة. رابط خاطئ يُبطل الغرض.
    expect(sourceUrl, startsWith('https://github.com/m7md-d/'));
    for (final path in [
      'pubspec.yaml',
      '../../packages/e3ks_engine/pubspec.yaml',
      '../../tools/e3ks_cli/pubspec.yaml',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains(sourceUrl),
        reason: '$path لا يذكر المستودع',
      );
    }
  });
}
