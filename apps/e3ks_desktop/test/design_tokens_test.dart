/// حارس مرجع الحقيقة الواحد للألوان.
///
/// القاعدة `07`: لا لون يُؤلَّف خارج `lib/app/tokens.dart`.
/// قاعدة بلا اختبار أمنية؛ هذا الملف يجعلها أمرًا واقعًا.
library;

import 'dart:io';

import 'package:e3ks_desktop/app/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const String _tokensFile = 'lib/app/tokens.dart';

/// `Colors.transparent` غياب لون لا لون، فلا يُعدّ تأليفًا.
/// حدّ الكلمة يمنع مطابقة `unmatchedColors` و`contentColors` وأخواتها.
final _colorLiteral = RegExp(r'Color\(0x|\bColors\.(?!transparent)[a-z]');

/// وزن أو اسم خطّ مكتوب يدويًا. `fontFamily: name` ديناميكي ومسموح —
/// فذاك خطّ المستند لا خطّ التطبيق.
final _typeLiteral = RegExp(r'''\bFontWeight\.|fontFamily:\s*['"]''');

String _hex(Color c) {
  String two(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${two(c.r)}${two(c.g)}${two(c.b)}'.toUpperCase();
}

/// ‏`Duration(...)` بأي وحدة، و`Curves.<اسم>` — كلاهما قرار حركة.
final RegExp _durationLiteral = RegExp(r'\bDuration\s*\(');
final RegExp _curveLiteral = RegExp(r'\bCurves\s*\.');

void main() {
  test('لا لون مؤلَّف خارج ملف الرموز', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path;
      if (path.endsWith(_tokensFile) || path.contains('/l10n/')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        if (_colorLiteral.hasMatch(line)) {
          offenders.add('$path:${i + 1}  $trimmed');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'لون خارج $_tokensFile:\n${offenders.join("\n")}',
    );
  });

  test('لا زمن ولا منحنى حركة مؤلَّف خارج ملف الرموز', () {
    // الحركة لغة كالألوان. أزمنة متناثرة (‏120 هنا و‎130‎ هناك) تُنتج واجهةً
    // تبدو مصنوعة على دفعات، والعين تلتقط ذلك قبل أن يسمّيه صاحبها.
    //
    // ما ليس حركةً — كمهلة طلب شبكة — يُعلَّم بـ`// e3ks:not-motion` في سطره.
    // الاستثناء سطريّ لا ملفّيّ، فيبقى ظاهرًا وقابلًا للتدقيق بـgrep.
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path;
      if (path.endsWith(_tokensFile) || path.contains('/l10n/')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        if (trimmed.contains('e3ks:not-motion')) continue;
        if (_durationLiteral.hasMatch(line) || _curveLiteral.hasMatch(line)) {
          offenders.add('$path:${i + 1}  $trimmed');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'حركة خارج $_tokensFile:\n${offenders.join("\n")}',
    );
  });

  test('لا وزن ولا اسم خطّ مؤلَّف خارج ملف الرموز', () {
    // الخطّ هوية مثل اللون. وزنٌ يُكتب في ودجة يعني أن تغيير الخطّ لاحقًا
    // يستلزم تمشيط عشرين ملفًا.
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path;
      if (path.endsWith(_tokensFile) || path.contains('/l10n/')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        if (_typeLiteral.hasMatch(lines[i])) {
          offenders.add('$path:${i + 1}  $trimmed');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'خطّ خارج $_tokensFile:\n${offenders.join("\n")}',
    );
  });

  test('كل وزن يستعمله التطبيق مضمَّن فعلًا في pubspec', () {
    // طلب وزن غير مضمَّن يجعل Flutter يصطنعه، فيبهت الخطّ بلا رسالة خطأ.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains("family: ${Type.family}"));

    for (final weight in [
      Type.display,
      Type.regular,
      Type.semiBold,
      Type.bold,
    ]) {
      expect(
        pubspec,
        contains('weight: ${weight.value}'),
        reason: 'الوزن ${weight.value} مستعمَل ولم يُضمَّن',
      );
    }

    // وملفات الخطّ موجودة ورخصتها معها.
    final dir = Directory('assets/fonts');
    expect(dir.existsSync(), isTrue, reason: 'مجلد الخطوط مفقود');
    final files = dir.listSync().map((e) => e.path.split('/').last).toSet();
    expect(files.where((f) => f.endsWith('.ttf')).length, equals(4));
    expect(files, contains('OFL.txt'), reason: 'رخصة الخطّ يجب أن تُشحَن معه');
  });

  test('كل لون في الرموز فريد داخل نطاقه', () {
    // لونان متطابقان باسمين مختلفين = انحراف ينتظر وقته.
    const shades = {
      'canvas': Shade.canvas,
      'surface': Shade.surface,
      'surfaceHigh': Shade.surfaceHigh,
      'surfaceHover': Shade.surfaceHover,
      'border': Shade.border,
      'borderStrong': Shade.borderStrong,
      'text': Shade.text,
      'textMuted': Shade.textMuted,
      'textFaint': Shade.textFaint,
      'mirror': Shade.mirror,
      'mirrorSoft': Shade.mirrorSoft,
      'mirrorDeep': Shade.mirrorDeep,
      'onMirror': Shade.onMirror,
      'success': Shade.success,
      'warning': Shade.warning,
      'danger': Shade.danger,
    };
    final seen = <String, String>{};
    for (final entry in shades.entries) {
      final hex = _hex(entry.value);
      expect(
        seen[hex],
        isNull,
        reason: '${entry.key} يطابق ${seen[hex]} — احذف أحدهما',
      );
      seen[hex] = entry.key;
    }
  });

  test('ألوان الرمز مطابقة لملفات SVG', () {
    // المرجع الواحد يعبر حدود اللغات: Dart تقرّر، وSVG تتبع.
    const expected = {
      'ink': Brand.ink,
      'paper': Brand.paper,
      'mirror': Brand.mirror,
    };

    for (final name in ['e3ks-icon.svg', 'e3ks-icon-small.svg']) {
      final file = File('../../brand/$name');
      if (!file.existsSync()) {
        fail('ملف الرمز مفقود: $name');
      }
      final source = file.readAsStringSync();

      for (final entry in expected.entries) {
        expect(
          source,
          contains(_hex(entry.value)),
          reason:
              '$name لا يستعمل Brand.${entry.key} '
              '(${_hex(entry.value)}) — عدّل tokens.dart لا الـSVG',
        );
      }

      // ولا لون آخر: ثلاثة ألوان فقط، لا رابع يتسلّل.
      final used = RegExp(
        r'#[0-9A-Fa-f]{6}',
      ).allMatches(source).map((m) => m[0]!.toUpperCase()).toSet();
      expect(
        used,
        equals(expected.values.map(_hex).toSet()),
        reason: '$name فيه لون خارج الرموز',
      );
    }
  });

  test('التباين يفي بمعيار WCAG في الأدوار الحرجة', () {
    double luminance(Color c) {
      double channel(double v) =>
          v <= 0.03928 ? v / 12.92 : _pow((v + 0.055) / 1.055, 2.4);
      return 0.2126 * channel(c.r) +
          0.7152 * channel(c.g) +
          0.0722 * channel(c.b);
    }

    double ratio(Color a, Color b) {
      final x = luminance(a), y = luminance(b);
      final hi = x > y ? x : y, lo = x > y ? y : x;
      return (hi + 0.05) / (lo + 0.05);
    }

    // نصّ لا يُقرأ ليس خيارًا جماليًا، بل عطل.
    expect(
      ratio(Shade.text, Shade.canvas),
      greaterThan(7.0),
      reason: 'النصّ الأساسي على الخلفية',
    );
    expect(
      ratio(Shade.textMuted, Shade.surface),
      greaterThan(4.5),
      reason: 'النصّ الثانوي على اللوحات',
    );
    expect(
      ratio(Shade.onMirror, Shade.mirror),
      greaterThan(4.5),
      reason: 'نصّ الأزرار على السماوي',
    );
    expect(
      ratio(Shade.mirror, Shade.canvas),
      greaterThan(4.5),
      reason: 'لون الفعل على الخلفية',
    );
    expect(
      ratio(Paper.ink, Paper.sheet),
      greaterThan(7.0),
      reason: 'حبر المستند على الورقة',
    );
    expect(
      ratio(Brand.mirror, Brand.ink),
      greaterThan(4.5),
      reason: 'الرمز: السماوي على الحبر',
    );
    expect(
      ratio(Brand.ink, Brand.paper),
      greaterThan(7.0),
      reason: 'الرمز: الحبر على الورق',
    );
  });
}

// تقريب كافٍ لحساب الإضاءة، بلا استيراد dart:math في ملف اختبار رموز.
double _pow(double base, double exp) => _exp(exp * _ln(base));

double _ln(double x) {
  var sum = 0.0;
  final z = (x - 1) / (x + 1);
  var term = z;
  for (var n = 1; n < 60; n += 2) {
    sum += term / n;
    term *= z * z;
  }
  return 2 * sum;
}

double _exp(double x) {
  var sum = 1.0, term = 1.0;
  for (var n = 1; n < 40; n++) {
    term *= x / n;
    sum += term;
  }
  return sum;
}
