/// بدائل المعاينة للخطوط التي لا يجوز شحنها.
///
/// **المشكلة**: خطوط مثل Calibri و Georgia و Arial تملأ مستندات المستخدمين،
/// وكلّها مملوكة. Google تخدم أصولها المملوكة نفسها تحت أسمائها — قرأنا
/// جدول `name` داخل ما تُرسله فوجدنا حقوق مايكروسوفت ولينوتايب ونصًّا يقول
/// «You may not redistribute, copy, convert, modify or reverse engineer this
/// font». فلا شحنها جائز ولا حفظها على قرص المستخدم.
///
/// **الحلّ**: نشحن بديلًا **مطابقًا مقاسيًّا** برخصة OFL. تطابق المقاسات هو
/// الشرط: عرض المحرف وارتفاع السطر وموضع القطع كلّها تساوي الأصل، فالتخطيط
/// الذي تراه المعاينة هو التخطيط الذي سيخرج عند من يملك الخطّ الأصلي.
///
/// **والمستند لا يتغيّر.** الاسم الحقيقي وحده يُكتب في XML؛ الإحلال هنا
/// للرسم على الشاشة لا غير. مستند يطلب Calibri يظلّ يطلب Calibri.
///
/// **والبديل يُشحن باسمه.** Carlito تُسجَّل «Carlito» في `pubspec.yaml`، لا
/// «Calibri» — إخفاء ما نوزّعه خلف اسم غيره يخالف رخصته ويخفي الحقيقة عن
/// من يقرأ شاشة الرخص.
library;

import 'font_probe.dart';

/// خطّ مملوك ← بديله المضمَّن.
///
/// المفتاح بأحرف صغيرة: المستندات تكتب «CALIBRI» و«Calibri» و«calibri».
const Map<String, String> _substitutes = {
  // Arimo مطابق مقاسيًّا لـ Arial، وHelvetica تشارك Arial مقاساتها.
  'arial': 'Arimo',
  'helvetica': 'Arimo',
  'helvetica neue': 'Arimo',
  'liberation sans': 'Arimo',
  // Carlito مصنوع بديلًا مقاسيًّا لـ Calibri.
  'calibri': 'Carlito',
  // Gelasio مصنوع بديلًا مقاسيًّا لـ Georgia.
  'georgia': 'Gelasio',
};

/// العائلة التي تُرسم بها المعاينة نيابةً عن [family].
///
/// **البديل ملاذٌ أخير لا اختصار.** الخطّ الحقيقي أدقّ من أي بديل، فإن كان
/// مضمَّنًا أو منصَّبًا على الجهاز أو مجلوبًا ومحمَّلًا رسمنا به. البديل لما
/// لم نجده: يمنع سقوط النصّ إلى خطّ الواجهة، ويحفظ التخطيط بتطابق المقاسات.
String previewFamily(String family) {
  final name = family.trim();
  if (isBundled(name) || isFontAvailable(name)) return name;
  return _substitutes[name.toLowerCase()] ?? name;
}

/// هل لهذه العائلة بديل مضمَّن؟ تستعمله الواجهة كي تقول للمستخدم إن ما يراه
/// بديلٌ مطابق مقاسيًّا لا الخطّ نفسه.
bool hasSubstitute(String family) =>
    _substitutes.containsKey(family.trim().toLowerCase());

/// كل البدائل المضمَّنة، لعرضها في شاشة الرخص وللاختبارات.
Set<String> get substituteFamilies => _substitutes.values.toSet();

/// الخطوط المشحونة داخل الحزمة، كما هي مصرَّحة في `pubspec.yaml`.
///
/// مصدرها واحد هنا: `about.dart` يقرأ منها ملفّات الرخص، و`FontService`
/// يقرأ منها ما لا يحتاج شبكة. قائمتان تنحرفان فيَعِد التطبيق بخطٍّ لا يشحنه.
const List<String> bundledFamilies = [
  'IBM Plex Sans Arabic',
  'Noto Sans Arabic',
  'Cairo',
  'Tajawal',
  'IBM Plex Sans',
  'Inter',
  'Arimo',
  'Carlito',
  'Gelasio',
];

final Set<String> _bundledLower = {
  for (final f in bundledFamilies) f.toLowerCase(),
};

/// هل العائلة مشحونة معنا؟
bool isBundled(String family) =>
    _bundledLower.contains(family.trim().toLowerCase());
