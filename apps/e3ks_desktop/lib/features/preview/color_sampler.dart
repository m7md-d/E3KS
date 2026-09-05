/// التقاط لون من بكسل المعاينة المرسومة.
///
/// المنتقي يقرأ **ما رُسم فعلًا** لا ما تحمله الودجة: التعبئة والحدّ والنصّ
/// كلّها بكسلات، وأيّها قد يكون ما يقصده المستخدم.
///
/// **ولا يُرجَع لون البكسل خامًا.** تنعيم الحواف يمزج لون الحرف بأرضيّته،
/// فبكسل من حافّة حرف أحمر ليس أحمر ولا أبيض، ورقمه لا يقابل صفًّا في قائمة
/// الألوان فلا ينفع المستخدم. نردّه إلى أقرب لون **يعلنه المستند**، وإن لم
/// يقترب من أيٍّ منها لم نخمّن — عجزٌ معلَن خيرٌ من لون مؤلَّف (`00` §5).
library;

import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';

/// نصف قطر البحث حول نقطة المؤشّر، ببكسل الشاشة الفيزيائي.
///
/// الحرف عند تكبير المعاينة الافتراضي ساقُه بكسلان أو ثلاثة، وقلبها وحده
/// يحمل اللون نقيًّا. البحث في جوارٍ صغير يبلغ ذلك القلب دون أن يقفز إلى
/// حرفٍ مجاور.
const int searchRadius = 4;

/// أقصى بُعد لوني نقبله مطابقةً — مسافة إقليدية في فضاء RGB (المدى 0..441).
///
/// أوسع من الصفر لأن الرسم يقرّب، وأضيق من أن يخلط لونين متجاورين في هوية
/// واحدة: درجتان في سلَّم واحد بينهما أكثر من هذا بكثير.
const int matchTolerance = 30;

/// شبكة بكسلات خام (RGBA، أربعة بايتات لكل بكسل) ملتقَطة من المعاينة.
final class PixelGrid {
  const PixelGrid({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final ByteData bytes;
  final int width;
  final int height;

  /// ‏`0xRRGGBB` عند النقطة، أو `null` خارج الحدود.
  int? rgbAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return null;
    final offset = (y * width + x) * 4;
    if (offset + 2 >= bytes.lengthInBytes) return null;
    return (bytes.getUint8(offset) << 16) |
        (bytes.getUint8(offset + 1) << 8) |
        bytes.getUint8(offset + 2);
  }
}

/// يردّ نقطةً على المعاينة إلى لونٍ يعلنه المستند، أو `null` إن لم يقترب منه.
///
/// **الترتيب مقصود:** نفحص حلقةً حلقةً من نقطة المؤشّر إلى الخارج، فأقرب
/// بكسل قابل للمطابقة يفوز — وهذا يجعل الضغط على مساحة ممتلئة دقيقًا فورًا.
///
/// وداخل الحلقة الواحدة يفوز **الأبعد عن أرضيّة الصفحة**: من يضغط على حرف
/// يقصد الحرف لا الورق تحته، والحلقة عند حافّة الحرف تحمل الاثنين معًا.
HexColor? resolveColorAt(
  PixelGrid grid,
  int x,
  int y, {
  required List<HexColor> candidates,
  required HexColor background,
  int radius = searchRadius,
  int tolerance = matchTolerance,
}) {
  if (candidates.isEmpty) return null;

  final packed = [for (final color in candidates) _rgb(color)];
  final ground = _rgb(background);
  final limit = tolerance * tolerance;

  for (var ring = 0; ring <= radius; ring++) {
    HexColor? best;
    var bestGap = -1;

    for (final (px, py) in _ring(x, y, ring)) {
      final pixel = grid.rgbAt(px, py);
      if (pixel == null) continue;

      var nearest = -1;
      var nearestGap = limit + 1;
      for (var i = 0; i < packed.length; i++) {
        final gap = _distance(pixel, packed[i]);
        if (gap <= limit && gap < nearestGap) {
          nearestGap = gap;
          nearest = i;
        }
      }
      if (nearest < 0) continue;

      final fromGround = _distance(packed[nearest], ground);
      if (fromGround > bestGap) {
        bestGap = fromGround;
        best = candidates[nearest];
      }
    }

    if (best != null) return best;
  }
  return null;
}

/// نقاط الحلقة المربّعة على بُعد `ring` من المركز (مسافة تشيبيشيف).
Iterable<(int, int)> _ring(int x, int y, int ring) sync* {
  if (ring == 0) {
    yield (x, y);
    return;
  }
  for (var dx = -ring; dx <= ring; dx++) {
    yield (x + dx, y - ring);
    yield (x + dx, y + ring);
  }
  for (var dy = -ring + 1; dy <= ring - 1; dy++) {
    yield (x - ring, y + dy);
    yield (x + ring, y + dy);
  }
}

int _rgb(HexColor color) => int.parse(color.ooxmlValue, radix: 16);

/// مربّع المسافة الإقليدية — الجذر لا يغيّر الترتيب ولا نحتاجه.
int _distance(int a, int b) {
  final dr = ((a >> 16) & 0xFF) - ((b >> 16) & 0xFF);
  final dg = ((a >> 8) & 0xFF) - ((b >> 8) & 0xFF);
  final db = (a & 0xFF) - (b & 0xFF);
  return dr * dr + dg * dg + db * db;
}
