/// لون مُطبَّع بصيغة `#RRGGBB`.
///
/// نوع مستقلّ لا `String` — القاعدة `03`: خطأ تمرير وسيط مكان آخر يجب أن
/// يظهر عند الترجمة لا عند التشغيل.
library;

import 'dart:math' as math;

/// عائلة لونية. **بلا نصّ معروض** — الترجمة شأن الواجهة (`01`).
enum ColorFamily {
  red,
  orange,
  gold,
  green,
  teal,
  cyan,
  blue,
  purple,
  pink,
  neutral,
}

/// درجة الإضاءة. بلا نصّ معروض، لنفس السبب.
enum ColorTone { veryDark, dark, medium, light, veryLight }

extension type const HexColor._(String value) implements Object {
  /// يطبّع قيمة لون من OOXML.
  ///
  /// يقبل `RRGGBB` و`AARRGGBB` (نُسقط قناة الشفافية) وبادئة `#` اختيارية.
  /// يُرجع `null` لكل ما ليس لونًا صريحًا — ومنه `auto`، فهي تفويض لـ Word
  /// لا لون (`02` §5). تمييزها مهمّ: عدّها لونًا يلوّث الإحصاء ويغري بتبديلها.
  static HexColor? tryParse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 8) s = s.substring(2); // AARRGGBB → RRGGBB
    if (s.length != 6) return null;
    for (final unit in s.codeUnits) {
      final isDigit = unit >= 0x30 && unit <= 0x39;
      final isUpper = unit >= 0x41 && unit <= 0x46;
      final isLower = unit >= 0x61 && unit <= 0x66;
      if (!isDigit && !isUpper && !isLower) return null;
    }
    return HexColor._('#${s.toUpperCase()}');
  }

  int get _r => int.parse(value.substring(1, 3), radix: 16);
  int get _g => int.parse(value.substring(3, 5), radix: 16);
  int get _b => int.parse(value.substring(5, 7), radix: 16);

  /// بلا `#` — الصيغة التي يكتبها OOXML.
  String get ooxmlValue => value.substring(1);

  /// الإضاءة النسبية حسب WCAG. أساس حساب التباين واختيار الدرجة المقابلة.
  double get relativeLuminance {
    double channel(int v) {
      final c = v / 255.0;
      return c <= 0.03928
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(_r) + 0.7152 * channel(_g) + 0.0722 * channel(_b);
  }

  /// نسبة التباين مع لون آخر حسب WCAG (‏1:1 إلى 21:1).
  double contrastWith(HexColor other) {
    final a = relativeLuminance;
    final b = other.relativeLuminance;
    final (hi, lo) = a > b ? (a, b) : (b, a);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// درجة الإشباع (0..1).
  double get saturation {
    final r = _r / 255, g = _g / 255, b = _b / 255;
    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    final l = (maxC + minC) / 2;
    if (maxC == minC) return 0;
    final d = maxC - minC;
    return l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC);
  }

  /// الإضاءة بمعنى HSL (0..1) — للتصنيف، لا للتباين.
  double get lightness {
    final r = _r / 255, g = _g / 255, b = _b / 255;
    return (math.max(r, math.max(g, b)) + math.min(r, math.min(g, b))) / 2;
  }

  double get _hue {
    final r = _r / 255, g = _g / 255, b = _b / 255;
    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    if (maxC == minC) return 0;
    final d = maxC - minC;
    final double h;
    if (maxC == r) {
      h = ((g - b) / d) % 6;
    } else if (maxC == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    return (h * 60) % 360;
  }

  ColorFamily get family {
    // إشباع منخفض أو إضاءة متطرّفة ⇒ محايد مهما كانت الدرجة اللونية.
    if (saturation < 0.12 || lightness < 0.06 || lightness > 0.96) {
      return ColorFamily.neutral;
    }
    final h = _hue;
    if (h < 15 || h >= 345) return ColorFamily.red;
    if (h < 45) return ColorFamily.orange;
    if (h < 70) return ColorFamily.gold;
    if (h < 155) return ColorFamily.green;
    if (h < 185) return ColorFamily.teal;
    if (h < 200) return ColorFamily.cyan;
    if (h < 255) return ColorFamily.blue;
    if (h < 300) return ColorFamily.purple;
    return ColorFamily.pink;
  }

  ColorTone get tone {
    final l = lightness;
    if (l < 0.18) return ColorTone.veryDark;
    if (l < 0.38) return ColorTone.dark;
    if (l < 0.62) return ColorTone.medium;
    if (l < 0.85) return ColorTone.light;
    return ColorTone.veryLight;
  }
}
