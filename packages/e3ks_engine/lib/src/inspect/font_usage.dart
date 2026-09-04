/// استعمال خط واحد في المستند.
library;

import '../ooxml/part_classes.dart';

/// أي فتحة خط — العربية تُقرأ من [complexScript]، وإغفالها خطأ شائع (`02` §7).
enum FontSlot { ascii, highAnsi, complexScript, eastAsian, drawing }

final class FontUsage {
  const FontUsage({
    required this.name,
    required this.count,
    required this.bySlot,
    required this.byPart,
    required this.partClasses,
    required this.themeLinked,
  });

  /// اسم الخط كما ورد في الملف.
  final String name;

  final int count;
  final Map<FontSlot, int> bySlot;
  final Map<String, int> byPart;
  final Set<PartClass> partClasses;

  /// اقترن بسمة `*Theme` — تُحذف عند التبديل الصريح (`02` §7).
  final bool themeLinked;

  bool get isInContent => partClasses.contains(PartClass.content);

  /// خط أحادي العرض على الأرجح — يُستثنى افتراضًا لئلّا تنهار كتل الكود.
  ///
  /// ترجيح بالاسم لا يقين: أسماء الخطوط لا تُصرّح بذلك. لذلك هذه **توصية**
  /// تُعرَض على المستخدم في قائمة الحماية، لا استثناء يُفرض بصمت (`00` §5).
  bool get looksMonospaced {
    final n = name.toLowerCase();
    const hints = [
      'mono',
      'courier',
      'consol',
      'menlo',
      'code',
      'terminal',
      'typewriter',
      'fixedsys',
      'inconsolata',
      'hack',
      'source code',
    ];
    return hints.any(n.contains);
  }
}
