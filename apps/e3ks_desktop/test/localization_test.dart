/// اختبارات الترجمة — أضعف نقطة في أي تطبيق متعدّد اللغات هي مفتاح منسيّ.
library;

import 'dart:convert';
import 'dart:io';

import 'package:e3ks_desktop/app/l10n_extensions.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> loadArb(String code) =>
    (jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync()) as Map)
        .cast<String, Object?>();

Set<String> keysOf(Map<String, Object?> arb) => {
  for (final k in arb.keys)
    if (!k.startsWith('@')) k,
};

void main() {
  group('ملفات الترجمة', () {
    test('اللغتان متطابقتان في المفاتيح', () {
      // مفتاح ناقص = نصّ إنجليزي يظهر فجأة داخل واجهة عربية، أو انهيار.
      final ar = keysOf(loadArb('ar'));
      final en = keysOf(loadArb('en'));
      expect(en.difference(ar), isEmpty, reason: 'مفاتيح زائدة في الإنجليزي');
      expect(ar.difference(en), isEmpty, reason: 'مفاتيح ناقصة في الإنجليزي');
      expect(ar.length, greaterThan(100));
    });

    test('لا قيمة فارغة في أي لغة', () {
      for (final code in ['ar', 'en']) {
        final arb = loadArb(code);
        for (final key in keysOf(arb)) {
          expect(arb[key], isA<String>(), reason: '$code/$key');
          expect(
            (arb[key]! as String).trim(),
            isNotEmpty,
            reason: '$code/$key فارغ',
          );
        }
      }
    });

    test('المعاملات متطابقة بين اللغتين', () {
      // "{count}" في العربي و"{total}" في الإنجليزي ⇒ انهيار وقت التشغيل.
      final ar = loadArb('ar');
      final en = loadArb('en');
      final pattern = RegExp(r'\{(\w+)\}');
      for (final key in keysOf(ar)) {
        Set<String> holes(Map<String, Object?> arb) =>
            pattern.allMatches(arb[key]! as String).map((m) => m[1]!).toSet();
        expect(holes(en), equals(holes(ar)), reason: 'المعاملات تختلف في $key');
      }
    });
  });

  group('جسر المحرّك', () {
    late L ar;
    late L en;

    setUpAll(() async {
      ar = await L.delegate.load(const Locale('ar'));
      en = await L.delegate.load(const Locale('en'));
    });

    test('كل رمز مشكلة له نصّ في اللغتين', () {
      // رمز بلا صياغة = رسالة خطأ فارغة أمام المستخدم في أسوأ لحظة.
      for (final code in IssueCode.values) {
        final issue = EngineIssue(code: code, part: 'word/header1.xml');
        expect(
          issueText(ar, issue).trim(),
          isNotEmpty,
          reason: '${code.name} ar',
        );
        expect(
          issueText(en, issue).trim(),
          isNotEmpty,
          reason: '${code.name} en',
        );
      }
    });

    test('كل قيمة في تعدادات المحرّك لها تسمية', () {
      for (final role in ColorRole.values) {
        expect(role.label(ar).trim(), isNotEmpty, reason: role.name);
        expect(role.label(en).trim(), isNotEmpty, reason: role.name);
      }
      for (final family in ColorFamily.values) {
        expect(family.label(ar).trim(), isNotEmpty, reason: family.name);
      }
      for (final tone in ColorTone.values) {
        expect(tone.label(ar).trim(), isNotEmpty, reason: tone.name);
      }
      for (final slot in FontSlot.values) {
        expect(slot.label(ar).trim(), isNotEmpty, reason: slot.name);
      }
      for (final kind in PreviewSectionKind.values) {
        expect(kind.label(ar).trim(), isNotEmpty, reason: kind.name);
        expect(kind.label(en).trim(), isNotEmpty, reason: kind.name);
      }
    });

    test('وصف اللون يختلف باختلاف اللغة', () {
      final teal = HexColor.tryParse('00403C')!;
      expect(teal.describe(ar), equals('أزرق مخضرّ داكن جدًا'));
      expect(teal.describe(en), equals('teal very dark'));
    });

    test('أسماء الأجزاء تُترجَم لا تُعرَض كمسارات', () {
      expect(partLabel(ar, 'word/header1.xml'), equals('الترويسة'));
      expect(partLabel(en, 'word/header1.xml'), equals('Header'));
      expect(partLabel(en, 'word/styles.xml'), equals('Styles'));
    });
  });

  test('لا سلسلة عربية مكتوبة داخل ودجة', () {
    // القاعدة `03`: كل النصّ المرئي في ARB. هذا الاختبار يحرسها آليًا.
    //
    // سطرٌ يحمل `// e3ks:not-ui` مستثنى: نصٌّ يُقاس أو يُطابَق ولا يُعرَض.
    // الاستثناء سطريّ لا ملفّيّ، فيبقى ظاهرًا وقابلًا للتدقيق بـgrep.
    final arabic = RegExp(r'''['"][^'"]*[؀-ۿ][^'"]*['"]''');
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('/l10n/')) continue; // المولَّد والمصدر
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (line.startsWith('*') || line.startsWith('/*')) continue;
        if (line.contains('e3ks:not-ui')) continue;
        if (!arabic.hasMatch(line)) continue;
        // الفواصل والمحارف الوظيفية مسموحة.
        if (RegExp(r"^.*'[،؛]\s?'.*$").hasMatch(line)) continue;
        offenders.add('${entity.path}:${i + 1}  $line');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'نصّ عربي خارج ARB:\n${offenders.join("\n")}',
    );
  });
}
