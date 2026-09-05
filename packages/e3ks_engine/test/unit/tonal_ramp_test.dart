/// سلَّم الدرجات: مشتقٌّ محسوب، لا ألوان مؤلَّفة.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

HexColor hex(String value) => HexColor.tryParse(value)!;

void main() {
  test('السلَّم تسع درجات مرقَّمة من الأفتح إلى الأغمق', () {
    final ramp = tonalRamp(hex('00635D'));
    expect(ramp, hasLength(9));
    expect(ramp.first.step, equals(100));
    expect(ramp.last.step, equals(900));

    // الإضاءة تنقص باطّراد: سلَّمٌ لا يترتّب ليس سلَّمًا.
    for (var i = 1; i < ramp.length; i++) {
      expect(
        ramp[i].color.lightness,
        lessThan(ramp[i - 1].color.lightness),
        reason: 'الدرجة ${ramp[i].step} ليست أغمق ممّا قبلها',
      );
    }
  });

  test('اللون الأصل موجود في سلَّمه بنفسه لا تقريبًا له', () {
    // لو أعطيناه تقريبًا لبدا السلَّم غريبًا عن اللون الذي اختاره.
    for (final value in ['00635D', 'A32834', 'F2F4F7', '1B7F79']) {
      final base = hex(value);
      final ramp = tonalRamp(base);
      final source = ramp.where((t) => t.isSource);
      expect(source, hasLength(1), reason: value);
      expect(source.first.color.value, equals(base.value), reason: value);
    }
  });

  test('الدرجة اللونية محفوظة عبر السلَّم', () {
    // سلَّمٌ ينزلق لونه ليس درجاتِ اللون بل ألوانًا أخرى.
    final ramp = tonalRamp(hex('00635D'));
    for (final tone in ramp) {
      if (tone.color.family == ColorFamily.neutral) continue; // الأطراف
      expect(
        tone.color.family,
        equals(ColorFamily.teal),
        reason: '${tone.step} انزلق إلى ${tone.color.family}',
      );
    }
  });

  test('الإشباع يهبط عند الطرفين لا في الوسط', () {
    // إضاءة قصوى بإشباع كامل تُنتج ألوانًا فاقعة لا تُستعمل في مستند.
    final ramp = tonalRamp(hex('1B7F79'));
    final middle = ramp[4].color.saturation;
    expect(ramp.first.color.saturation, lessThan(middle));
    expect(ramp.last.color.saturation, lessThan(middle));
  });

  test('المحايد يعطي سلَّمًا رماديًّا لا فارغًا', () {
    // الرماديات درجاتٌ مطلوبة كغيرها.
    final ramp = tonalRamp(hex('808080'));
    expect(ramp, hasLength(9));
    for (final tone in ramp) {
      expect(tone.color.saturation, lessThan(0.05));
    }
  });

  test('الأبيض والأسود لهما سلَّمهما ولا ينهار الحساب', () {
    for (final value in ['FFFFFF', '000000']) {
      final ramp = tonalRamp(hex(value));
      expect(ramp, hasLength(9));
      expect(ramp.where((t) => t.isSource), hasLength(1), reason: value);
    }
  });
}
