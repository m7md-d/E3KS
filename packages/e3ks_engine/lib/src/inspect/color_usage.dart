/// استعمال لون واحد في المستند: كم مرّة، وأين، وبأي دور، وعلى أي نصّ.
library;

import 'part_class.dart';
import 'hex_color.dart';

/// دور اللون — أين يقع بصريًا. الدور هو ما يجعل جدول الأثر مفهومًا:
/// «هذا لون نصّ» غير «هذا خلفية خلية». التسمية المعروضة شأن الواجهة (`01`).
enum ColorRole {
  text,
  paragraphFill,
  cellFill,
  rowFill,
  tableFill,
  runFill,
  shadingPattern,
  border,

  /// تعبئة شكل على شريحة — أكثر أدوار اللون ظهورًا في العروض التقديمية.
  shapeFill,

  pageBackground,
  graphics,
  themePalette,
  other,
}

final class ColorUsage {
  const ColorUsage({
    required this.color,
    required this.count,
    required this.byRole,
    required this.byPart,
    required this.partClasses,
    required this.themeLinked,
    required this.samples,
  });

  final HexColor color;

  /// عدد المواضع التي ظهر فيها اللون.
  final int count;

  final Map<ColorRole, int> byRole;

  /// كم مرّة في كل جزء — يُظهر للمستخدم أن اللون في الترويسة مثلًا.
  final Map<String, int> byPart;

  final Set<PartClass> partClasses;

  /// ظهر مرّة واحدة على الأقل مقترنًا بسمة ثيم (`themeColor`/`themeFill`).
  /// إشارة إلى أن التبديل الصريح يستلزم حذف سمة الثيم — `02` §6.
  final bool themeLinked;

  /// عيّنات من النصّ الذي طُبّق عليه اللون. بلا عيّنة يصير الجدول أرقامًا صمّاء.
  final List<String> samples;

  /// هل يراه القارئ فعلًا، أم هو موروث من تعريفات الأنماط؟
  ///
  /// هذا هو الفصل الذي يمنع إغراق المستخدم بعشرات ألوان ثيم Office — `02` §6.
  bool get isInContent => partClasses.contains(PartClass.content);

  ColorRole get dominantRole {
    if (byRole.isEmpty) return ColorRole.other;
    return byRole.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}
