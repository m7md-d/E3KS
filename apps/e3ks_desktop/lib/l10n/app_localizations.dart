import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'E3KS'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'تبديل ألوان المستندات وخطوطها'**
  String get tagline;

  /// No description provided for @languageName.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageName;

  /// No description provided for @dropHere.
  ///
  /// In ar, this message translates to:
  /// **'أفلِت ملف Word أو PowerPoint هنا'**
  String get dropHere;

  /// No description provided for @orDivider.
  ///
  /// In ar, this message translates to:
  /// **'ــ أو ــ'**
  String get orDivider;

  /// No description provided for @chooseFile.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملفًا…'**
  String get chooseFile;

  /// No description provided for @supported.
  ///
  /// In ar, this message translates to:
  /// **'الصيغ المدعومة: ‎.docx‎ و‎.pptx‎'**
  String get supported;

  /// No description provided for @reading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ قراءة المستند…'**
  String get reading;

  /// No description provided for @openAnother.
  ///
  /// In ar, this message translates to:
  /// **'افتح ملفًا آخر'**
  String get openAnother;

  /// No description provided for @tabColors.
  ///
  /// In ar, this message translates to:
  /// **'الألوان'**
  String get tabColors;

  /// No description provided for @tabFonts.
  ///
  /// In ar, this message translates to:
  /// **'الخطوط'**
  String get tabFonts;

  /// No description provided for @tabIdentities.
  ///
  /// In ar, this message translates to:
  /// **'الهويات المحفوظة'**
  String get tabIdentities;

  /// No description provided for @identityColors.
  ///
  /// In ar, this message translates to:
  /// **'ألوان المحتوى'**
  String get identityColors;

  /// No description provided for @identityColorsHint.
  ///
  /// In ar, this message translates to:
  /// **'ألوان تظهر في محتوى المستند.'**
  String get identityColorsHint;

  /// No description provided for @inheritedColors.
  ///
  /// In ar, this message translates to:
  /// **'ألوان موروثة'**
  String get inheritedColors;

  /// No description provided for @inheritedColorsHint.
  ///
  /// In ar, this message translates to:
  /// **'ألوان معرَّفة في قوالب Word ولا تظهر في المحتوى.'**
  String get inheritedColorsHint;

  /// No description provided for @pickReplacement.
  ///
  /// In ar, this message translates to:
  /// **'اختر لونًا بديلًا'**
  String get pickReplacement;

  /// No description provided for @colorUsage.
  ///
  /// In ar, this message translates to:
  /// **'{count} موضعًا · {role} · {parts}'**
  String colorUsage(int count, Object role, Object parts);

  /// No description provided for @occurrences.
  ///
  /// In ar, this message translates to:
  /// **'{count} موضعًا'**
  String occurrences(int count);

  /// No description provided for @emptyColors.
  ///
  /// In ar, this message translates to:
  /// **'افتح مستندًا لعرض ألوانه.'**
  String get emptyColors;

  /// No description provided for @emptyFonts.
  ///
  /// In ar, this message translates to:
  /// **'افتح مستندًا لعرض خطوطه.'**
  String get emptyFonts;

  /// No description provided for @replacementColor.
  ///
  /// In ar, this message translates to:
  /// **'اللون البديل'**
  String get replacementColor;

  /// No description provided for @removeMapping.
  ///
  /// In ar, this message translates to:
  /// **'أزل التبديل'**
  String get removeMapping;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'اعتمد'**
  String get confirm;

  /// No description provided for @fromOtherDocument.
  ///
  /// In ar, this message translates to:
  /// **'من مستند آخر مفتوح'**
  String get fromOtherDocument;

  /// No description provided for @openReferenceHint.
  ///
  /// In ar, this message translates to:
  /// **'ألوان المستندات الأخرى المفتوحة تظهر هنا.'**
  String get openReferenceHint;

  /// No description provided for @fromSavedIdentities.
  ///
  /// In ar, this message translates to:
  /// **'من الهويات المحفوظة'**
  String get fromSavedIdentities;

  /// No description provided for @contrastReadable.
  ///
  /// In ar, this message translates to:
  /// **'التباين مع الأبيض {ratio}:1 ✓ مقروء'**
  String contrastReadable(Object ratio);

  /// No description provided for @contrastLow.
  ///
  /// In ar, this message translates to:
  /// **'التباين مع الأبيض {ratio}:1 — منخفض'**
  String contrastLow(Object ratio);

  /// No description provided for @fontsHint.
  ///
  /// In ar, this message translates to:
  /// **'الخطّ اللاتيني والعربي منفصلان في OOXML، ويُضبط كلٌّ منهما وحده.'**
  String get fontsHint;

  /// No description provided for @latinFont.
  ///
  /// In ar, this message translates to:
  /// **'الخط الإنجليزي'**
  String get latinFont;

  /// No description provided for @arabicFont.
  ///
  /// In ar, this message translates to:
  /// **'الخط العربي'**
  String get arabicFont;

  /// No description provided for @keepAsIs.
  ///
  /// In ar, this message translates to:
  /// **'اتركه كما هو'**
  String get keepAsIs;

  /// No description provided for @protectedFonts.
  ///
  /// In ar, this message translates to:
  /// **'خطوط محميّة'**
  String get protectedFonts;

  /// No description provided for @protectedFontsHint.
  ///
  /// In ar, this message translates to:
  /// **'خطوط أحادية العرض. مستثناة من التبديل لأن استبدالها يغيّر المحاذاة.'**
  String get protectedFontsHint;

  /// No description provided for @likelyCodeFont.
  ///
  /// In ar, this message translates to:
  /// **'يُرجَّح أنه خط كود'**
  String get likelyCodeFont;

  /// No description provided for @before.
  ///
  /// In ar, this message translates to:
  /// **'قبل'**
  String get before;

  /// No description provided for @after.
  ///
  /// In ar, this message translates to:
  /// **'بعد'**
  String get after;

  /// No description provided for @showNumbers.
  ///
  /// In ar, this message translates to:
  /// **'أظهِر ترقيم الفقرات'**
  String get showNumbers;

  /// No description provided for @jumpToSection.
  ///
  /// In ar, this message translates to:
  /// **'انتقل إلى قسم'**
  String get jumpToSection;

  /// No description provided for @nextChange.
  ///
  /// In ar, this message translates to:
  /// **'التغيير التالي'**
  String get nextChange;

  /// No description provided for @previousChange.
  ///
  /// In ar, this message translates to:
  /// **'التغيير السابق'**
  String get previousChange;

  /// No description provided for @noChangesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا تغييرات'**
  String get noChangesYet;

  /// No description provided for @fitWidth.
  ///
  /// In ar, this message translates to:
  /// **'ملء العرض'**
  String get fitWidth;

  /// No description provided for @actualSize.
  ///
  /// In ar, this message translates to:
  /// **'مقاس حقيقي'**
  String get actualSize;

  /// No description provided for @zoomIn.
  ///
  /// In ar, this message translates to:
  /// **'تكبير'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In ar, this message translates to:
  /// **'تصغير'**
  String get zoomOut;

  /// No description provided for @pageOf.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {n} من {total}'**
  String pageOf(int n, int total);

  /// No description provided for @previewTruncated.
  ///
  /// In ar, this message translates to:
  /// **'عُرض جزء من المستند لأنه طويل.'**
  String get previewTruncated;

  /// No description provided for @sectionBody.
  ///
  /// In ar, this message translates to:
  /// **'المتن'**
  String get sectionBody;

  /// No description provided for @sectionHeader.
  ///
  /// In ar, this message translates to:
  /// **'الترويسة'**
  String get sectionHeader;

  /// No description provided for @sectionFooter.
  ///
  /// In ar, this message translates to:
  /// **'التذييل'**
  String get sectionFooter;

  /// No description provided for @sectionFootnotes.
  ///
  /// In ar, this message translates to:
  /// **'الحواشي'**
  String get sectionFootnotes;

  /// No description provided for @sectionEndnotes.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات الختامية'**
  String get sectionEndnotes;

  /// No description provided for @sectionComments.
  ///
  /// In ar, this message translates to:
  /// **'التعليقات'**
  String get sectionComments;

  /// No description provided for @partStyles.
  ///
  /// In ar, this message translates to:
  /// **'الأنماط'**
  String get partStyles;

  /// No description provided for @partTheme.
  ///
  /// In ar, this message translates to:
  /// **'الثيم'**
  String get partTheme;

  /// No description provided for @partNumbering.
  ///
  /// In ar, this message translates to:
  /// **'القوائم'**
  String get partNumbering;

  /// No description provided for @roleText.
  ///
  /// In ar, this message translates to:
  /// **'لون نص'**
  String get roleText;

  /// No description provided for @roleParagraphFill.
  ///
  /// In ar, this message translates to:
  /// **'خلفية فقرة'**
  String get roleParagraphFill;

  /// No description provided for @roleCellFill.
  ///
  /// In ar, this message translates to:
  /// **'خلفية خلية'**
  String get roleCellFill;

  /// No description provided for @roleRowFill.
  ///
  /// In ar, this message translates to:
  /// **'خلفية صف'**
  String get roleRowFill;

  /// No description provided for @roleTableFill.
  ///
  /// In ar, this message translates to:
  /// **'خلفية جدول'**
  String get roleTableFill;

  /// No description provided for @roleRunFill.
  ///
  /// In ar, this message translates to:
  /// **'خلفية نص'**
  String get roleRunFill;

  /// No description provided for @roleShadingPattern.
  ///
  /// In ar, this message translates to:
  /// **'نمط تظليل'**
  String get roleShadingPattern;

  /// No description provided for @roleBorder.
  ///
  /// In ar, this message translates to:
  /// **'حد'**
  String get roleBorder;

  /// No description provided for @rolePageBackground.
  ///
  /// In ar, this message translates to:
  /// **'خلفية صفحة'**
  String get rolePageBackground;

  /// No description provided for @roleGraphics.
  ///
  /// In ar, this message translates to:
  /// **'رسوميات'**
  String get roleGraphics;

  /// No description provided for @roleThemePalette.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الثيم'**
  String get roleThemePalette;

  /// No description provided for @roleOther.
  ///
  /// In ar, this message translates to:
  /// **'غير محدّد'**
  String get roleOther;

  /// No description provided for @familyRed.
  ///
  /// In ar, this message translates to:
  /// **'أحمر'**
  String get familyRed;

  /// No description provided for @familyOrange.
  ///
  /// In ar, this message translates to:
  /// **'برتقالي'**
  String get familyOrange;

  /// No description provided for @familyGold.
  ///
  /// In ar, this message translates to:
  /// **'أصفر/ذهبي'**
  String get familyGold;

  /// No description provided for @familyGreen.
  ///
  /// In ar, this message translates to:
  /// **'أخضر'**
  String get familyGreen;

  /// No description provided for @familyTeal.
  ///
  /// In ar, this message translates to:
  /// **'أزرق مخضرّ'**
  String get familyTeal;

  /// No description provided for @familyCyan.
  ///
  /// In ar, this message translates to:
  /// **'سماوي'**
  String get familyCyan;

  /// No description provided for @familyBlue.
  ///
  /// In ar, this message translates to:
  /// **'أزرق'**
  String get familyBlue;

  /// No description provided for @familyPurple.
  ///
  /// In ar, this message translates to:
  /// **'بنفسجي'**
  String get familyPurple;

  /// No description provided for @familyPink.
  ///
  /// In ar, this message translates to:
  /// **'وردي'**
  String get familyPink;

  /// No description provided for @familyNeutral.
  ///
  /// In ar, this message translates to:
  /// **'رمادي/محايد'**
  String get familyNeutral;

  /// No description provided for @toneVeryDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن جدًا'**
  String get toneVeryDark;

  /// No description provided for @toneDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get toneDark;

  /// No description provided for @toneMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get toneMedium;

  /// No description provided for @toneLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get toneLight;

  /// No description provided for @toneVeryLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح جدًا'**
  String get toneVeryLight;

  /// No description provided for @slotAscii.
  ///
  /// In ar, this message translates to:
  /// **'لاتيني'**
  String get slotAscii;

  /// No description provided for @slotHighAnsi.
  ///
  /// In ar, this message translates to:
  /// **'لاتيني موسّع'**
  String get slotHighAnsi;

  /// No description provided for @slotComplexScript.
  ///
  /// In ar, this message translates to:
  /// **'عربي/معقّد'**
  String get slotComplexScript;

  /// No description provided for @slotEastAsian.
  ///
  /// In ar, this message translates to:
  /// **'شرق آسيوي'**
  String get slotEastAsian;

  /// No description provided for @slotDrawing.
  ///
  /// In ar, this message translates to:
  /// **'رسوميات'**
  String get slotDrawing;

  /// No description provided for @identitiesHint.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة ألوان وخطوط محفوظة، تُطبَّق على أي مستند.'**
  String get identitiesHint;

  /// No description provided for @saveIdentity.
  ///
  /// In ar, this message translates to:
  /// **'احفظ كهويّة'**
  String get saveIdentity;

  /// No description provided for @saveIdentityDisabled.
  ///
  /// In ar, this message translates to:
  /// **'لا تغييرات لحفظها'**
  String get saveIdentityDisabled;

  /// No description provided for @identityName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الهوية'**
  String get identityName;

  /// No description provided for @identityNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: أكاديمية طويق'**
  String get identityNameHint;

  /// No description provided for @applyIdentity.
  ///
  /// In ar, this message translates to:
  /// **'طبّق'**
  String get applyIdentity;

  /// No description provided for @deleteIdentity.
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get deleteIdentity;

  /// No description provided for @noIdentities.
  ///
  /// In ar, this message translates to:
  /// **'لا هويات محفوظة.'**
  String get noIdentities;

  /// No description provided for @documentFacts.
  ///
  /// In ar, this message translates to:
  /// **'نتائج الفحص'**
  String get documentFacts;

  /// No description provided for @factDesignColors.
  ///
  /// In ar, this message translates to:
  /// **'ألوان التصميم'**
  String get factDesignColors;

  /// No description provided for @factInheritedColors.
  ///
  /// In ar, this message translates to:
  /// **'ألوان موروثة'**
  String get factInheritedColors;

  /// No description provided for @factFonts.
  ///
  /// In ar, this message translates to:
  /// **'خطوط'**
  String get factFonts;

  /// No description provided for @factScannedParts.
  ///
  /// In ar, this message translates to:
  /// **'أجزاء مفحوصة'**
  String get factScannedParts;

  /// No description provided for @export.
  ///
  /// In ar, this message translates to:
  /// **'صدّر المستند'**
  String get export;

  /// No description provided for @exporting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التصدير…'**
  String get exporting;

  /// No description provided for @exported.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get exported;

  /// No description provided for @exportBlocked.
  ///
  /// In ar, this message translates to:
  /// **'أُلغيت الكتابة — لم يُنشأ أي ملف'**
  String get exportBlocked;

  /// No description provided for @exportBlockedWhy.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحقّق من الملف الناتج، فأُلغيت الكتابة.'**
  String get exportBlockedWhy;

  /// No description provided for @reportColorsReplaced.
  ///
  /// In ar, this message translates to:
  /// **'ألوان بُدِّلت'**
  String get reportColorsReplaced;

  /// No description provided for @reportFontsReplaced.
  ///
  /// In ar, this message translates to:
  /// **'خطوط بُدِّلت'**
  String get reportFontsReplaced;

  /// No description provided for @reportPartsChanged.
  ///
  /// In ar, this message translates to:
  /// **'أجزاء تغيّرت'**
  String get reportPartsChanged;

  /// No description provided for @reportFontsProtected.
  ///
  /// In ar, this message translates to:
  /// **'خطوط حُميت'**
  String get reportFontsProtected;

  /// No description provided for @reportUnmatched.
  ///
  /// In ar, this message translates to:
  /// **'ألوان غير موجودة في المستند: {colors}'**
  String reportUnmatched(Object colors);

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @reset.
  ///
  /// In ar, this message translates to:
  /// **'تراجع عن الكل'**
  String get reset;

  /// No description provided for @changesBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} تغييرًا'**
  String changesBadge(int count);

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @aboutSection.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutSection;

  /// No description provided for @aboutCopyright.
  ///
  /// In ar, this message translates to:
  /// **'© 2026 m7md-d'**
  String get aboutCopyright;

  /// No description provided for @aboutLicense.
  ///
  /// In ar, this message translates to:
  /// **'برنامج حرّ تحت رخصة جنو العمومية العامة، الإصدار الثالث. يُوزَّع بلا أيّ ضمان.'**
  String get aboutLicense;

  /// No description provided for @componentLicenses.
  ///
  /// In ar, this message translates to:
  /// **'رخص المكوّنات'**
  String get componentLicenses;

  /// No description provided for @sourceCode.
  ///
  /// In ar, this message translates to:
  /// **'الشيفرة المصدرية'**
  String get sourceCode;

  /// No description provided for @roleShapeFill.
  ///
  /// In ar, this message translates to:
  /// **'تعبئة شكل'**
  String get roleShapeFill;

  /// No description provided for @sectionSlides.
  ///
  /// In ar, this message translates to:
  /// **'الشرائح'**
  String get sectionSlides;

  /// No description provided for @errUnsupportedFormat.
  ///
  /// In ar, this message translates to:
  /// **'هذه الصيغة غير مدعومة. المدعوم اليوم: Word ‏(.docx) و PowerPoint ‏(.pptx).'**
  String get errUnsupportedFormat;

  /// No description provided for @errForeignPartTouched.
  ///
  /// In ar, this message translates to:
  /// **'خلل داخلي: حاولت الصيغة الكتابة في جزء لا تملكه، فأُوقف التصدير.'**
  String get errForeignPartTouched;

  /// No description provided for @licensesTitle.
  ///
  /// In ar, this message translates to:
  /// **'رخص المكوّنات'**
  String get licensesTitle;

  /// No description provided for @licensesHint.
  ///
  /// In ar, this message translates to:
  /// **'المكتبات مفتوحة المصدر المستعملة في التطبيق'**
  String get licensesHint;

  /// No description provided for @licensesLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get licensesLoading;

  /// No description provided for @licensesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا رخص مسجَّلة'**
  String get licensesEmpty;

  /// No description provided for @licenseEntries.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{رخصة واحدة} =2{رخصتان} other{{count} رخص}}'**
  String licenseEntries(int count);

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @focusedColor.
  ///
  /// In ar, this message translates to:
  /// **'متابعة اللون'**
  String get focusedColor;

  /// No description provided for @clearFocus.
  ///
  /// In ar, this message translates to:
  /// **'أوقف المتابعة'**
  String get clearFocus;

  /// No description provided for @noMatches.
  ///
  /// In ar, this message translates to:
  /// **'لا مواضع'**
  String get noMatches;

  /// No description provided for @tapColorHint.
  ///
  /// In ar, this message translates to:
  /// **'متابعة اللون في الصفحة'**
  String get tapColorHint;

  /// No description provided for @nextMatch.
  ///
  /// In ar, this message translates to:
  /// **'الموضع التالي'**
  String get nextMatch;

  /// No description provided for @previousMatch.
  ///
  /// In ar, this message translates to:
  /// **'الموضع السابق'**
  String get previousMatch;

  /// No description provided for @extractIdentity.
  ///
  /// In ar, this message translates to:
  /// **'استخرج الهوية من ملف مفتوح'**
  String get extractIdentity;

  /// No description provided for @extractIdentityHint.
  ///
  /// In ar, this message translates to:
  /// **'ألوان الملف مرتّبة بالأكثر استعمالًا'**
  String get extractIdentityHint;

  /// No description provided for @extractFrom.
  ///
  /// In ar, this message translates to:
  /// **'استخرج من: {file}'**
  String extractFrom(String file);

  /// No description provided for @noOtherFiles.
  ///
  /// In ar, this message translates to:
  /// **'لا ملفات أخرى مفتوحة'**
  String get noOtherFiles;

  /// No description provided for @quickPick.
  ///
  /// In ar, this message translates to:
  /// **'اختيار سريع'**
  String get quickPick;

  /// No description provided for @quickPickHint.
  ///
  /// In ar, this message translates to:
  /// **'ألوان مستخرَجة من الملفات المفتوحة'**
  String get quickPickHint;

  /// No description provided for @labelPrimary.
  ///
  /// In ar, this message translates to:
  /// **'الأساسي'**
  String get labelPrimary;

  /// No description provided for @labelText.
  ///
  /// In ar, this message translates to:
  /// **'لون النصّ'**
  String get labelText;

  /// No description provided for @labelBackground.
  ///
  /// In ar, this message translates to:
  /// **'الخلفية'**
  String get labelBackground;

  /// No description provided for @labelAccent.
  ///
  /// In ar, this message translates to:
  /// **'مُكمّل'**
  String get labelAccent;

  /// No description provided for @goToPage.
  ///
  /// In ar, this message translates to:
  /// **'اذهب إلى صفحة'**
  String get goToPage;

  /// No description provided for @showChangeMarks.
  ///
  /// In ar, this message translates to:
  /// **'أظهِر علامات التغيير'**
  String get showChangeMarks;

  /// No description provided for @pickColorToTrack.
  ///
  /// In ar, this message translates to:
  /// **'التقاط لون من الصفحة'**
  String get pickColorToTrack;

  /// No description provided for @shadesOf.
  ///
  /// In ar, this message translates to:
  /// **'درجات هذا اللون'**
  String get shadesOf;

  /// No description provided for @shadesHint.
  ///
  /// In ar, this message translates to:
  /// **'محسوبة من اللون المختار'**
  String get shadesHint;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @fontsSection.
  ///
  /// In ar, this message translates to:
  /// **'خطوط المستندات'**
  String get fontsSection;

  /// No description provided for @fontsSectionHint.
  ///
  /// In ar, this message translates to:
  /// **'المعاينة تستعمل خطوط المستند. غير المنصَّب منها يُجلب ويُحفَظ هنا.'**
  String get fontsSectionHint;

  /// No description provided for @fetchFonts.
  ///
  /// In ar, this message translates to:
  /// **'اجلب الخطوط الناقصة'**
  String get fetchFonts;

  /// No description provided for @fetchFontsHint.
  ///
  /// In ar, this message translates to:
  /// **'يُرسَل اسم الخطّ فقط؛ لا يُرسَل المستند ولا اسمه.'**
  String get fetchFontsHint;

  /// No description provided for @cachedFonts.
  ///
  /// In ar, this message translates to:
  /// **'خطوط محفوظة'**
  String get cachedFonts;

  /// No description provided for @cacheSize.
  ///
  /// In ar, this message translates to:
  /// **'المساحة المستهلكة'**
  String get cacheSize;

  /// No description provided for @deleteAllFonts.
  ///
  /// In ar, this message translates to:
  /// **'احذف الكل'**
  String get deleteAllFonts;

  /// No description provided for @deleteFont.
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get deleteFont;

  /// No description provided for @noCachedFonts.
  ///
  /// In ar, this message translates to:
  /// **'لا خطوط محفوظة.'**
  String get noCachedFonts;

  /// No description provided for @fontDeletedNote.
  ///
  /// In ar, this message translates to:
  /// **'المحذوف يبقى معروضًا حتى إعادة تشغيل التطبيق.'**
  String get fontDeletedNote;

  /// No description provided for @fontsMissingOne.
  ///
  /// In ar, this message translates to:
  /// **'خطّ واحد غير متاح، والمعاينة تعرضه ببديل.'**
  String get fontsMissingOne;

  /// No description provided for @fontsMissingMany.
  ///
  /// In ar, this message translates to:
  /// **'{count} خطوط غير متاحة، والمعاينة تعرضها ببدائل.'**
  String fontsMissingMany(int count);

  /// No description provided for @fontsFetching.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ جلب الخطوط…'**
  String get fontsFetching;

  /// No description provided for @showDetails.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get showDetails;

  /// No description provided for @originBundled.
  ///
  /// In ar, this message translates to:
  /// **'مضمَّن في التطبيق'**
  String get originBundled;

  /// No description provided for @originSystem.
  ///
  /// In ar, this message translates to:
  /// **'منصَّب على الجهاز'**
  String get originSystem;

  /// No description provided for @originCached.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ محليًّا'**
  String get originCached;

  /// No description provided for @originFetched.
  ///
  /// In ar, this message translates to:
  /// **'جُلب'**
  String get originFetched;

  /// No description provided for @originUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير موجود على Google Fonts'**
  String get originUnavailable;

  /// No description provided for @originOffline.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال'**
  String get originOffline;

  /// No description provided for @originDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الجلب معطَّل من الإعدادات'**
  String get originDisabled;

  /// No description provided for @errNotAnArchive.
  ///
  /// In ar, this message translates to:
  /// **'الملف ليس أرشيف OOXML صالحًا؛ تعذّر فتحه.'**
  String get errNotAnArchive;

  /// No description provided for @errMissingContentTypes.
  ///
  /// In ar, this message translates to:
  /// **'الملف ينقصه جزء أساسي — ليس مستند Office.'**
  String get errMissingContentTypes;

  /// No description provided for @errChecksumMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الملف تالف أو غير مكتمل.'**
  String get errChecksumMismatch;

  /// No description provided for @errMalformedXml.
  ///
  /// In ar, this message translates to:
  /// **'جزء داخل المستند تالف: {part}'**
  String errMalformedXml(Object part);

  /// No description provided for @errEmptyTextNode.
  ///
  /// In ar, this message translates to:
  /// **'{count} موضعًا يكسر فتح الملف في Google Docs.'**
  String errEmptyTextNode(int count);

  /// No description provided for @errUnbalancedField.
  ///
  /// In ar, this message translates to:
  /// **'حقول Word غير متوازنة — أرقام الصفحات أو الفهرس ستنكسر.'**
  String get errUnbalancedField;

  /// No description provided for @errContentTypesNotFirst.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب أجزاء الملف غير سليم — بعض البرامج سترفضه.'**
  String get errContentTypesNotFirst;

  /// No description provided for @errPartCountMismatch.
  ///
  /// In ar, this message translates to:
  /// **'عدد أجزاء المخرج لا يطابق المصدر.'**
  String get errPartCountMismatch;

  /// No description provided for @errPartNotFound.
  ///
  /// In ar, this message translates to:
  /// **'جزء مطلوب غير موجود في المستند.'**
  String get errPartNotFound;

  /// No description provided for @errEncodeFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر بناء الملف الناتج.'**
  String get errEncodeFailed;

  /// No description provided for @errUnmatchedMapping.
  ///
  /// In ar, this message translates to:
  /// **'ألوان في الخطة غير موجودة في المستند: {colors}'**
  String errUnmatchedMapping(Object colors);

  /// No description provided for @cancelPicking.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الالتقاط'**
  String get cancelPicking;

  /// No description provided for @pickingHint.
  ///
  /// In ar, this message translates to:
  /// **'التقاط لون — Esc للإلغاء'**
  String get pickingHint;

  /// No description provided for @noColorMatch.
  ///
  /// In ar, this message translates to:
  /// **'لا لون مطابق'**
  String get noColorMatch;

  /// No description provided for @batchTitle.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق على مجلد'**
  String get batchTitle;

  /// No description provided for @batchHint.
  ///
  /// In ar, this message translates to:
  /// **'الخطة نفسها على كل مستند في المجلد وما تحته، والبنية تُحفَظ.'**
  String get batchHint;

  /// No description provided for @batchSource.
  ///
  /// In ar, this message translates to:
  /// **'المجلد'**
  String get batchSource;

  /// No description provided for @batchOutput.
  ///
  /// In ar, this message translates to:
  /// **'مجلد المخرَج'**
  String get batchOutput;

  /// No description provided for @batchChoose.
  ///
  /// In ar, this message translates to:
  /// **'اختر…'**
  String get batchChoose;

  /// No description provided for @batchDocuments.
  ///
  /// In ar, this message translates to:
  /// **'{count} مستندًا'**
  String batchDocuments(int count);

  /// No description provided for @batchPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة'**
  String get batchPlan;

  /// No description provided for @batchFromOpen.
  ///
  /// In ar, this message translates to:
  /// **'خطة الملف المفتوح'**
  String get batchFromOpen;

  /// No description provided for @batchRun.
  ///
  /// In ar, this message translates to:
  /// **'شغّل'**
  String get batchRun;

  /// No description provided for @batchProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total}'**
  String batchProgress(int done, int total);

  /// No description provided for @batchWritten.
  ///
  /// In ar, this message translates to:
  /// **'كُتب'**
  String get batchWritten;

  /// No description provided for @batchFailedCount.
  ///
  /// In ar, this message translates to:
  /// **'سقط'**
  String get batchFailedCount;

  /// No description provided for @batchUnchanged.
  ///
  /// In ar, this message translates to:
  /// **'بلا تغيير'**
  String get batchUnchanged;

  /// No description provided for @batchNeverMatched.
  ///
  /// In ar, this message translates to:
  /// **'ألوان في الخطة لم تُطابق أي ملف'**
  String get batchNeverMatched;

  /// No description provided for @batchEmptyFolder.
  ///
  /// In ar, this message translates to:
  /// **'لا مستندات مدعومة في هذا المجلد.'**
  String get batchEmptyFolder;

  /// No description provided for @batchNoPlan.
  ///
  /// In ar, this message translates to:
  /// **'بدّل ألوانًا أو اختر هوية محفوظة.'**
  String get batchNoPlan;

  /// No description provided for @batchSameFolder.
  ///
  /// In ar, this message translates to:
  /// **'مجلد المخرَج هو المصدر — المصدر لا يُكتب فوقه.'**
  String get batchSameFolder;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return LAr();
    case 'en':
      return LEn();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
