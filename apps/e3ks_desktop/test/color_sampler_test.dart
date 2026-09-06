/// منتقي اللون: ردّ بكسل مرسوم إلى لون يعلنه المستند.
library;

import 'dart:typed_data';

import 'package:e3ks_desktop/features/preview/color_sampler.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// `!` مضمون: القيم أدناه مكتوبة بصيغة `#RRGGBB` صحيحة.
HexColor hex(String value) => HexColor.tryParse(value)!;

final white = hex('#FFFFFF');
final red = hex('#C00000');
final blue = hex('#1F4E79');

PixelGrid gridOf(int width, int height, int Function(int x, int y) at) {
  final bytes = ByteData(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final rgb = at(x, y);
      final offset = (y * width + x) * 4;
      bytes.setUint8(offset, (rgb >> 16) & 0xFF);
      bytes.setUint8(offset + 1, (rgb >> 8) & 0xFF);
      bytes.setUint8(offset + 2, rgb & 0xFF);
      bytes.setUint8(offset + 3, 0xFF);
    }
  }
  return PixelGrid(bytes: bytes, width: width, height: height);
}

void main() {
  final candidates = [white, red, blue];

  test('مساحة ممتلئة تُلتقط كما هي', () {
    final grid = gridOf(
      40,
      40,
      (x, y) => x >= 10 && x < 30 ? 0xC00000 : 0xFFFFFF,
    );

    expect(
      resolveColorAt(grid, 20, 20, candidates: candidates, background: white),
      equals(red),
    );
    expect(
      resolveColorAt(grid, 2, 20, candidates: candidates, background: white),
      equals(white),
    );
  });

  test('حافّة الحرف الممزوجة تُردّ إلى لون الحرف لا إلى الورق', () {
    // تنعيم الحواف يمزج اللونين، فبكسل الحافّة ليس أحمر ولا أبيض. الجوار
    // يحمل قلب الساق، ومنه يأتي الجواب — لا من الرقم الممزوج.
    final grid = gridOf(20, 20, (x, y) {
      if (x == 10) return 0xC00000; // قلب الساق
      if (x == 9 || x == 11) return 0xDF7F7F; // الحافّة الممزوجة
      return 0xFFFFFF;
    });

    expect(
      resolveColorAt(grid, 9, 10, candidates: candidates, background: white),
      equals(red),
      reason: 'الأقرب إلى الحافّة هو الحرف، والورق يخسر داخل الحلقة',
    );
  });

  test('البكسل البعيد عن كل لون معلَن لا يُخمَّن', () {
    final grid = gridOf(20, 20, (x, y) => 0x33AA55);

    expect(
      resolveColorAt(grid, 10, 10, candidates: candidates, background: white),
      isNull,
      reason: 'عجزٌ معلَن خيرٌ من لون مؤلَّف',
    );
  });

  test('أقرب حلقة تفوز: لونان متجاوران لا يختلطان', () {
    final grid = gridOf(40, 40, (x, y) => x < 20 ? 0x1F4E79 : 0xC00000);

    expect(
      resolveColorAt(grid, 5, 20, candidates: candidates, background: white),
      equals(blue),
    );
    expect(
      resolveColorAt(grid, 35, 20, candidates: candidates, background: white),
      equals(red),
    );
  });

  test('خارج الحدود وبلا مرشّحين: لا انهيار ولا نتيجة', () {
    final grid = gridOf(10, 10, (x, y) => 0xC00000);

    expect(
      resolveColorAt(grid, 500, 500, candidates: candidates, background: white),
      isNull,
    );
    expect(
      resolveColorAt(grid, 5, 5, candidates: const [], background: white),
      isNull,
    );
  });

  test('الشبكة تقرأ القناة الصحيحة', () {
    final grid = gridOf(4, 4, (x, y) => 0x102030);
    expect(grid.rgbAt(1, 1), equals(0x102030));
    expect(grid.rgbAt(-1, 0), isNull);
    expect(grid.rgbAt(0, 9), isNull);
  });
}
