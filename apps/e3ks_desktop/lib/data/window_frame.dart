/// مقاسات إطار النافذة المخصّص — **مقيسةً من النظام لا مفترَضة**.
///
/// التطبيق يمدّ محتواه تحت شريط العنوان ويُخفي عنوانه، وتبقى أزرار النافذة
/// أزرارَ النظام في موضعها. والموضع ليس ثابتًا: على نظام بلغة عربية ينقلها
/// macOS إلى اليمين.
///
/// **ولغة النظام غير لغة التطبيق**، فلا يصحّ أن نستنتج الجهة من اتجاه
/// الواجهة. نسأل النظام ونحجز حيث قال.
///
/// **والمقاس ليس ثابتًا بعد الإقلاع.** ملء الشاشة على macOS يُخفي أزرار
/// النظام، فيصير الحجز الذي كان يفتح لها الطريق فراغًا بلا شاغل. فالنظام
/// يدفع القياس الجديد متى تغيّر، و[WindowFrameWatch] تحمله إلى الواجهة.
library;

import 'package:flutter/foundation.dart';
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

/// يقرأ القياس من الجهة الأصلية مرّةً واحدة.
Future<WindowFrame> readWindowFrame() async {
  try {
    return _frameFrom(
      await _channel.invokeMapMethod<String, double>('metrics'),
    );
  } on MissingPluginException {
    // لا قناة: الاختبارات ومنصّات لم يُكتب لها إطار بعد. نرسم بلا حجز.
    return flatWindowFrame;
  } on PlatformException {
    // النافذة لم تُهيّأ بعد. الحجز صفرًا أهون من نافذة لا تُرسم.
    return flatWindowFrame;
  }
}

/// قراءة القياس كما يصل من الجهة الأصلية.
///
/// مفتاح ناقص يُقرأ صفرًا: نافذةٌ بلا حجز أهون من نافذة لا تُرسم.
WindowFrame _frameFrom(Map<Object?, Object?>? metrics) {
  if (metrics == null) return flatWindowFrame;
  double at(String key) => (metrics[key] as num?)?.toDouble() ?? 0;
  return (
    titlebarHeight: at('titlebarHeight'),
    reserveLeft: at('reserveLeft'),
    reserveRight: at('reserveRight'),
  );
}

/// الإطار الحالي، يتغيّر حين يغيّره النظام.
///
/// **الدفع من النظام لا السؤال المتكرّر.** استطلاعٌ كل إطار يقيس ما لا
/// يتغيّر في أغلب الأوقات؛ والنظام يعرف لحظة التغيّر ويخبرنا بها.
final class WindowFrameWatch extends ValueNotifier<WindowFrame> {
  WindowFrameWatch() : super(flatWindowFrame);

  /// يصغي لما يدفعه النظام، ثم يقرأ القياس الأول.
  Future<void> start() async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'metrics') {
        value = _frameFrom(call.arguments as Map<Object?, Object?>?);
      }
      return null;
    });
    value = await readWindowFrame();
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }
}
