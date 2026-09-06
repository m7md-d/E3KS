/// خطة التبديل: ماذا يُستبدل بماذا.
///
/// المبدأ `00` §3: لا قيم مُصلَّبة في الكود. الخطة تأتي من إعداد يبنيه
/// المستخدم، والمحرّك لا يعرف أي لون ولا أي خط سلفًا.
library;

import '../inspect/hex_color.dart';
import '../inspect/text_mark.dart';

/// الخطوط المطلوبة لكل فتحة. `null` يعني «لا تلمس هذه الفتحة».
///
/// الفصل بين اللاتيني والعربي مقصود: توحيدهما في اسم واحد يكسر أحدهما غالبًا،
/// والعربية تُقرأ من فتحة `cs` لا من `ascii` (`02` §7).
final class FontPlan {
  const FontPlan({String? latin, String? arabic, String? eastAsian})
    : _latin = latin,
      _arabic = arabic,
      _eastAsian = eastAsian;

  final String? _latin;
  final String? _arabic;
  final String? _eastAsian;

  String? get latin => _named(_latin);
  String? get arabic => _named(_arabic);
  String? get eastAsian => _named(_eastAsian);

  /// اسمٌ فارغ أو مسافات = «لا تلمس»، لا «امسح الاسم».
  ///
  /// **هذا حارس المخرَج:** المحوّل لا يلمس خانة فارغة أصلًا، والطريق الوحيد
  /// إلى كتابة `typeface=""` خطةٌ تحمل اسمًا فارغًا. وخانة بلا اسم تُسقط
  /// النصّ إلى خطّ افتراضي بلا إشعار.
  static String? _named(String? value) {
    final name = value?.trim();
    return (name == null || name.isEmpty) ? null : name;
  }

  bool get isEmpty => latin == null && arabic == null && eastAsian == null;
}

final class StylePlan {
  const StylePlan({
    this.colors = const {},
    this.fonts,
    this.preserveFonts = const {},
    this.removeMarks = const {},
    this.removeHighlight = false,
    this.removeTextShading = false,
  });

  /// من لون إلى لون. ما ليس في الخريطة يبقى كما هو ويُذكر في التقرير (`00` §5).
  final Map<HexColor, HexColor> colors;

  final FontPlan? fonts;

  /// خطوط لا تُبدَّل مهما كانت الخطة — كتل الكود والجداول التقنية (`02` §7).
  /// المقارنة بلا حساسية لحالة الأحرف.
  final Set<String> preserveFonts;

  /// علاماتٌ بعينها تُرفع عن النصّ — بمفاتيحها كما يعلنها المستند.
  final Set<TextMark> removeMarks;

  /// كل قلم تمييز مهما كان اسمه أو لونه.
  ///
  /// **الرايتان لازمتان مع [removeMarks]:** الدفعة تطبّق خطةً واحدة على
  /// ملفات لا تُعرف علاماتها سلفًا، فلا يمكن تعدادها في مجموعة.
  final bool removeHighlight;

  /// كل تظليل خلفية على نصّ، مهما كان لونه.
  final bool removeTextShading;

  bool get isEmpty =>
      colors.isEmpty &&
      (fonts?.isEmpty ?? true) &&
      removeMarks.isEmpty &&
      !removeHighlight &&
      !removeTextShading;

  /// هل ترفع هذه الخطة هذه العلامة؟
  bool removes(TextMark mark) => switch (mark.kind) {
    MarkKind.highlight => removeHighlight || removeMarks.contains(mark),
    MarkKind.textShading => removeTextShading || removeMarks.contains(mark),
  };

  bool preserves(String fontName) {
    final needle = fontName.toLowerCase();
    return preserveFonts.any((f) => f.toLowerCase() == needle);
  }
}
