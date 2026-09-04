/// حصيلة التحويل: ماذا تغيّر، وكم مرّة، وما الذي لم يُطابَق.
///
/// المبدأ `00` §5: الصمت ممنوع. خريطة لا تُطابق شيئًا خللٌ في الإعداد
/// يجب أن يعرفه المستخدم فورًا، لا أن يكتشفه بعد تسليم الملف.
library;

import '../inspect/hex_color.dart';

final class TransformReport {
  const TransformReport({
    required this.colorReplacements,
    required this.fontReplacements,
    required this.themeAttributesRemoved,
    required this.highlightsRemoved,
    required this.changedParts,
    required this.unmatchedColors,
    required this.preservedFonts,
  });

  /// عدد مرات استبدال كل لون فعليًا.
  final Map<HexColor, int> colorReplacements;

  /// عدد مرات استبدال كل خط، بالاسم القديم.
  final Map<String, int> fontReplacements;

  /// سمات ثيم حُذفت لئلّا تغلب على القيمة الصريحة (`02` §6 و§7).
  final int themeAttributesRemoved;

  final int highlightsRemoved;

  /// الأجزاء التي تغيّرت بايتاتها فعلًا. ما عداها نُسخ كما ورد.
  final List<String> changedParts;

  /// ألوان في الخطة لم يُعثر عليها في المستند — الخطة أو المستند خطأ.
  final Set<HexColor> unmatchedColors;

  /// خطوط تُركت عمدًا بحكم قائمة الحماية.
  final Map<String, int> preservedFonts;

  int get totalColorReplacements =>
      colorReplacements.values.fold(0, (a, b) => a + b);

  int get totalFontReplacements =>
      fontReplacements.values.fold(0, (a, b) => a + b);

  bool get changedNothing => changedParts.isEmpty;
}
