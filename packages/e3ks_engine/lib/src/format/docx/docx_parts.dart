/// أجزاء Word: أيّها ملك الصيغة، وأيّها يُفحَص، وبأي صنف.
///
/// **الملكية أوسع من الفحص عمدًا:** نملك `word/` كلّه — بما فيه ما لا نفحصه
/// — كي يكون الحدّ مع الصيغ الأخرى حدًّا واضحًا لا استثناءات فيه.
library;

import '../../inspect/part_class.dart';

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

/// كل ما تحت `word/` ملك صيغة Word — حارس العزل في [DocumentFormat.owns].
///
/// `docProps/` و`_rels/` و`[Content_Types].xml` **ليست ملكًا لأحد**: الأولى
/// خارج مسار الستايل (`00` §2)، والأخريان تكتبهما الحاوية.
bool ownsDocxPart(String name) => name.startsWith('word/');
