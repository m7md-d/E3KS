/// **مرجع الحقيقة الواحد للألوان.**
///
/// لا لون في هذا التطبيق يُكتب خارج هذا الملف. لا في ودجة، ولا في ثيم،
/// ولا في رسّام. مغطّى باختبار يمسح `lib/` ويرفض أي قيمة لون خارجه.
///
/// **لماذا هذا الصرامة بالذات؟** لأن منتجنا نفسه يوحّد ألوان المستندات.
/// أداةٌ تفرّق ألوانها في عشرين ملفًا لا تُصدَّق حين تَعِد بتوحيد ألوان غيرها.
///
/// والخطّ كذلك: [Type] مرجعه الوحيد، ولا اسم خطّ ولا وزن يُكتب في ودجة.
///
/// نطاقات منفصلة **لا تختلط**:
///   [Type]   الخطّ المعتمد وأوزانه.
///   [Shade]  سطح التطبيق — داكن، ولمسة المرآة السماوية.
///   [Paper]  سطح المستند المعروض — أبيض دائمًا، لا يتبع ثيم التطبيق.
///   [Brand]  الرمز — انظر `brand/README.md`، ومطابقته مضمونة باختبار.
///   [Motion] الحركة — أزمنتها ومنحنياتها. لا رقم زمن في ودجة.
library;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// الخطّ المعتمد وأوزانه.
///
/// **IBM Plex Sans Arabic**، مضمَّن في التطبيق لا مطلوب من نظام المستخدم:
/// خطٌّ يعتمد على التنصيب يجعل البرنامج يبدو مختلفًا على كل جهاز — وهذا
/// عيبٌ في أداةٍ تبيع الاتساق البصري.
///
/// يرسم العربية واللاتينية معًا بعائلة واحدة، فلا ينكسر السطر المختلط.
abstract final class Type {
  /// اسم العائلة كما هو مصرَّح في `pubspec.yaml`. لا يُكتب في ودجة.
  static const family = 'IBM Plex Sans Arabic';

  /// احتياطي النظام إن تعذّر تحميل الأصل لأي سبب.
  static const fallback = <String>['SF Arabic', 'Geeza Pro'];

  /// الأوزان المضمَّنة. طلب وزن غير مضمَّن يجعل Flutter يصطنعه فيبهت.
  static const display = FontWeight.w200; // الشعار وحده
  static const regular = FontWeight.w400;
  static const semiBold = FontWeight.w600; // العناوين والأزرار
  static const bold = FontWeight.w700; // التوكيد داخل النصّ
}

/// ألوان واجهة التطبيق.
abstract final class Shade {
  /// شفّاف تامّ — طرف تدرّج الانعكاس في الشعار.
  static const transparent = Color(0x00000000);

  /// حجاب ما خلف الحوار: داكن بما يكفي ليعزل، شفّاف بما يبقي السياق مرئيًّا.
  static const scrim = Color(0x9904090B);

  /// خلفية النافذة — شبه أسود بميل أزرق، لا رمادي ميّت.
  static const canvas = Color(0xFF0B1013);

  /// أسطح مرتفعة: اللوحات والبطاقات.
  static const surface = Color(0xFF121A1F);
  static const surfaceHigh = Color(0xFF18232A);
  static const surfaceHover = Color(0xFF1E2B33);

  static const border = Color(0xFF243239);
  static const borderStrong = Color(0xFF33454F);

  static const text = Color(0xFFE6EDF1);
  static const textMuted = Color(0xFF93A6B1);
  static const textFaint = Color(0xFF5F7480);

  /// السماوي — لون المرآة. الفعل والتحديد والأثر، ولا يُبعثر.
  static const mirror = Color(0xFF4FD6E8);
  static const mirrorSoft = Color(0xFF2A98A8);
  static const mirrorDeep = Color(0xFF12414A);

  /// النصّ فوق السماوي. تباينه معه 12.6:1.
  static const onMirror = Color(0xFF04191D);

  static const success = Color(0xFF56D9A3);
  static const warning = Color(0xFFE8B84F);
  static const danger = Color(0xFFF07A7A);
}

/// ألوان رسم المستند في المعاينة.
///
/// **لا تتبع ثيم التطبيق ولا يجوز أن تتبعه.** الورقة بيضاء لأن ورقة Word
/// بيضاء؛ عرضها داكنة يجعل المعاينة كذبًا. وما عدا ألوان المستند نفسه
/// (تأتي من المحرّك) فهو من هنا.
abstract final class Paper {
  /// الورقة. بيضاء دائمًا.
  static const sheet = Color(0xFFFFFFFF);

  /// حبر النصّ حين لا يصرّح المستند بلون.
  static const ink = Color(0xFF1A1A1A);

  /// أرقام الفقرات في الهامش — حاضرة ولا تزاحم النصّ.
  static const gutter = Color(0xFFB2BCC3);

  /// حدود الجداول وفواصل الأقسام.
  static const rule = Color(0xFFD8DDE1);

  static const shadow = Color(0x66000000);
}

/// ألوان الرمز في `brand/`.
///
/// مذكورة هنا **ومطابقتها لملفات SVG مضمونة باختبار** — فالمرجع الواحد
/// يعبر حدود اللغات، ولا يبقى وعدًا في ملف توثيق.
abstract final class Brand {
  /// حبر الرمز = خلفية التطبيق. سوادٌ واحد في المنتج كلّه، لا اثنان متقاربان.
  static const ink = Shade.canvas;

  /// ورق الرمز. ليس أبيض نقيًّا: الرمز علامة لا مستند.
  static const paper = Color(0xFFF5F8F9);

  /// سماوي الرمز = سماوي الواجهة. هو الرابط بين الأيقونة والتطبيق.
  static const mirror = Shade.mirror;
}

/// أطراف فضاء الألوان في منتقي الألوان.
///
/// قيم رياضية لا اختيارات تصميمية: مكعّب HSV يبدأ عند الأبيض وينتهي عند
/// الأسود. تسكن هنا كي تبقى القاعدة بلا استثناء.
abstract final class Picker {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const cursor = Color(0xFFFFFFFF);
  static const cursorRing = Color(0x44000000);
  static const transparent = Color(0x00000000);
}

/// **مرجع الحقيقة الواحد للحركة.**
///
/// لا `Duration` ولا `Curve` يُؤلَّف في ودجة. الحركة لغةٌ كالألوان: أزمنة
/// متناثرة (120 هنا و130 هناك و160 ثالثة) تُنتج واجهةً تبدو مصنوعة على
/// دفعات — والعين تلتقط ذلك قبل أن يسمّيه صاحبها.
///
/// **المبدأ الحاكم: الحركة تشرح ولا تستعرض.** كل حركة هنا تجيب سؤالًا واحدًا
/// عند المستخدم — «من أين جاء هذا؟» أو «ما الذي تغيّر؟». الحركة التي لا
/// تجيب سؤالًا زينةٌ تُبطئ العمل، ويشيخ ظرفها بعد الأسبوع الأول.
///
/// ولذلك **الأزمنة قصيرة**: أطولها [entrance] وهي تقع مرّة واحدة عند الفتح.
/// أداةٌ مكتبية تُستعمل ساعات، والحركة الطويلة فيها ضريبة تُدفع كل مرّة.
abstract final class Motion {
  /// تغيّر حالة فوري تقريبًا: تظليل، وتحديد، وحدّ يظهر. أقصر من أن يُلاحَظ
  /// وأطول من أن يقفز.
  static const Duration instant = Duration(milliseconds: 90);

  /// الاستجابة القياسية للمس: زرّ، ومفتاح، ومبدّل «قبل/بعد».
  static const Duration quick = Duration(milliseconds: 140);

  /// انتقال عنصر أو ظهور لوحة: قائمة منسدلة، حوار، تبويب.
  static const Duration normal = Duration(milliseconds: 220);

  /// انتقال مساحة كبيرة: صفحة كاملة، أو تمرير موجَّه إلى صفحة بعيدة.
  static const Duration slow = Duration(milliseconds: 320);

  /// دخول التطبيق مرّة واحدة. الوحيدة التي يُسمح لها أن تُلاحَظ.
  static const Duration entrance = Duration(milliseconds: 420);

  /// فارق بدء العناصر المتتابعة. يوحي بالترتيب دون أن يؤخّر آخرها.
  ///
  /// ٥ عناصر × 55ms = 275ms قبل بدء الأخير — لا يزال تحت عتبة الانتظار.
  static const Duration stagger = Duration(milliseconds: 55);

  /// المنحنى الافتراضي: يبدأ سريعًا ويستقرّ. مناسب لما **يدخل** المشهد.
  static const Curve enter = Curves.easeOutCubic;

  /// لما **يخرج** من المشهد: يتسارع مغادرًا فلا يُبطئ المستخدم.
  static const Curve exit = Curves.easeInCubic;

  /// لتغيّر في مكانه: لون، أو حجم، أو حدّ. متماثل الطرفين.
  static const Curve standard = Curves.easeInOut;

  /// حركة تحمل مسافة كبيرة: تبدأ ببطء وتنتهي بحسم. تُستعمل بحساب.
  static const Curve emphasized = Curves.easeOutQuart;

  /// مهلة ظهور التلميح. أطول من الحركات لأنها **انتظار مقصود**: تلميح
  /// يظهر فور المرور يقفز في وجه من يمرّ مارًّا لا سائلًا.
  static const Duration tooltipDelay = Duration(milliseconds: 400);

  /// مسافة الانزلاق عند الدخول، بالبكسل المنطقي.
  ///
  /// صغيرة عمدًا: الانزلاق يدلّ على الاتجاه، ولا يُقطع مسافة تُشاهَد.
  static const double slideIn = 12;
}
