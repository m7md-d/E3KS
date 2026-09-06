/// علامة على النصّ نفسه: قلم تمييز أو تظليل خلفية.
///
/// **لماذا نوعٌ مستقلّ عن اللون.** اللون يُبدَّل بلونٍ آخر؛ والعلامة تُرفع.
/// وهذا فرقٌ يراه المستخدم قبل أن يراه الكود: من يفتح ملفًّا وصله من غيره
/// يريد أن يذهب أثر القلم، لا أن يصير أصفرَه أزرق.
///
/// **وثلاثة مواضع تُنتج المظهر نفسه:**
///
/// | الموضع | القيمة | ما يراه المستخدم |
/// |---|---|---|
/// | `w:highlight` | اسم ثابت (`yellow`) | قلم التمييز في Word |
/// | `w:shd` داخل `w:rPr` | لون حرّ | خلفية نصّ لا يرفعها قلم Word |
/// | `a:highlight` | لون حرّ | قلم التمييز في PowerPoint |
///
/// الثاني هو الذي يستعصي على المستخدم: قلم Word لا يرفعه لأنه ليس تمييزًا،
/// فيبقى ملتصقًا بالنصّ مهما اختار «بلا لون».
library;

import 'hex_color.dart';
import 'part_class.dart';

/// نوع العلامة. **بلا نصّ معروض** — التسمية شأن الواجهة (`01`).
enum MarkKind {
  /// قلم التمييز: `w:highlight` باسمه الثابت، و`a:highlight` بلونه.
  highlight,

  /// خلفية النصّ نفسه: `w:shd` داخل `w:rPr`.
  textShading,
}

/// علامة واحدة بمفتاحها.
///
/// المفتاح اسمٌ ثابت لقلم Word (`yellow`)، أو `#RRGGBB` لما سواه. توحيده في
/// سلسلة واحدة يجعل الخطة تُكتب وتُقرأ ويُوازَن عليها بلا تفريعٍ عند كل
/// مستدعٍ.
final class TextMark {
  const TextMark(this.kind, this.key);

  /// علامة تظليل من لونها.
  TextMark.shading(HexColor color)
    : kind = MarkKind.textShading,
      key = color.value;

  /// قلم تمييز بلونه — PowerPoint، فقلمه لا يحمل أسماء.
  TextMark.coloredPen(HexColor color)
    : kind = MarkKind.highlight,
      key = color.value;

  /// يقرأ علامة من نصّها كما يكتبها [toString] — `highlight:yellow`.
  ///
  /// **مشتركة بين المستدعين:** الخطة تُكتب في JSON على سطر الأوامر وتُقرأ
  /// هنا؛ قارئان اثنان ينحرفان، فيقبل أحدهما ما يرفضه الآخر.
  static TextMark? tryParse(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    final at = text.indexOf(':');
    if (at <= 0 || at == text.length - 1) return null;
    final kind = switch (text.substring(0, at)) {
      'highlight' => MarkKind.highlight,
      'textShading' => MarkKind.textShading,
      _ => null,
    };
    if (kind == null) return null;

    final key = text.substring(at + 1);
    // مفتاح اللون يُطبَّع كما يُطبَّع في المستند، فلا ينحرف `#d9d9d9` عن
    // `D9D9D9` ويصير علامتين لشيء واحد.
    final color = HexColor.tryParse(key);
    if (color != null) return TextMark(kind, color.value);
    return kind == MarkKind.highlight ? TextMark(kind, key) : null;
  }

  final MarkKind kind;
  final String key;

  /// لون العلامة كما يُرسَم.
  ///
  /// للقلم المسمّى يُقرأ من جدول المواصفة ([highlightPalette])، ولغيره من
  /// المفتاح نفسه. `null` لاسمٍ لا تعرفه المواصفة — فلا يُرسَم بتخمين.
  HexColor? get color =>
      HexColor.tryParse(highlightPalette[key.toLowerCase()] ?? key);

  @override
  bool operator ==(Object other) =>
      other is TextMark && other.kind == kind && other.key == key;

  @override
  int get hashCode => Object.hash(kind, key);

  @override
  String toString() => '${kind.name}:$key';
}

/// ألوان أسماء `w:highlight` كما تعرّفها المواصفة (ECMA-376، `ST_HighlightColor`).
///
/// **ليست لوحة هوية** فلا تخضع لـ`07`: هذه قيم يقرؤها المستند نفسه، شأنها
/// شأن أي `#RRGGBB` نقرؤه من ملفّ. اختراعُ لونٍ لها يجعل المعاينة تكذب على
/// المستخدم فيما سيراه في Word.
const Map<String, String> highlightPalette = {
  'black': '000000',
  'blue': '0000FF',
  'cyan': '00FFFF',
  'darkblue': '000080',
  'darkcyan': '008080',
  'darkgray': '808080',
  'darkgreen': '008000',
  'darkmagenta': '800080',
  'darkred': '800000',
  'darkyellow': '808000',
  'green': '00FF00',
  'lightgray': 'C0C0C0',
  'magenta': 'FF00FF',
  'red': 'FF0000',
  'white': 'FFFFFF',
  'yellow': 'FFFF00',
};

/// استعمال علامة واحدة في المستند: كم مرّة، وأين، وعلى أي نصّ.
///
/// الشكل نفسه الذي لـ`ColorUsage` عمدًا: الجدولان يُقرآن بالعين نفسها،
/// والعيّنة هي التي تجعل الرقم قرارًا (`00` §5).
final class MarkUsage {
  const MarkUsage({
    required this.mark,
    required this.count,
    required this.byPart,
    required this.partClasses,
    required this.samples,
  });

  final TextMark mark;

  /// عدد المواضع التي ظهرت فيها العلامة.
  final int count;

  final Map<String, int> byPart;

  final Set<PartClass> partClasses;

  /// عيّنات من النصّ المعلَّم. بلا عيّنة يصير الجدول أرقامًا صمّاء.
  final List<String> samples;

  /// هل يراها القارئ في المتن، أم هي في تعريف نمطٍ لا يظهر؟
  bool get isInContent => partClasses.contains(PartClass.content);
}
