/// خطٌّ يحمله المستند نفسه.
///
/// **أصدق مصادر المعاينة**: لا شبكة، ولا بديل، ولا خطّ نظام قريب — الحروف
/// حروف كاتب المستند. ‏OOXML يسمح بتضمين الخطوط، ويشوّش ملفّاتها بمفتاح
/// معلَن بجوارها (`w:fontKey`)، فيُفكّ عند القراءة.
///
/// **ولا يُحفَظ على القرص.** المضمَّن حقّ هذا المستند: يُحمَّل في الذاكرة
/// لرسم معاينته، ويذهب بذهابه.
library;

import 'dart:typed_data';

/// وجه الخطّ كما يعلنه `fontTable.xml`.
enum FontFace { regular, bold, italic, boldItalic }

final class EmbeddedFont {
  const EmbeddedFont({
    required this.family,
    required this.face,
    required this.bytes,
    required this.subsetted,
  });

  /// اسم العائلة كما كتبه المستند — به يُطابَق طلب النصّ.
  final String family;
  final FontFace face;

  /// بايتات الخطّ بعد فكّ التشويش، بتوقيعٍ مُتحقَّق منه.
  final Uint8List bytes;

  /// جزءٌ من الخطّ يكفي محارف هذا المستند وحده.
  ///
  /// **يُقال ولا يُخفى**: نصٌّ جديد يُكتب بحروفٍ ليست فيه يخرج مربّعات، وهذا
  /// حدُّ ما ضمّنه صاحب المستند لا عجزٌ عندنا.
  final bool subsetted;
}
