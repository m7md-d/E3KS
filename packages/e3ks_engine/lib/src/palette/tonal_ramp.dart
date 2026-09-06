/// سُلَّم درجات مشتقّ من لون واحد.
///
/// **الحاجة:** المستخدم اختار لون هويته، ويريد درجاته — أفتح للخلفيات وأغمق
/// للنصّ — بلا أن يفتح أداة تصميم ويحسبها بنفسه.
///
/// **الطريقة:** نثبّت الدرجة اللونية (hue) ونمشي على سلَّم إضاءة معلَن، ثمّ
/// نخفض الإشباع عند الطرفين. لماذا الخفض؟ لأن الإضاءة القصوى بإشباع كامل
/// تُنتج ألوانًا فاقعة لا تُستعمل في مستند: أصفر يحرق العين وأزرق يبدو
/// نيونًا. سلالم أنظمة التصميم كلّها تفعل هذا.
///
/// **وما ليس فيها:** لا نموذج إدراكي (OKLCH وأخواته). HSL تكفي لسلَّمٍ
/// يختار منه إنسان بعينه، وإدخال نموذج كامل هنا دَيْنٌ بلا مقابل ظاهر.
library;

import 'dart:math' as math;

import '../inspect/hex_color.dart';

/// سلَّم الإضاءة المعلَن — تسع درجات كما في أنظمة التصميم الشائعة.
///
/// غير متساوي المسافات عمدًا: العين تميّز فروق الفواتح أكثر من الغوامق،
/// فنُكثّف أعلى السلَّم ونُباعد أسفله.
const List<double> _lightnessLadder = [
  0.95,
  0.88,
  0.78,
  0.66,
  0.54,
  0.43,
  0.33,
  0.24,
  0.15,
];

/// أقلّ إشباع نسمح به عند الطرفين، كنسبة من إشباع الأصل.
const double _edgeSaturation = 0.55;

/// درجة واحدة في السلَّم.
typedef Tone = ({HexColor color, int step, bool isSource});

/// يشتقّ سلَّم درجات من [base].
///
/// الدرجة الأقرب إلى [base] تُستبدل به نفسه وتُعلَّم [Tone.isSource]: المستخدم
/// يجب أن يرى لونه هو في السلَّم لا تقريبًا له، وإلّا بدا السلَّم غريبًا عنه.
///
/// **اللون المحايد يُرجع سلَّمًا رماديًّا** لا فارغًا: الرماديات درجاتٌ
/// مطلوبة كغيرها، والأسود والأبيض لهما سلَّمهما.
List<Tone> tonalRamp(HexColor base) {
  final hue = _hueOf(base);
  final saturation = base.saturation;
  final sourceLightness = base.lightness;

  // أقرب درجة إلى إضاءة الأصل — هناك يُزرع اللون نفسه.
  var nearest = 0;
  var nearestGap = double.infinity;
  for (var i = 0; i < _lightnessLadder.length; i++) {
    final gap = (_lightnessLadder[i] - sourceLightness).abs();
    if (gap < nearestGap) {
      nearestGap = gap;
      nearest = i;
    }
  }

  return [
    for (var i = 0; i < _lightnessLadder.length; i++)
      (
        color: i == nearest
            ? base
            : _fromHsl(hue, saturation * _edgeFactor(i), _lightnessLadder[i]),
        // الترقيم كسلالم التصميم: 100 أفتح و900 أغمق.
        step: (i + 1) * 100,
        isSource: i == nearest,
      ),
  ];
}

/// معامل خفض الإشباع بحسب البعد عن وسط السلَّم.
double _edgeFactor(int index) {
  final middle = (_lightnessLadder.length - 1) / 2;
  final distance = (index - middle).abs() / middle;
  return 1 - (1 - _edgeSaturation) * distance * distance;
}

double _hueOf(HexColor color) {
  final r = int.parse(color.value.substring(1, 3), radix: 16) / 255;
  final g = int.parse(color.value.substring(3, 5), radix: 16) / 255;
  final b = int.parse(color.value.substring(5, 7), radix: 16) / 255;
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

HexColor _fromHsl(double hue, double saturation, double lightness) {
  final s = saturation.clamp(0.0, 1.0);
  final l = lightness.clamp(0.0, 1.0);
  final c = (1 - (2 * l - 1).abs()) * s;
  final x = c * (1 - (((hue / 60) % 2) - 1).abs());
  final m = l - c / 2;

  final (double r, double g, double b) = switch (hue ~/ 60) {
    0 => (c, x, 0),
    1 => (x, c, 0),
    2 => (0, c, x),
    3 => (0, x, c),
    4 => (x, 0, c),
    _ => (c, 0, x),
  };

  String channel(double v) =>
      (((v + m) * 255).round().clamp(0, 255)).toRadixString(16).padLeft(2, '0');

  return HexColor.tryParse('${channel(r)}${channel(g)}${channel(b)}')!;
}
