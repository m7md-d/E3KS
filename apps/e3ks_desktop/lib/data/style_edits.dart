/// تعديلات تنسيق: ألوان، وخطّان، وحماية، وعلامات مرفوعة.
///
/// **يُستعمل طبقتين** ([`ADR 0005`](../../../../docs/adr/0005-مجموعة-العمل.md)):
/// طبقةً **عامّة** تسري على كل ملفات المجموعة، وطبقةً **خاصّة** لكل ملف.
/// والشكل واحد لأن ما يُكتب في الأولى هو ما يُكتب في الثانية — وتكرار
/// الحقلين بصنفين ينحرف أحدهما عن الآخر عند أول إضافة.
library;

import 'package:e3ks_engine/e3ks_engine.dart';

/// قيمة تبديل لون في طبقة.
///
/// **و`null` هنا ليست غيابًا بل قولًا.** الملفّ قد يريد استثناء لونٍ من
/// قاعدةٍ عامّة تشمله: «هذا اللون يبقى كما هو». وغيابُ المفتاح يعني
/// «لا رأي لي، فلتسرِ العامّة» — والفرق بينهما هو ما يجعل الطبقتين تعملان.
typedef ColorOverride = HexColor?;

final class StyleEdits {
  final Map<HexColor, ColorOverride> colors = {};
  final Set<String> preserveFonts = {};

  /// علامات النصّ المطلوب رفعها.
  ///
  /// **تعمّ داخل المجموعة ولا تدخل ملفّ الهوية** (`02` §5/1): مفتاحها نوعٌ
  /// وقيمة (`highlight:yellow`) لا موضعٌ في ملف، فالعموم فيها معنًى؛ أمّا
  /// الهوية فتصف ألوانًا وخطوطًا، وأثرُ لصقٍ لا يوصف فيها.
  final Set<TextMark> liftedMarks = {};

  String? latinFont;
  String? arabicFont;

  bool get isEmpty =>
      colors.isEmpty &&
      liftedMarks.isEmpty &&
      latinFont == null &&
      arabicFont == null &&
      preserveFonts.isEmpty;

  /// عدد ما قرّره المستخدم هنا. **الاستثناء الصريح قرارٌ يُعدّ**: من قال
  /// «هذا اللون يبقى» فعل شيئًا، وإخفاؤه يجعل العدّاد يكذب.
  int get decisions =>
      colors.length +
      liftedMarks.length +
      (latinFont != null ? 1 : 0) +
      (arabicFont != null ? 1 : 0);

  void clear() {
    colors.clear();
    liftedMarks.clear();
    preserveFonts.clear();
    latinFont = null;
    arabicFont = null;
  }
}

/// يدمج الطبقة العامّة مع الخاصّة في خطّةٍ واحدة تُطبَّق.
///
/// **الصريح يسبق الترجيح** — نفس منطق `map` في الهوية (`05`): ما قرّره
/// المستخدم لهذا الملفّ يفوز على القاعدة العامّة دائمًا. وبه يخرج الملفّ
/// الحادي والأربعون مطابقًا لما خرج به الأربعون قبله.
///
/// و[general] فارغة تعني ملفًّا **مقفلًا**: لا تسري عليه القواعد العامّة،
/// ويبقى على ما قرّره له صاحبه وحده.
StylePlan resolvePlan(StyleEdits? general, StyleEdits own) {
  final colors = <HexColor, HexColor>{};
  for (final entry
      in general?.colors.entries ??
          const <MapEntry<HexColor, ColorOverride>>[]) {
    if (entry.value != null) colors[entry.key] = entry.value!;
  }
  for (final entry in own.colors.entries) {
    // القيمة `null` استثناءٌ صريح: تُزيل ما وضعته العامّة ولا تضع بديلًا.
    if (entry.value == null) {
      colors.remove(entry.key);
    } else {
      colors[entry.key] = entry.value!;
    }
  }

  return StylePlan(
    colors: colors,
    fonts: FontPlan(
      latin: own.latinFont ?? general?.latinFont,
      arabic: own.arabicFont ?? general?.arabicFont,
    ),
    preserveFonts: {...?general?.preserveFonts, ...own.preserveFonts},
    removeMarks: {...?general?.liftedMarks, ...own.liftedMarks},
  );
}
