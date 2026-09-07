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
  String get tagline => 'تبديل ألوان المستندات وخطوطها';

  @override
  String get languageName => 'العربية';

  @override
  String get dropHere => 'أفلِت ملف Word أو PowerPoint هنا';

  @override
  String get orDivider => 'ــ أو ــ';

  @override
  String get chooseFile => 'اختر ملف…';

  @override
  String get supported => 'الصيغ المدعومة: ‎.docx‎ و‎.pptx‎';

  @override
  String get reading => 'جارٍ قراءة المستند…';

  @override
  String get openAnother => 'افتح ملف آخر';

  @override
  String get tabColors => 'الألوان';

  @override
  String get tabFonts => 'الخطوط';

  @override
  String get tabIdentities => 'الهويات المحفوظة';

  @override
  String get identityColors => 'ألوان المحتوى';

  @override
  String get identityColorsHint => 'ألوان تظهر في محتوى المستند.';

  @override
  String get inheritedColors => 'ألوان موروثة';

  @override
  String get inheritedColorsHint => 'ألوان من قوالب Word لا تظهر في المحتوى.';

  @override
  String get pickReplacement => 'اختر اللون البديل';

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
  String get openReferenceHint => 'ألوان المستندات الأخرى المفتوحة تظهر هنا.';

  @override
  String get fromSavedIdentities => 'من الهويات المحفوظة';

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
      'الخطّ اللاتيني والعربي منفصلان في OOXML، ويُضبط كل واحد وحده.';

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
      'خطوط أحادية العرض. مستثناة من التبديل لأن استبدالها يغيّر المحاذاة.';

  @override
  String get likelyCodeFont => 'الأرجح أنه خط كود';

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
  String get inspectingDocument => 'جارٍ فحص المستند';

  @override
  String get previewLoadingRest => 'بقيّة الصفحات قيد الاستخراج';

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
  String get identitiesHint => 'مجموعة ألوان وخطوط محفوظة، تصلح لأي مستند.';

  @override
  String get saveIdentity => 'احفظ كهويّة';

  @override
  String get saveIdentityDisabled => 'لا تغييرات لحفظها';

  @override
  String get identityName => 'اسم الهوية';

  @override
  String get identityNameHint => 'مثال: أكاديمية طويق';

  @override
  String get applyIdentity => 'طبّق';

  @override
  String get deleteIdentity => 'احذف';

  @override
  String get noIdentities => 'لا هويات محفوظة.';

  @override
  String get documentFacts => 'نتائج الفحص';

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
  String get exporting => 'جارٍ التصدير…';

  @override
  String get exported => 'تم الحفظ';

  @override
  String get exportBlocked => 'أُلغيت الكتابة — لم يُنشأ أي ملف';

  @override
  String get exportBlockedWhy =>
      'فشل التحقّق من الملف الناتج، فأُلغيت الكتابة.';

  @override
  String get reportColorsReplaced => 'ألوان تغيّرت';

  @override
  String get reportFontsReplaced => 'خطوط تغيّرت';

  @override
  String get reportPartsChanged => 'أجزاء تغيّرت';

  @override
  String get reportFontsProtected => 'خطوط حُميت';

  @override
  String reportUnmatched(Object colors) {
    return 'ألوان غير موجودة في المستند: $colors';
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
      'برنامج حرّ تحت رخصة جنو العمومية العامة، الإصدار الثالث. يُنشر بلا أي ضمان.';

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
  String get licensesTitle => 'رخص المكوّنات';

  @override
  String get licensesHint => 'المكتبات مفتوحة المصدر المستعملة في التطبيق';

  @override
  String get licensesLoading => 'جارٍ التحميل…';

  @override
  String get licensesEmpty => 'لا رخص هنا';

  @override
  String licenseEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رخص',
      two: 'رخصتان',
      one: 'رخصة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get back => 'رجوع';

  @override
  String get focusedColor => 'متابعة اللون';

  @override
  String get clearFocus => 'أوقف المتابعة';

  @override
  String get noMatches => 'لا مواضع';

  @override
  String get tapColorHint => 'متابعة اللون في الصفحة';

  @override
  String get nextMatch => 'الموضع التالي';

  @override
  String get previousMatch => 'الموضع السابق';

  @override
  String get extractIdentity => 'استخرج الهوية من ملف مفتوح';

  @override
  String get extractIdentityHint => 'ألوان الملف مرتّبة بحسب الاستعمال';

  @override
  String extractFrom(String file) {
    return 'استخرج من: $file';
  }

  @override
  String get noOtherFiles => 'لا ملفات أخرى مفتوحة';

  @override
  String get quickPick => 'اختيار سريع';

  @override
  String get quickPickHint => 'ألوان مستخرَجة من الملفات المفتوحة';

  @override
  String get labelPrimary => 'الأساسي';

  @override
  String get labelText => 'لون النصّ';

  @override
  String get labelBackground => 'الخلفية';

  @override
  String get labelAccent => 'مُكمّل';

  @override
  String get goToPage => 'اذهب إلى صفحة';

  @override
  String get showChangeMarks => 'أظهِر علامات التغيير';

  @override
  String get pickColorToTrack => 'التقاط لون من الصفحة';

  @override
  String get shadesOf => 'درجات هذا اللون';

  @override
  String get shadesHint => 'محسوبة من اللون المختار';

  @override
  String get settings => 'الإعدادات';

  @override
  String get fontsSection => 'خطوط المستندات';

  @override
  String get fontsSectionHint =>
      'المعاينة تستعمل خطوط المستند. ما ليس على الجهاز يُجلب ويُحفَظ هنا.';

  @override
  String get fetchFonts => 'اجلب الخطوط الناقصة';

  @override
  String get fetchFontsHint =>
      'يُرسَل اسم الخطّ فقط؛ لا يُرسَل المستند ولا اسمه.';

  @override
  String get cachedFonts => 'خطوط محفوظة';

  @override
  String get cacheSize => 'المساحة المستهلكة';

  @override
  String get deleteAllFonts => 'احذف الكل';

  @override
  String get addFont => 'أضف خط';

  @override
  String fontAdded(String family) {
    return 'أُضيف $family';
  }

  @override
  String get fontAddFailed => 'تعذّرت قراءة الملفّ كخطّ';

  @override
  String get hideNotice => 'إخفاء';

  @override
  String get deleteFont => 'احذف';

  @override
  String get noCachedFonts => 'لا خطوط محفوظة.';

  @override
  String get fontDeletedNote => 'المحذوف يبقى معروضًا حتى إعادة تشغيل التطبيق.';

  @override
  String fontsMissingOne(Object family) {
    return '«$family» غير متاح، ويُرسَم بخطّ التطبيق.';
  }

  @override
  String fontsMissingMany(int count) {
    return '$count خطوط غير متاحة، وتُرسَم بخطّ التطبيق.';
  }

  @override
  String get fontsFetching => 'جارٍ جلب الخطوط…';

  @override
  String get showDetails => 'التفاصيل';

  @override
  String get originBundled => 'مشحون مع التطبيق';

  @override
  String get originSystem => 'على الجهاز';

  @override
  String get originCached => 'محفوظ على القرص';

  @override
  String get originFetched => 'جُلب';

  @override
  String get originUnavailable => 'غير موجود على Google Fonts';

  @override
  String get originSubstituted => 'رُسم ببديل مطابق في المقاسات';

  @override
  String get originOffline => 'تعذّر الاتصال';

  @override
  String get originDisabled => 'الجلب موقوف من الإعدادات';

  @override
  String get errNotAnArchive => 'تعذّر فتح الملف: ليس أرشيف OOXML.';

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
    return '$count موضعًا يكسر فتح الملف في Google Docs.';
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
    return 'ألوان في الخطة غير موجودة في المستند: $colors';
  }

  @override
  String get cancelPicking => 'إلغاء الالتقاط';

  @override
  String get pickingHint => 'التقاط لون — Esc للإلغاء';

  @override
  String get noColorMatch => 'لا لون مطابق';

  @override
  String get batchTitle => 'تطبيق على مجلد';

  @override
  String get batchHint =>
      'الخطة نفسها على كل مستند في المجلد وما تحته، والبنية تُحفَظ.';

  @override
  String get batchSource => 'المجلد';

  @override
  String get batchOutput => 'مجلد المخرَج';

  @override
  String get batchChoose => 'اختر…';

  @override
  String get batchConfirmSource => 'اقرأ من هذا المجلد';

  @override
  String get batchConfirmOutput => 'اكتب في هذا المجلد';

  @override
  String batchDocuments(int count) {
    return '$count مستندًا';
  }

  @override
  String get batchPlan => 'الخطة';

  @override
  String get batchFromOpen => 'خطة الملف المفتوح';

  @override
  String get batchRun => 'شغّل';

  @override
  String batchProgress(int done, int total) {
    return '$done من $total';
  }

  @override
  String get batchWritten => 'كُتب';

  @override
  String get batchFailedCount => 'سقط';

  @override
  String get batchUnchanged => 'بلا تغيير';

  @override
  String get batchNeverMatched => 'ألوان في الخطة لم تُطابق أي ملف';

  @override
  String get batchEmptyFolder => 'لا مستندات مدعومة في هذا المجلد.';

  @override
  String get batchNoPlan => 'بدّل ألوانًا أو اختر هوية محفوظة.';

  @override
  String get batchSameFolder =>
      'مجلد المخرَج هو المصدر — المصدر لا يُكتب فوقه.';

  @override
  String get tabMarks => 'التمييز';

  @override
  String get marksTitle => 'علامات النصّ';

  @override
  String get marksHint => 'قلم التمييز وتظليل الخلفية. الرفع لهذا الملف وحده.';

  @override
  String get emptyMarks => 'افتح مستندًا لعرض علاماته.';

  @override
  String get noMarks => 'لا علامات في هذا المستند.';

  @override
  String get markHighlight => 'قلم تمييز';

  @override
  String get markShading => 'تظليل نصّ';

  @override
  String markUsage(int count, Object kind, Object parts) {
    return '$count موضعًا · $kind · $parts';
  }

  @override
  String get liftAll => 'امسح الكل';

  @override
  String get keepAll => 'أعد الكل';

  @override
  String get liftMark => 'امسح';

  @override
  String get markLifted => 'سيُمسح';

  @override
  String get focusedMark => 'علامة متتبَّعة';

  @override
  String get tapMarkHint => 'اضغط لتتبّع مواضعها';

  @override
  String get reportMarksLifted => 'علامات رُفعت';

  @override
  String get exportFailed => 'تعذّرت الكتابة';

  @override
  String get exportFailedWhy =>
      'لم يُنشأ ملف. جرّب موضعًا آخر: المستندات أو سطح المكتب.';

  @override
  String get fitSubstitute => 'بديل مطابق';

  @override
  String get fitFallback => 'غير متاح هنا';

  @override
  String get fitFallbackWhy => 'يُرسَم بخطّ التطبيق، فالمعاينة تقريبية.';

  @override
  String get fitSubstituteWhy =>
      'يُرسَم ببديل يطابقه في المقاسات، فالتخطيط سليم والحروف حروف غيره.';
}
