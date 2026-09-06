/// نصوص واجهة سطر الأوامر — عربية.
///
/// المحرّك يُرجع رموزًا لا كلمات (`01`)، وهذا الملف يصوغها. إضافة لغة للـCLI
/// = ملف مثله وتبديل الاستيراد في `bin/e3ks.dart`.
library;

import 'package:e3ks_engine/e3ks_engine.dart';

const String usage = '''
E3KS — اعكس

  e3ks inspect <ملف.docx> [--json]
      يفحص المستند ويعرض الألوان والخطوط بعددها ودورها وعيّنة نصّها.

  e3ks restyle <ملف.docx> --plan <خطة.json> --out <مخرج.docx>
      يطبّق الخطة. لا يُكتب شيء إن رفضت بوابة التحقّق المخرج.

  e3ks restyle-dir <مجلد> --plan <خطة.json> --out <مجلد>
      يطبّق الخطة على كل مستند في المجلد وما تحته، ويحفظ البنية كما هي.
      ملفٌ يسقط لا يوقف البقيّة، ويُذكر في الحصيلة.

صيغة الخطة:
  {
    "colors": { "#4C2FB8": "#00635D" },
    "fonts":  { "latin": "IBM Plex Sans", "arabic": "IBM Plex Sans Arabic" },
    "preserveFonts": ["DejaVu Sans Mono"],
    "removeMarks": ["highlight:yellow", "textShading:#D9D9D9"],
    "removeHighlight": false,
    "removeTextShading": false
  }
''';

/// أنواع العلامات على النصّ — نصّ معروض، فمكانه هنا لا في المحرّك (`01`).
const Map<MarkKind, String> markKinds = {
  MarkKind.highlight: 'قلم تمييز',
  MarkKind.textShading: 'تظليل نصّ',
};

const Map<String, String> ui = {
  'unknownCommand': 'أمر غير معروف',
  'noFile': 'حدّد ملفًا.',
  'missingFile': 'لا يوجد ملف',
  'needPlanAndOut': 'يلزم: <ملف> --plan <خطة.json> --out <مخرج.docx>',
  'planNotObject': 'الخطة يجب أن تكون كائن JSON.',
  'badColor': 'لون غير صالح في الخطة',
  'writeCancelled': 'أُلغيت الكتابة — لم يُنشأ أي ملف:',
  'needDirPlanAndOut': 'يلزم: <مجلد> --plan <خطة.json> --out <مجلد>',
  'missingDir': 'لا يوجد مجلد',
  'sameDir': 'مجلد المخرَج هو مجلد المصدر — المصدر لا يُكتب فوقه.',
  'noDocuments': 'لا مستندات مدعومة في المجلد.',
  'batchWritten': 'كُتب',
  'batchFailed': 'سقط',
  'batchUnchanged': 'بلا تغيير',
  'batchOf': 'من',
  'neverMatched': 'ألوان في الخطة لم تُطابق أي ملف',
  'scannedParts': 'أجزاء مفحوصة',
  'colors': 'ألوان',
  'fonts': 'خطوط',
  'identityColors': 'ألوان الهوية (يراها القارئ)',
  'inheritedColors': 'موروثة من الأنماط والثيم',
  'marks': 'علامات على النصّ',
  'marksLifted': 'علامات مرفوعة',
  'badMark': 'علامة غير صالحة في الخطة',
  'suggestProtect': 'يُقترح حمايته',
  'colorsReplaced': 'ألوان مُبدَّلة',
  'in_': 'في',
  'colorsWord': 'لونًا',
  'fontsReplaced': 'خطوط مُبدَّلة',
  'themeRemoved': 'سمات ثيم محذوفة',
  'partsChanged': 'أجزاء تغيّرت',
  'fontsProtected': 'خطوط محميّة',
};

const Map<ColorRole, String> roleNames = {
  ColorRole.text: 'لون نص',
  ColorRole.paragraphFill: 'خلفية فقرة',
  ColorRole.cellFill: 'خلفية خلية',
  ColorRole.rowFill: 'خلفية صف',
  ColorRole.tableFill: 'خلفية جدول',
  ColorRole.runFill: 'خلفية نص',
  ColorRole.shadingPattern: 'نمط تظليل',
  ColorRole.border: 'حد',
  ColorRole.pageBackground: 'خلفية صفحة',
  ColorRole.graphics: 'رسوميات',
  ColorRole.themePalette: 'لوحة الثيم',
  ColorRole.other: 'غير محدّد',
};

const Map<ColorFamily, String> familyNames = {
  ColorFamily.red: 'أحمر',
  ColorFamily.orange: 'برتقالي',
  ColorFamily.gold: 'أصفر/ذهبي',
  ColorFamily.green: 'أخضر',
  ColorFamily.teal: 'أزرق مخضرّ',
  ColorFamily.cyan: 'سماوي',
  ColorFamily.blue: 'أزرق',
  ColorFamily.purple: 'بنفسجي',
  ColorFamily.pink: 'وردي',
  ColorFamily.neutral: 'رمادي/محايد',
};

const Map<ColorTone, String> toneNames = {
  ColorTone.veryDark: 'داكن جدًا',
  ColorTone.dark: 'داكن',
  ColorTone.medium: 'متوسط',
  ColorTone.light: 'فاتح',
  ColorTone.veryLight: 'فاتح جدًا',
};

const Map<FontSlot, String> slotNames = {
  FontSlot.ascii: 'لاتيني',
  FontSlot.highAnsi: 'لاتيني موسّع',
  FontSlot.complexScript: 'عربي/معقّد',
  FontSlot.eastAsian: 'شرق آسيوي',
  FontSlot.drawing: 'رسوميات',
};

const Map<IssueCode, String> issueNames = {
  IssueCode.notAnArchive: 'الملف ليس مستند Word صالحًا — تعذّر فتحه.',
  IssueCode.missingContentTypes: 'الملف ينقصه جزء أساسي — ليس مستند Office.',
  IssueCode.checksumMismatch: 'الملف تالف أو غير مكتمل.',
  IssueCode.malformedXml: 'جزء داخل المستند تالف.',
  IssueCode.emptyTextNode:
      'وجدنا مواضع <w:t> بلا نص — تكسر فتح الملف في Google Docs.',
  IssueCode.unbalancedField:
      'حقول Word غير متوازنة — أرقام الصفحات أو الفهرس ستنكسر.',
  IssueCode.contentTypesNotFirst: 'ترتيب أجزاء الملف غير سليم.',
  IssueCode.partCountMismatch: 'عدد أجزاء المخرج لا يطابق المصدر.',
  IssueCode.partNotFound: 'جزء مطلوب غير موجود في المستند.',
  IssueCode.encodeFailed: 'تعذّر بناء الملف الناتج.',
  IssueCode.unmatchedMapping: 'ألوان في خطتك لم توجد في المستند.',
};

String describeColor(HexColor color) =>
    '${familyNames[color.family]} ${toneNames[color.tone]}';

String describeIssue(EngineIssue issue) {
  final base = issueNames[issue.code] ?? issue.code.name;
  final where = issue.part == null ? '' : ' [${issue.part}]';
  final args = issue.args.isEmpty ? '' : ' ${issue.args}';
  return '$base$where$args';
}
