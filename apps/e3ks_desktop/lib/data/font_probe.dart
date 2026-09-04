/// هل الخطّ متاح للرسم فعلًا؟
///
/// لا تملك Flutter واجهةً تسأل «هل هذه العائلة موجودة؟». فنقيس: نرسم نصًّا
/// بالعائلة المطلوبة وبعائلة لا وجود لها قطعًا. تطابق المقاسات يعني أن
/// المطلوبة سقطت إلى الخطّ الافتراضي — أي أنها غير متاحة.
///
/// الطريقة كلاسيكية ومجرَّبة، وتعمل بلا شبكة وبلا امتياز نظام.
library;

import 'package:flutter/painting.dart';

/// عائلة يستحيل وجودها — مرجع «الخطّ الافتراضي».
const String _sentinel = '__e3ks_missing_family__';

/// نصّ يخلط العربية واللاتينية والأرقام كي يظهر الفرق في المقاس.
///
/// **لا يُعرَض قطّ** — يُقاس عرضه ثم يُرمى. لذلك لا يدخل ملفّات الترجمة،
/// وعليه علامة الاستثناء الصريحة.
const String _specimen = 'المحتوى Wgq 8§'; // e3ks:not-ui

final Map<String, bool> _memo = {};

double _width(String family) {
  final painter = TextPainter(
    text: TextSpan(
      text: _specimen,
      style: TextStyle(fontFamily: family, fontSize: 96),
    ),
    textDirection: TextDirection.rtl,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// يُرجع `true` إن كان الخطّ مرسومًا بعائلته الحقيقية.
bool isFontAvailable(String family) {
  final name = family.trim();
  if (name.isEmpty) return false;
  return _memo.putIfAbsent(name, () {
    final fallback = _width(_sentinel);
    final actual = _width(name);
    // فرق ولو بجزء من البكسل يكفي: الخطوط لا تتطابق مقاساتها صدفةً.
    return (actual - fallback).abs() > 0.5;
  });
}

/// يُنسى ما حُفظ بعد تحميل خطٍّ جديد وقت التشغيل.
void forgetFontProbe([String? family]) {
  if (family == null) {
    _memo.clear();
  } else {
    _memo.remove(family.trim());
  }
}
