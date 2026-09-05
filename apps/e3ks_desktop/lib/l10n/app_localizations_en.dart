// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'E3KS';

  @override
  String get tagline => 'Reverse your document\'s identity';

  @override
  String get languageName => 'English';

  @override
  String get dropHere => 'Drop a Word file here';

  @override
  String get orDivider => '— or —';

  @override
  String get chooseFile => 'Choose a file…';

  @override
  String get supported =>
      'Supports .docx and .pptx files from Word and PowerPoint';

  @override
  String get reading => 'Reading the document…';

  @override
  String get openAnother => 'Open another file';

  @override
  String get tabColors => 'Colours';

  @override
  String get tabFonts => 'Fonts';

  @override
  String get tabIdentities => 'Saved identities';

  @override
  String get identityColors => 'Colours the reader sees';

  @override
  String get identityColorsHint =>
      'These are your document\'s actual design colours. Usually the ones you want to change.';

  @override
  String get inheritedColors => 'Colours inherited from Word templates';

  @override
  String get inheritedColorsHint =>
      'Colours that came with built-in Word templates and never appear in the text. Normally left alone.';

  @override
  String get pickReplacement => 'Pick a replacement colour';

  @override
  String colorUsage(int count, Object role, Object parts) {
    return '$count places · $role · $parts';
  }

  @override
  String occurrences(int count) {
    return '$count places';
  }

  @override
  String get emptyColors => 'Open a document to see its colours.';

  @override
  String get emptyFonts => 'Open a document to see its fonts.';

  @override
  String get replacementColor => 'Replacement colour';

  @override
  String get removeMapping => 'Remove replacement';

  @override
  String get confirm => 'Apply';

  @override
  String get fromOtherDocument => 'From another open document';

  @override
  String get openReferenceHint =>
      'Open a file that has the identity you want, and its colours appear here.';

  @override
  String get fromSavedIdentities => 'From your saved identities';

  @override
  String contrastReadable(Object ratio) {
    return 'Contrast on white $ratio:1 ✓ readable';
  }

  @override
  String contrastLow(Object ratio) {
    return 'Contrast on white $ratio:1 — low';
  }

  @override
  String get fontsHint =>
      'Unify the document\'s fonts. Arabic and Latin are separate because merging them breaks one of the two.';

  @override
  String get latinFont => 'Latin font';

  @override
  String get arabicFont => 'Arabic font';

  @override
  String get keepAsIs => 'Leave unchanged';

  @override
  String get protectedFonts => 'Protected fonts';

  @override
  String get protectedFontsHint =>
      'Fonts used for code and technical tables. Changing them ruins the alignment, so we skip them.';

  @override
  String get likelyCodeFont => 'likely a code font';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get showNumbers => 'Show paragraph numbers';

  @override
  String get jumpToSection => 'Jump to section';

  @override
  String get nextChange => 'Next change';

  @override
  String get previousChange => 'Previous change';

  @override
  String get noChangesYet => 'No changes';

  @override
  String get fitWidth => 'Fit width';

  @override
  String get actualSize => 'Actual size';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String pageOf(int n, int total) {
    return 'Page $n of $total';
  }

  @override
  String get previewTruncated =>
      'Part of the document is shown because it is long.';

  @override
  String get sectionBody => 'Body';

  @override
  String get sectionHeader => 'Header';

  @override
  String get sectionFooter => 'Footer';

  @override
  String get sectionFootnotes => 'Footnotes';

  @override
  String get sectionEndnotes => 'Endnotes';

  @override
  String get sectionComments => 'Comments';

  @override
  String get partStyles => 'Styles';

  @override
  String get partTheme => 'Theme';

  @override
  String get partNumbering => 'Lists';

  @override
  String get roleText => 'text colour';

  @override
  String get roleParagraphFill => 'paragraph fill';

  @override
  String get roleCellFill => 'cell fill';

  @override
  String get roleRowFill => 'row fill';

  @override
  String get roleTableFill => 'table fill';

  @override
  String get roleRunFill => 'text fill';

  @override
  String get roleShadingPattern => 'shading pattern';

  @override
  String get roleBorder => 'border';

  @override
  String get rolePageBackground => 'page background';

  @override
  String get roleGraphics => 'graphics';

  @override
  String get roleThemePalette => 'theme palette';

  @override
  String get roleOther => 'unspecified';

  @override
  String get familyRed => 'red';

  @override
  String get familyOrange => 'orange';

  @override
  String get familyGold => 'gold';

  @override
  String get familyGreen => 'green';

  @override
  String get familyTeal => 'teal';

  @override
  String get familyCyan => 'cyan';

  @override
  String get familyBlue => 'blue';

  @override
  String get familyPurple => 'purple';

  @override
  String get familyPink => 'pink';

  @override
  String get familyNeutral => 'neutral';

  @override
  String get toneVeryDark => 'very dark';

  @override
  String get toneDark => 'dark';

  @override
  String get toneMedium => 'medium';

  @override
  String get toneLight => 'light';

  @override
  String get toneVeryLight => 'very light';

  @override
  String get slotAscii => 'Latin';

  @override
  String get slotHighAnsi => 'Latin extended';

  @override
  String get slotComplexScript => 'Arabic / complex';

  @override
  String get slotEastAsian => 'East Asian';

  @override
  String get slotDrawing => 'graphics';

  @override
  String get identitiesHint =>
      'A set of colours and fonts you save once and apply to any document.';

  @override
  String get saveIdentity => 'Save as identity';

  @override
  String get saveIdentityDisabled =>
      'Change some colours first, then save them as an identity';

  @override
  String get identityName => 'Identity name';

  @override
  String get identityNameHint => 'e.g. Tuwaiq Academy';

  @override
  String get applyIdentity => 'Apply';

  @override
  String get deleteIdentity => 'Delete';

  @override
  String get noIdentities =>
      'No saved identities yet.\nChange some colours, then press \"Save as identity\".';

  @override
  String get documentFacts => 'What we found in the document';

  @override
  String get factDesignColors => 'Design colours';

  @override
  String get factInheritedColors => 'Inherited colours';

  @override
  String get factFonts => 'Fonts';

  @override
  String get factScannedParts => 'Parts scanned';

  @override
  String get export => 'Export document';

  @override
  String get exporting => 'Preparing the file…';

  @override
  String get exported => 'Saved';

  @override
  String get exportBlocked => 'Write cancelled — no file was created';

  @override
  String get exportBlockedWhy =>
      'We found a fault that could break the file when opened, so we stopped the save.';

  @override
  String get reportColorsReplaced => 'Colours replaced';

  @override
  String get reportFontsReplaced => 'Fonts replaced';

  @override
  String get reportPartsChanged => 'Parts changed';

  @override
  String get reportFontsProtected => 'Fonts protected';

  @override
  String reportUnmatched(Object colors) {
    return 'Colours you picked were not found in the document: $colors';
  }

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get reset => 'Undo all';

  @override
  String changesBadge(int count) {
    return '$count changes';
  }

  @override
  String get language => 'Language';

  @override
  String get aboutSection => 'About';

  @override
  String get aboutCopyright => '© 2026 m7md-d';

  @override
  String get aboutLicense =>
      'Free software under the GNU General Public License, version 3. Distributed with no warranty.';

  @override
  String get componentLicenses => 'Component licenses';

  @override
  String get sourceCode => 'Source code';

  @override
  String get roleShapeFill => 'Shape fill';

  @override
  String get sectionSlides => 'Slides';

  @override
  String get errUnsupportedFormat =>
      'This format is not supported. Supported today: Word (.docx) and PowerPoint (.pptx).';

  @override
  String get errForeignPartTouched =>
      'Internal fault: the format tried to write a part it does not own, so the export was stopped.';

  @override
  String get licensesTitle => 'Component licenses';

  @override
  String get licensesHint => 'The open-source libraries this app is built on';

  @override
  String get licensesLoading => 'Collecting licenses…';

  @override
  String get licensesEmpty => 'No licenses registered';

  @override
  String licenseEntries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licenses',
      one: 'One license',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Back';

  @override
  String get settings => 'Settings';

  @override
  String get fontsSection => 'Document fonts';

  @override
  String get fontsSectionHint =>
      'To show your file as it really looks we need its fonts. Whatever is not on your machine we fetch and keep here.';

  @override
  String get fetchFonts => 'Fetch missing fonts';

  @override
  String get fetchFontsHint =>
      'Only the font name leaves your machine — never the document\'s content or name.';

  @override
  String get cachedFonts => 'Saved fonts';

  @override
  String get cacheSize => 'Space used';

  @override
  String get deleteAllFonts => 'Delete all';

  @override
  String get deleteFont => 'Delete';

  @override
  String get noCachedFonts => 'No saved fonts yet.';

  @override
  String get fontDeletedNote =>
      'Deleted fonts stay on screen until the app restarts.';

  @override
  String get fontsMissingOne =>
      'One font is unavailable; the preview shows a substitute.';

  @override
  String fontsMissingMany(int count) {
    return '$count fonts are unavailable; the preview shows substitutes.';
  }

  @override
  String get fontsFetching => 'Fetching the document\'s fonts…';

  @override
  String get showDetails => 'Details';

  @override
  String get originBundled => 'Bundled with the app';

  @override
  String get originSystem => 'Installed on your machine';

  @override
  String get originCached => 'Saved here';

  @override
  String get originFetched => 'Just fetched';

  @override
  String get originUnavailable => 'Not found on Google Fonts';

  @override
  String get originOffline => 'Could not connect';

  @override
  String get originDisabled => 'Fetching is turned off in settings';

  @override
  String get errNotAnArchive =>
      'This is not a valid Word document — we could not open it.';

  @override
  String get errMissingContentTypes =>
      'The file is missing an essential part — it is not an Office document.';

  @override
  String get errChecksumMismatch => 'The file is damaged or incomplete.';

  @override
  String errMalformedXml(Object part) {
    return 'A part inside the document is damaged: $part';
  }

  @override
  String errEmptyTextNode(int count) {
    return 'We found $count places that break opening the file in Google Docs.';
  }

  @override
  String get errUnbalancedField =>
      'Word fields are unbalanced — page numbers or the table of contents would break.';

  @override
  String get errContentTypesNotFirst =>
      'The file\'s parts are in the wrong order — some programs would reject it.';

  @override
  String get errPartCountMismatch =>
      'The output part count does not match the source.';

  @override
  String get errPartNotFound => 'A required part is missing from the document.';

  @override
  String get errEncodeFailed => 'We could not build the output file.';

  @override
  String errUnmatchedMapping(Object colors) {
    return 'Colours in your plan were not found in the document: $colors';
  }
}
