// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class LAr extends L {
  LAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'E3KS';

  @override
  String get tagline => 'اعكس هوية مستندك';

  @override
  String get languageName => 'العربية';

  @override
  String get dropHere => 'اسحب ملف Word هنا';

  @override
  String get orDivider => 'ــ أو ــ';

  @override
  String get chooseFile => 'اختر ملفًا…';

  @override
  String get supported => 'يدعم ملفات ‎.docx‎ و‎.pptx‎ من Word و PowerPoint';

  @override
  String get reading => 'نقرأ المستند…';

  @override
  String get openAnother => 'افتح ملفًا آخر';

  @override
  String get tabColors => 'الألوان';

  @override
  String get tabFonts => 'الخطوط';

  @override
  String get tabIdentities => 'الهويات المحفوظة';

  @override
  String get identityColors => 'ألوان يراها القارئ';

  @override
  String get identityColorsHint =>
      'هذه ألوان التصميم الفعلية في مستندك. غالبًا هي ما تريد تغييره.';

  @override
  String get inheritedColors => 'ألوان موروثة من قوالب Word';

  @override
  String get inheritedColorsHint =>
      'ألوان أتت مع قوالب Word الجاهزة ولا تظهر في النصّ. عادةً تُترك كما هي.';

  @override
  String get pickReplacement => 'اختر لونًا بديلًا';

  @override
  String colorUsage(int count, Object role, Object parts) {
    return '$count موضعًا · $role · $parts';
  }

  @override
  String occurrences(int count) {
    return '$count موضعًا';
  }

  @override
  String get emptyColors => 'افتح مستندًا لعرض ألوانه.';

  @override
  String get emptyFonts => 'افتح مستندًا لعرض خطوطه.';

  @override
  String get replacementColor => 'اللون البديل';

  @override
  String get removeMapping => 'أزل التبديل';

  @override
  String get confirm => 'اعتمد';

  @override
  String get fromOtherDocument => 'من مستند آخر مفتوح';

  @override
  String get openReferenceHint =>
      'افتح ملفًا فيه الهوية التي تريدها، وستظهر ألوانه هنا.';

  @override
  String get fromSavedIdentities => 'من هوياتك المحفوظة';

  @override
  String contrastReadable(Object ratio) {
    return 'التباين مع الأبيض $ratio:1 ✓ مقروء';
  }

  @override
  String contrastLow(Object ratio) {
    return 'التباين مع الأبيض $ratio:1 — منخفض';
  }

  @override
  String get fontsHint =>
      'وحّد خطوط المستند. الخطوط العربية والإنجليزية منفصلة لأن دمجها يكسر أحدهما.';

  @override
  String get latinFont => 'الخط الإنجليزي';

  @override
  String get arabicFont => 'الخط العربي';

  @override
  String get keepAsIs => 'اتركه كما هو';

  @override
  String get protectedFonts => 'خطوط محميّة';

  @override
  String get protectedFontsHint =>
      'خطوط الكود والجداول التقنية. تغييرها يفسد محاذاتها، فنستثنيها.';

  @override
  String get likelyCodeFont => 'يُرجَّح أنه خط كود';

  @override
  String get before => 'قبل';

  @override
  String get after => 'بعد';

  @override
  String get showNumbers => 'أظهِر ترقيم الفقرات';

  @override
  String get jumpToSection => 'انتقل إلى قسم';

  @override
  String get nextChange => 'التغيير التالي';

  @override
  String get previousChange => 'التغيير السابق';

  @override
  String get noChangesYet => 'لا تغييرات';

  @override
  String get fitWidth => 'ملء العرض';

  @override
  String get actualSize => 'مقاس حقيقي';

  @override
  String get zoomIn => 'تكبير';

  @override
  String get zoomOut => 'تصغير';

  @override
  String pageOf(int n, int total) {
    return 'صفحة $n من $total';
  }

  @override
  String get previewTruncated => 'عُرض جزء من المستند لأنه طويل.';

  @override
  String get sectionBody => 'المتن';

  @override
  String get sectionHeader => 'الترويسة';

  @override
  String get sectionFooter => 'التذييل';

  @override
  String get sectionFootnotes => 'الحواشي';

  @override
  String get sectionEndnotes => 'التعليقات الختامية';

  @override
  String get sectionComments => 'التعليقات';

  @override
  String get partStyles => 'الأنماط';

  @override
  String get partTheme => 'الثيم';

  @override
  String get partNumbering => 'القوائم';

  @override
  String get roleText => 'لون نص';

  @override
  String get roleParagraphFill => 'خلفية فقرة';

  @override
  String get roleCellFill => 'خلفية خلية';

  @override
  String get roleRowFill => 'خلفية صف';

  @override
  String get roleTableFill => 'خلفية جدول';

  @override
  String get roleRunFill => 'خلفية نص';

  @override
  String get roleShadingPattern => 'نمط تظليل';

  @override
  String get roleBorder => 'حد';

  @override
  String get rolePageBackground => 'خلفية صفحة';

  @override
  String get roleGraphics => 'رسوميات';

  @override
  String get roleThemePalette => 'لوحة الثيم';

  @override
  String get roleOther => 'غير محدّد';

  @override
  String get familyRed => 'أحمر';

  @override
  String get familyOrange => 'برتقالي';

  @override
  String get familyGold => 'أصفر/ذهبي';

  @override
  String get familyGreen => 'أخضر';

  @override
  String get familyTeal => 'أزرق مخضرّ';

  @override
  String get familyCyan => 'سماوي';

  @override
  String get familyBlue => 'أزرق';

  @override
  String get familyPurple => 'بنفسجي';

  @override
  String get familyPink => 'وردي';

  @override
  String get familyNeutral => 'رمادي/محايد';

  @override
  String get toneVeryDark => 'داكن جدًا';

  @override
  String get toneDark => 'داكن';

  @override
  String get toneMedium => 'متوسط';

  @override
  String get toneLight => 'فاتح';

  @override
  String get toneVeryLight => 'فاتح جدًا';

  @override
  String get slotAscii => 'لاتيني';

  @override
  String get slotHighAnsi => 'لاتيني موسّع';

  @override
  String get slotComplexScript => 'عربي/معقّد';

  @override
  String get slotEastAsian => 'شرق آسيوي';

  @override
  String get slotDrawing => 'رسوميات';

  @override
  String get identitiesHint =>
      'مجموعة ألوان وخطوط تحفظها مرّة وتطبّقها على أي مستند.';

  @override
  String get saveIdentity => 'احفظ كهويّة';

  @override
  String get saveIdentityDisabled => 'بدّل ألوانًا أولًا ثم احفظها كهويّة';

  @override
  String get identityName => 'اسم الهوية';

  @override
  String get identityNameHint => 'مثال: أكاديمية طويق';

  @override
  String get applyIdentity => 'طبّق';

  @override
  String get deleteIdentity => 'احذف';

  @override
  String get noIdentities =>
      'لا هويات محفوظة بعد.\nبدّل بعض الألوان ثم اضغط «احفظ كهويّة».';

  @override
  String get documentFacts => 'ما وجدناه في المستند';

  @override
  String get factDesignColors => 'ألوان التصميم';

  @override
  String get factInheritedColors => 'ألوان موروثة';

  @override
  String get factFonts => 'خطوط';

  @override
  String get factScannedParts => 'أجزاء مفحوصة';

  @override
  String get export => 'صدّر المستند';

  @override
  String get exporting => 'نُجهّز الملف…';

  @override
  String get exported => 'تم الحفظ';

  @override
  String get exportBlocked => 'أُلغيت الكتابة — لم يُنشأ أي ملف';

  @override
  String get exportBlockedWhy =>
      'اكتشفنا خللًا قد يكسر الملف عند فتحه، فأوقفنا الحفظ.';

  @override
  String get reportColorsReplaced => 'ألوان بُدِّلت';

  @override
  String get reportFontsReplaced => 'خطوط بُدِّلت';

  @override
  String get reportPartsChanged => 'أجزاء تغيّرت';

  @override
  String get reportFontsProtected => 'خطوط حُميت';

  @override
  String reportUnmatched(Object colors) {
    return 'ألوان اخترتها لم توجد في المستند: $colors';
  }

  @override
  String get close => 'إغلاق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get reset => 'تراجع عن الكل';

  @override
  String changesBadge(int count) {
    return '$count تغييرًا';
  }

  @override
  String get language => 'اللغة';

  @override
  String get aboutSection => 'عن التطبيق';

  @override
  String get aboutCopyright => '© 2026 m7md-d';

  @override
  String get aboutLicense =>
      'برنامج حرّ تحت رخصة جنو العمومية العامة، الإصدار الثالث. يُوزَّع بلا أيّ ضمان.';

  @override
  String get componentLicenses => 'رخص المكوّنات';

  @override
  String get sourceCode => 'الشيفرة المصدرية';

  @override
  String get roleShapeFill => 'تعبئة شكل';

  @override
  String get sectionSlides => 'الشرائح';

  @override
  String get errUnsupportedFormat =>
      'هذه الصيغة غير مدعومة. المدعوم اليوم: Word ‏(.docx) و PowerPoint ‏(.pptx).';

  @override
  String get errForeignPartTouched =>
      'خلل داخلي: حاولت الصيغة الكتابة في جزء لا تملكه، فأُوقف التصدير.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get fontsSection => 'خطوط المستندات';

  @override
  String get fontsSectionHint =>
      'لعرض ملفّك بشكله الحقيقي نحتاج خطوطه. ما لا يوجد على جهازك نجلبه ونحفظه هنا.';

  @override
  String get fetchFonts => 'اجلب الخطوط الناقصة';

  @override
  String get fetchFontsHint =>
      'يغادر جهازك اسم الخطّ فقط — لا محتوى المستند ولا اسمه.';

  @override
  String get cachedFonts => 'خطوط محفوظة';

  @override
  String get cacheSize => 'المساحة المستهلكة';

  @override
  String get deleteAllFonts => 'احذف الكل';

  @override
  String get deleteFont => 'احذف';

  @override
  String get noCachedFonts => 'لا خطوط محفوظة بعد.';

  @override
  String get fontDeletedNote => 'المحذوف يبقى معروضًا حتى إعادة تشغيل التطبيق.';

  @override
  String get fontsMissingOne => 'خطّ واحد غير متاح، والمعاينة تعرضه ببديل.';

  @override
  String fontsMissingMany(int count) {
    return '$count خطوط غير متاحة، والمعاينة تعرضها ببدائل.';
  }

  @override
  String get fontsFetching => 'نجلب خطوط المستند…';

  @override
  String get showDetails => 'التفاصيل';

  @override
  String get originBundled => 'مضمَّن في التطبيق';

  @override
  String get originSystem => 'منصَّب على جهازك';

  @override
  String get originCached => 'محفوظ عندنا';

  @override
  String get originFetched => 'جُلب الآن';

  @override
  String get originUnavailable => 'لم نجده على Google Fonts';

  @override
  String get originOffline => 'تعذّر الاتصال';

  @override
  String get originDisabled => 'الجلب معطَّل من الإعدادات';

  @override
  String get errNotAnArchive => 'الملف ليس مستند Word صالحًا — تعذّر فتحه.';

  @override
  String get errMissingContentTypes =>
      'الملف ينقصه جزء أساسي — ليس مستند Office.';

  @override
  String get errChecksumMismatch => 'الملف تالف أو غير مكتمل.';

  @override
  String errMalformedXml(Object part) {
    return 'جزء داخل المستند تالف: $part';
  }

  @override
  String errEmptyTextNode(int count) {
    return 'وجدنا $count موضعًا يكسر فتح الملف في Google Docs.';
  }

  @override
  String get errUnbalancedField =>
      'حقول Word غير متوازنة — أرقام الصفحات أو الفهرس ستنكسر.';

  @override
  String get errContentTypesNotFirst =>
      'ترتيب أجزاء الملف غير سليم — بعض البرامج سترفضه.';

  @override
  String get errPartCountMismatch => 'عدد أجزاء المخرج لا يطابق المصدر.';

  @override
  String get errPartNotFound => 'جزء مطلوب غير موجود في المستند.';

  @override
  String get errEncodeFailed => 'تعذّر بناء الملف الناتج.';

  @override
  String errUnmatchedMapping(Object colors) {
    return 'ألوان في خطتك لم توجد في المستند: $colors';
  }
}
