/// تصنيف أجزاء المستند بحسب أثرها على ما يراه القارئ.
///
/// التصنيف ليس ترفًا تنظيميًا: هو أساس الفصل بين **ألوان الهوية الفعلية**
/// و**ضجيج ثيم Office الموروث** (`02` §6). لون لا يظهر إلا في `styles.xml`
/// غالبًا موروث من أنماط جداول افتراضية، ولون في `document.xml` قرار مصمّم.
library;

enum PartClass {
  /// ما يقرأه القارئ: المتن والترويسات والتذييلات والحواشي والتعليقات.
  content,

  /// تعريفات الأنماط — مصدر أغلب الألوان الموروثة.
  styles,

  /// القوائم والترقيم.
  numbering,

  /// لوحة الثيم.
  theme,

  /// جزء لا نفحصه.
  other,
}

/// يصنّف جزءًا في مستند Word، أو يُرجع [PartClass.other] لما لا يُفحَص.
///
/// الترويسات والتذييلات أجزاء منفصلة وكثيرًا ما تُنسى — `02` §8.
PartClass classifyDocxPart(String name) {
  if (!name.startsWith('word/') || !name.endsWith('.xml')) {
    return PartClass.other;
  }
  final leaf = name.substring('word/'.length);
  if (leaf.contains('/') && !leaf.startsWith('theme/')) return PartClass.other;

  if (leaf == 'document.xml' ||
      leaf == 'footnotes.xml' ||
      leaf == 'endnotes.xml' ||
      leaf == 'comments.xml' ||
      _numbered(leaf, 'header') ||
      _numbered(leaf, 'footer')) {
    return PartClass.content;
  }
  if (leaf == 'styles.xml') return PartClass.styles;
  if (leaf == 'numbering.xml') return PartClass.numbering;
  if (_numbered(
        leaf.startsWith('theme/') ? leaf.substring(6) : leaf,
        'theme',
      ) &&
      leaf.startsWith('theme/')) {
    return PartClass.theme;
  }
  return PartClass.other;
}

/// هل الاسم على صيغة `<prefix><رقم>.xml`، مثل `header1.xml`؟
bool _numbered(String leaf, String prefix) {
  if (!leaf.startsWith(prefix) || !leaf.endsWith('.xml')) return false;
  final digits = leaf.substring(prefix.length, leaf.length - 4);
  return digits.isNotEmpty && int.tryParse(digits) != null;
}

/// أجزاء Word التي يمرّ عليها الفحص والتحويل — `02` §8.
bool isInspectableDocxPart(String name) =>
    classifyDocxPart(name) != PartClass.other;
