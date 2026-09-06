/// استخراج هوية من مستند مفتوح.
///
/// **الحاجة:** المستخدم يفتح ملفًّا يحمل الهوية التي يريدها، ولا يريد أن
/// يكتب أرقامها السداسية واحدًا واحدًا. نقرؤها له مرتَّبةً ومسمّاة.
///
/// **الترتيب أولًا، والتسمية إن أمكن.** الترتيب بكثرة الاستعمال حقيقةٌ
/// مقيسة لا تخمين. أمّا التسمية فترجيح: «لون النصّ» لأكثر ألوان النصّ
/// استعمالًا، و«الخلفية» لأكثر ألوان التعبئة. وما لم يُرجَّح يبقى بترتيبه
/// مسمّى بوصفه اللوني — اسمٌ مخترَع أسوأ من رقم صادق (`00` §5).
library;

import 'package:e3ks_engine/e3ks_engine.dart';

import 'document_loader.dart';
import 'identity.dart';

/// التسميات المرجَّحة، مترجَمةً. تأتي من الواجهة لأن `data/` لا يعرف لغة.
typedef IdentityLabels = ({
  String primary,
  String text,
  String background,
  String accent,
});

/// أقصى عدد ألوان في الهوية المستخرَجة.
///
/// هوية يقرؤها إنسان لا جدولُ كل لون في الملف. ما بعد الثامن ذيلٌ طويل من
/// ألوان تظهر مرّة أو مرّتين.
const int _maxColors = 8;

/// حدّ اعتبار اللون هويةً لا صدفة.
const int _minOccurrences = 2;

/// يستخرج هوية من مستند مفتوح: ألوانه مرتّبةً ومسمّاة، وخطّاه.
Identity extractIdentity(
  LoadedDocument document, {
  required String name,
  required IdentityLabels labels,
}) {
  final colors = document.report.contentColors
      .where((c) => c.count >= _minOccurrences)
      .take(_maxColors)
      .toList();

  // أكثر ألوان النصّ وأكثر ألوان التعبئة — مرشّحان للتسمية.
  ColorUsage? firstWhereRole(bool Function(ColorRole) matches) {
    for (final usage in colors) {
      if (matches(usage.dominantRole)) return usage;
    }
    return null;
  }

  final textColor = firstWhereRole((r) => r == ColorRole.text);
  final fill = firstWhereRole(_isFill);

  var accent = 0;
  final named = <NamedColor>[];
  for (final usage in colors) {
    final String label;
    final IdentityRole role;
    if (identical(usage, colors.first)) {
      label = labels.primary;
      role = IdentityRole.primary;
    } else if (identical(usage, textColor)) {
      label = labels.text;
      role = IdentityRole.text;
    } else if (identical(usage, fill)) {
      label = labels.background;
      role = IdentityRole.surface;
    } else {
      accent++;
      label = '${labels.accent} $accent';
      role = IdentityRole.accent;
    }
    // **الدور يُحفَظ حقلًا لا يُرمى في اسم.** الاسم للقراءة، والدور للتطبيق:
    // اسمٌ مترجَم لا يُقارَن به شيء، وحقلٌ معلَن يُقارَن.
    named.add(NamedColor(name: label, hex: usage.color, role: role));
  }

  return Identity(
    name: name,
    colors: named,
    latinFont: _dominantFont(document.report, FontSlot.ascii),
    arabicFont: _dominantFont(document.report, FontSlot.complexScript),
    preserveFonts: [
      for (final font in document.report.monospacedCandidates) font.name,
    ],
  );
}

bool _isFill(ColorRole role) => switch (role) {
  ColorRole.paragraphFill ||
  ColorRole.cellFill ||
  ColorRole.rowFill ||
  ColorRole.tableFill ||
  ColorRole.runFill ||
  ColorRole.shapeFill ||
  ColorRole.pageBackground => true,
  _ => false,
};

/// أكثر الخطوط استعمالًا في فتحة بعينها، من بين خطوط المحتوى وحدها.
///
/// من الموروث (`styles.xml` والنماذج) تأتي خطوط لا يراها القارئ أصلًا.
String? _dominantFont(InspectionReport report, FontSlot slot) {
  FontUsage? best;
  for (final font in report.contentFonts) {
    final count = font.bySlot[slot] ?? 0;
    if (count == 0) continue;
    if (best == null || count > (best.bySlot[slot] ?? 0)) best = font;
  }
  return best?.name;
}

// **خطّ العناوين لا يُستخرَج بعد — عمدًا.**
//
// نستطيع قراءته من المعاينة (الفقرة تحمل `outlineLevel`)، لكن `StylePlan`
// يبدّل الخطّ بالفتحة (لاتيني/عربي) لا بالنمط. فاستخراجه يعني أن نعرض على
// المستخدم قيمةً لا نستطيع تطبيقها — وعدٌ بما لا نفعل (`00` §5).
//
// شرطه: خريطة خطوط بالنمط في المحرّك. عندها يُستخرَج ويُطبَّق معًا.
