/// ترميز الكيانات كما يكتبها Word.
///
/// المحلّل القياسي يُخرج `>` حرفيًا، بينما يكتب Word `&gt;`. الاثنان صحيحان
/// دلاليًا (‏`>` لا يلزم تهريبه إلا في `]]>`)، لكن المطابقة الحرفية تمنحنا
/// ثابتًا أقوى بكثير:
///
/// > **جزء لم نغيّره دلاليًا يخرج مطابقًا بايتًا ببايت حتى بعد تحليله وإعادة
/// > تسلسله.**
///
/// وبهذا الثابت نُقرّر الكتابة بمقارنة البايتات لا بالنيّة، فتصير مجموعة
/// الأجزاء الممسوسة **أصغر ما يمكن إثباتًا** — وهذا صلب المبدأ `00` §١/١.
library;

import 'package:xml/xml.dart';

final class OoxmlEntityMapping extends XmlDefaultEntityMapping {
  const OoxmlEntityMapping() : super.xml();

  @override
  String encodeText(String input) =>
      // آمن بعد `super`: ما ينتجه من `&gt;` لا يحوي `>` حرفيًا.
      super.encodeText(input).replaceAll('>', '&gt;');
}

const OoxmlEntityMapping ooxmlEntities = OoxmlEntityMapping();

/// يسلسل مستندًا بترميز Word.
String serializeOoxml(XmlDocument document) =>
    document.toXmlString(entityMapping: ooxmlEntities);
