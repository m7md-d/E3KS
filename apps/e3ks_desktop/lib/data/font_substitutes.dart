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

import 'font_fetcher.dart';
import 'font_probe.dart';

/// **المقاسات مقيسة لا مدَّعاة.** قِسنا عرض كل محرف من ٧٣ محرفًا عند 100pt،
/// وعرض جملة كاملة، بين كل أصل وبديله — بالخطوط الحقيقية على macOS:
///
/// | الأصل ← البديل | أسوأ فرق |
/// |---|---|
/// | Arial ← Arimo | 0.000px |
/// | Georgia ← Gelasio | 0.000px |
/// | Calibri ← Carlito | 0.000px |
/// | Times New Roman ← Tinos | 0.000px |
/// | Courier New ← Cousine | 0.000px |
///
/// وشاهدٌ سالب يقول إن القياس يميّز: Arial ← Times New Roman يختلف في ٥٢
/// محرفًا من ٦٩، وأسوأ فرق 11.23px.

/// خطّ مملوك ← بديله المشحون معنا.
///
/// المفتاح بأحرف صغيرة: المستندات تكتب «CALIBRI» و«Calibri» و«calibri».
const Map<String, String> _bundled = {
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

/// خطّ مملوك ← بديل **يُجلب إلى جهاز المستخدم**، ولا يُشحن معنا.
///
/// **الفرق مسؤولية لا تقنية:** ما نشحنه نلتزم برخصته، وما يجلبه جهاز
/// المستخدم من قناة عامة شأنه هو. فهذه لا تزيد حجم الحزمة ولا تدخل شاشة
/// الرخص؛ تصل عند أول مستند يطلب أصلها ثم تبقى محفوظة على قرصه.
///
/// **ولماذا هذه بالذات:** Google تخدم Times New Roman و Courier New بأسمائها
/// (فيُجلب الأصل نفسه أوّلًا)، وتعجز عن Cambria و Segoe UI و Aptos — مقيسًا
/// بطلبها من `css2`. فالبديل هنا لمن هو خارج التغطية: بلا شبكة، أو على
/// نظامٍ لا يملك الخطّ.
const Map<String, String> _fetched = {
  'times new roman': 'Tinos',
  'times': 'Tinos',
  'liberation serif': 'Tinos',
  'courier new': 'Cousine',
  'liberation mono': 'Cousine',
  // **غير مقيس عندنا**: لا Cambria على جهاز التطوير ولا تخدمها Google،
  // فمقاسيّة Caladea قول ناشرها. تُقاس على أول جهاز فيه Cambria.
  'cambria': 'Caladea',
};

/// العائلة التي تُرسم بها المعاينة نيابةً عن [family].
///
/// **البديل ملاذٌ أخير لا اختصار.** الخطّ الحقيقي أدقّ من أي بديل، فإن كان
/// مضمَّنًا أو منصَّبًا على الجهاز أو مجلوبًا ومحمَّلًا رسمنا به. البديل لما
/// لم نجده: يمنع سقوط النصّ إلى خطّ الواجهة، ويحفظ التخطيط بتطابق المقاسات.
String previewFamily(String family) {
  final name = family.trim();
  if (isBundled(name) || isFontAvailable(name)) return name;
  return substituteFor(name) ?? name;
}

/// بديل هذه العائلة إن كان لها بديل — مشحونًا كان أو مجلوبًا.
///
/// **والاسم المجرَّد من لاحقة النمط يُجرَّب أيضًا**: «Calibri Light» بديلها
/// بديلُ Calibri، وبدونها يسقط أشهر خطوط العناوين في Word إلى خطّ التطبيق.
String? substituteFor(String family) {
  final key = family.trim().toLowerCase();
  final direct = _bundled[key] ?? _fetched[key];
  if (direct != null) return direct;

  final bare = familyWithoutStyleSuffix(family)?.toLowerCase();
  if (bare == null) return null;
  return _bundled[bare] ?? _fetched[bare];
}

/// بماذا سترسم المعاينة هذه العائلة **على هذا الجهاز**.
///
/// **الغرض ألّا تكذب المعاينة صامتة.** خطٌّ لا نملكه ولا بديل له يسقط إلى
/// خطّ التطبيق، فيرى المستخدم مستنده كلّه بخطّ واحد ويحسبه خطّه. والحكم
/// محلّي لأن الجواب محلّي: Geeza Pro على macOS خطّ نظام، وعلى ويندوز ولينكس
/// لا وجود له.
enum PreviewFit {
  /// الخطّ نفسه: مشحون معنا أو منصَّب أو محمَّل وقت التشغيل.
  real,

  /// بديل مطابق في المقاسات: التخطيط صحيح والحروف حروف غيره.
  substitute,

  /// لا هذا ولا ذاك: يُرسَم بخطّ التطبيق، والمعاينة تقريبية.
  fallback,
}

PreviewFit previewFit(String family) {
  final name = family.trim();
  if (isBundled(name) || isFontAvailable(name)) return PreviewFit.real;
  final stand = substituteFor(name);
  if (stand == null) return PreviewFit.fallback;
  // **البديل المجلوب لا يُوعَد به قبل وصوله.** الرقاقة تصف ما يُرسم الآن،
  // فبديلٌ لم يصل بعدُ سقوطٌ إلى خطّ التطبيق لا بديل مطابق.
  return isBundled(stand) || isFontAvailable(stand)
      ? PreviewFit.substitute
      : PreviewFit.fallback;
}

/// هل لهذه العائلة بديل؟ تستعمله الواجهة كي تقول للمستخدم إن ما يراه
/// بديلٌ مطابق مقاسيًّا لا الخطّ نفسه.
bool hasSubstitute(String family) => substituteFor(family) != null;

/// البدائل المشحونة معنا: تُعرض رخصها، ويحرسها الاختبار.
Set<String> get substituteFamilies => _bundled.values.toSet();

/// البدائل التي تُجلب ولا تُشحن — لا رخصة علينا فيها، ويحرس الاختبار
/// ألّا تتسرّب إلى الحزمة.
Set<String> get fetchedSubstituteFamilies => _fetched.values.toSet();

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
