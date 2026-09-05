/// مقاسات إطار النافذة المخصّص — **مقيسةً من النظام لا مفترَضة**.
///
/// التطبيق يمدّ محتواه تحت شريط العنوان ويُخفي عنوانه، وتبقى أزرار النافذة
/// أزرارَ النظام في موضعها. والموضع ليس ثابتًا: على نظام بلغة عربية ينقلها
/// macOS إلى اليمين.
///
/// **ولغة النظام غير لغة التطبيق**، فلا يصحّ أن نستنتج الجهة من اتجاه
/// الواجهة. نسأل النظام ونحجز حيث قال.
library;

import 'package:flutter/services.dart';

// e3ks:not-ui — اسم قناة لا نصّ معروض.
const MethodChannel _channel = MethodChannel('e3ks/window');

/// ما يجب أن يخلو من محتوى التطبيق، بالبكسل المنطقي.
typedef WindowFrame = ({
  double titlebarHeight,
  double reserveLeft,
  double reserveRight,
});

/// إطار بلا حجز: منصّة بلا شريط مخصّص، أو بيئة اختبار.
const WindowFrame flatWindowFrame = (
  titlebarHeight: 0,
  reserveLeft: 0,
  reserveRight: 0,
);

Future<WindowFrame> readWindowFrame() async {
  try {
    final metrics = await _channel.invokeMapMethod<String, double>('metrics');
    if (metrics == null) return flatWindowFrame;
    return (
      titlebarHeight: metrics['titlebarHeight'] ?? 0,
      reserveLeft: metrics['reserveLeft'] ?? 0,
      reserveRight: metrics['reserveRight'] ?? 0,
    );
  } on MissingPluginException {
    // لا قناة: الاختبارات ومنصّات لم يُكتب لها إطار بعد. نرسم بلا حجز.
    return flatWindowFrame;
  } on PlatformException {
    // النافذة لم تُهيّأ بعد. الحجز صفرًا أهون من نافذة لا تُرسم.
    return flatWindowFrame;
  }
}
