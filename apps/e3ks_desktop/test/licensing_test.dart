/// الحقوق ليست ملفًّا يُنسى: الرخصة تُشحَن، والإصدار لا ينحرف عن الحزمة.
library;

import 'dart:io';

import 'package:e3ks_desktop/app/about.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('الإصدار المعروض يطابق pubspec', () {
    // رقمان للإصدار في مكانين ينحرفان حتمًا، فيكذب «عن التطبيق» بصمت.
    final line = File(
      'pubspec.yaml',
    ).readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(line.split(':')[1].trim(), equals(appVersion));
  });

  test('نصّ رخصة الخطّ مشحون ومعلَن كأصل', () {
    // OFL 1.1 تُلزم بشحن النصّ مع الخطّ. غيابه مخالفة ترخيص لا سهو تنظيمي.
    final ofl = File('assets/fonts/OFL.txt');
    expect(ofl.existsSync(), isTrue);
    expect(ofl.readAsStringSync(), contains('SIL OPEN FONT LICENSE'));
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('assets/fonts/OFL.txt'),
      reason: 'مشحون لكن غير مقروء ⇒ لا يظهر في رخص المكوّنات',
    );
  });

  test('رخصة المشروع موجودة في جذره', () {
    final license = File('../../LICENSE');
    expect(license.existsSync(), isTrue);
    expect(license.readAsStringSync(), contains('GNU GENERAL PUBLIC LICENSE'));
  });

  test('رابط المصدر يشير إلى حساب المالك', () {
    // ‏GPL‑3 §5: البرنامج التفاعلي يعرض إشعاراته، ومنها أين يجد المستخدم
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
