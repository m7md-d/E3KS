/// حصيلة فحص مستند: كل لون وكل خط، بعدده وموضعه ودوره.
///
/// هذا التقرير هو ما يُغذّي «جدول الأثر» في الواجهة، وما يبني منه المستخدم
/// خريطة التبديل. المبدأ `00` §5: لا شيء يُخفى.
library;

import 'color_usage.dart';
import 'font_usage.dart';
import 'text_mark.dart';

final class InspectionReport {
  const InspectionReport({
    required this.colors,
    required this.fonts,
    required this.marks,
    required this.scannedParts,
  });

  /// كل الألوان، مرتّبة تنازليًا بعدد الاستعمال.
  final List<ColorUsage> colors;

  /// كل الخطوط، مرتّبة تنازليًا بعدد الاستعمال.
  final List<FontUsage> fonts;

  /// علامات النصّ: قلم التمييز وتظليل الخلفية، مرتّبة تنازليًا بعددها.
  ///
  /// **منفصلة عن الألوان لأن فعلها منفصل:** اللون يُبدَّل، والعلامة تُرفع.
  /// ولون التظليل يظهر في الجدولين معًا — في [colors] ليُبدَّل، وهنا ليُمسح.
  final List<MarkUsage> marks;

  /// الأجزاء التي مرّ عليها الفحص فعلًا.
  final List<String> scannedParts;

  /// ألوان يراها القارئ في المتن أو الترويسات أو التذييلات.
  /// هذه هي هوية المستند الفعلية، وهي التي تُعرَض أولًا.
  List<ColorUsage> get contentColors => [
    for (final c in colors)
      if (c.isInContent) c,
  ];

  /// ألوان لا تظهر إلا في تعريفات الأنماط والثيم — ضجيج Office الموروث غالبًا.
  /// تُعرَض مطويّة، لا مختلطة بالأولى (`02` §6).
  List<ColorUsage> get inheritedColors => [
    for (final c in colors)
      if (!c.isInContent) c,
  ];

  List<FontUsage> get contentFonts => [
    for (final f in fonts)
      if (f.isInContent) f,
  ];

  /// خطوط يُرجَّح أنها أحادية العرض — تُقترح للحماية، ولا تُستثنى بصمت (`02` §7).
  List<FontUsage> get monospacedCandidates => [
    for (final f in fonts)
      if (f.looksMonospaced) f,
  ];

  /// علامات يراها القارئ في المتن — وهي وحدها ما يعني المستخدم.
  List<MarkUsage> get contentMarks => [
    for (final m in marks)
      if (m.isInContent) m,
  ];

  int get totalColorOccurrences => colors.fold(0, (sum, c) => sum + c.count);

  int get totalFontOccurrences => fonts.fold(0, (sum, f) => sum + f.count);
}
