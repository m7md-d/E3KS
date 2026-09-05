/// تحويل الأرقام الهندية إلى عربية غربية.
///
/// **لماذا نحتاجه أصلًا:** الواجهة العربية تعرض الأرقام هندية (‏١٢٣) لأن
/// `intl` يصوغها بلغة المستخدم. فمن يقرأ «صفحة ١٢» يكتب «١٢» ليقفز إليها —
/// وهذا هو الصواب منه. رفضُ ما عرضناه نحن عليه عيبٌ فينا لا فيه.
///
/// نغطّي مجموعتين: العربية-الهندية (‏٠-٩ ‏U+0660) والفارسية الممتدّة
/// (‏۰-۹ ‏U+06F0) — الثانية تأتي من لوحات مفاتيح فارسية وأردية شائعة.
library;

/// أول محرف في كل مجموعة أرقام نقبلها.
const int _arabicIndicZero = 0x0660;
const int _extendedIndicZero = 0x06F0;
const int _asciiZero = 0x30;

/// يحوّل كل رقم هندي في [input] إلى نظيره الغربي، ويترك ما عداه كما هو.
String toWesternDigits(String input) {
  final buffer = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= _arabicIndicZero && unit <= _arabicIndicZero + 9) {
      buffer.writeCharCode(_asciiZero + unit - _arabicIndicZero);
    } else if (unit >= _extendedIndicZero && unit <= _extendedIndicZero + 9) {
      buffer.writeCharCode(_asciiZero + unit - _extendedIndicZero);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// يقرأ عددًا صحيحًا مكتوبًا بأي من المجموعتين.
///
/// يُرجع `null` لما ليس عددًا — **ولا يخمّن**: نصٌّ فيه رقم وحرف ليس رقمًا
/// ناقصًا بل مدخَلًا خاطئًا، وقبوله يُقفز بالمستخدم إلى صفحة لم يقصدها.
int? parseFlexibleInt(String input) {
  final normalized = toWesternDigits(input).trim();
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}
