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
  String get tagline => 'Colour and font replacement for Office documents';

  @override
  String get languageName => 'English';

  @override
  String get dropHere => 'Drop a Word or PowerPoint file here';

  @override
  String get orDivider => '— or —';

  @override
  String get chooseFile => 'Choose a file…';

  @override
  String get supported => 'Supported formats: .docx and .pptx';

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
  String get identityColors => 'Content colours';

  @override
  String get identityColorsHint =>
      'Colours that appear in the document\'s content.';

  @override
  String get inheritedColors => 'Inherited colours';

  @override
  String get inheritedColorsHint =>
      'Colours defined in Word templates that do not appear in the content.';

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
      'Colours from other open documents appear here.';

  @override
  String get fromSavedIdentities => 'From saved identities';

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
      'Latin and Arabic fonts are separate in OOXML; each is set on its own.';

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
      'Monospaced fonts. Excluded from replacement because substituting them changes alignment.';

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
  String get inspectingDocument => 'Reading the document';

  @override
  String get previewLoadingRest => 'The remaining pages are still being read';

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
      'A saved set of colours and fonts, applied to any document.';

  @override
  String get saveIdentity => 'Save as identity';

  @override
  String get saveIdentityDisabled => 'No changes to save';

  @override
  String get identityName => 'Identity name';

  @override
  String get identityNameHint => 'e.g. Tuwaiq Academy';

  @override
  String get applyIdentity => 'Apply';

  @override
  String get deleteIdentity => 'Delete';

  @override
  String get noIdentities => 'No saved identities.';

  @override
  String get documentFacts => 'Scan results';

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
  String get exporting => 'Exporting…';

  @override
  String get exported => 'Saved';

  @override
  String get exportBlocked => 'Write cancelled — no file was created';

  @override
  String get exportBlockedWhy =>
      'The output failed validation, so the write was cancelled.';

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
    return 'Colours not found in the document: $colors';
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
  String get licensesHint => 'Open-source libraries used by the app';

  @override
  String get licensesLoading => 'Loading…';

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
  String get focusedColor => 'Tracking colour';

  @override
  String get clearFocus => 'Stop tracking';

  @override
  String get noMatches => 'No matches';

  @override
  String get tapColorHint => 'Track this colour on the page';

  @override
  String get nextMatch => 'Next match';

  @override
  String get previousMatch => 'Previous match';

  @override
  String get extractIdentity => 'Extract identity from an open file';

  @override
  String get extractIdentityHint => 'The file\'s colours, ordered by use';

  @override
  String extractFrom(String file) {
    return 'Extract from: $file';
  }

  @override
  String get noOtherFiles => 'No other files open';

  @override
  String get quickPick => 'Quick pick';

  @override
  String get quickPickHint => 'Colours extracted from open files';

  @override
  String get labelPrimary => 'Primary';

  @override
  String get labelText => 'Text colour';

  @override
  String get labelBackground => 'Background';

  @override
  String get labelAccent => 'Accent';

  @override
  String get goToPage => 'Go to page';

  @override
  String get showChangeMarks => 'Show change marks';

  @override
  String get pickColorToTrack => 'Pick a colour from the page';

  @override
  String get shadesOf => 'Shades of this colour';

  @override
  String get shadesHint => 'Computed from the selected colour';

  @override
  String get settings => 'Settings';

  @override
  String get fontsSection => 'Document fonts';

  @override
  String get fontsSectionHint =>
      'The preview uses the document\'s fonts. Those not installed are fetched and stored here.';

  @override
  String get fetchFonts => 'Fetch missing fonts';

  @override
  String get fetchFontsHint =>
      'Only the font name is sent; the document and its name are not.';

  @override
  String get cachedFonts => 'Saved fonts';

  @override
  String get cacheSize => 'Space used';

  @override
  String get deleteAllFonts => 'Delete all';

  @override
  String get addFont => 'Add a font';

  @override
  String fontAdded(String family) {
    return 'Added $family';
  }

  @override
  String get fontAddFailed => 'The file could not be read as a font';

  @override
  String get hideNotice => 'Hide';

  @override
  String get deleteFont => 'Delete';

  @override
  String get noCachedFonts => 'No stored fonts.';

  @override
  String get fontDeletedNote =>
      'Deleted fonts stay on screen until the app restarts.';

  @override
  String fontsMissingOne(Object family) {
    return '“$family” is not available; it is drawn with the app font.';
  }

  @override
  String fontsMissingMany(int count) {
    return '$count fonts are not available; they are drawn with the app font.';
  }

  @override
  String get fontsFetching => 'Fetching fonts…';

  @override
  String get showDetails => 'Details';

  @override
  String get originBundled => 'Bundled with the app';

  @override
  String get originSystem => 'Installed on this machine';

  @override
  String get originCached => 'Stored locally';

  @override
  String get originFetched => 'Fetched';

  @override
  String get originUnavailable => 'Not found on Google Fonts';

  @override
  String get originSubstituted => 'Drawn with a metric-compatible stand-in';

  @override
  String get originOffline => 'Could not connect';

  @override
  String get originDisabled => 'Fetching is turned off in settings';

  @override
  String get errNotAnArchive =>
      'Not a valid OOXML archive; it could not be opened.';

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
    return '$count places break opening the file in Google Docs.';
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
  String get errEncodeFailed => 'The output file could not be built.';

  @override
  String errUnmatchedMapping(Object colors) {
    return 'Colours in the plan were not found in the document: $colors';
  }

  @override
  String get cancelPicking => 'Cancel picking';

  @override
  String get pickingHint => 'Picking a colour — Esc to cancel';

  @override
  String get noColorMatch => 'No matching colour';

  @override
  String get batchTitle => 'Apply to a folder';

  @override
  String get batchHint =>
      'The same plan on every document in the folder and below; the structure is kept.';

  @override
  String get batchSource => 'Folder';

  @override
  String get batchOutput => 'Output folder';

  @override
  String get batchChoose => 'Choose…';

  @override
  String get batchConfirmSource => 'Read from this folder';

  @override
  String get batchConfirmOutput => 'Write into this folder';

  @override
  String batchDocuments(int count) {
    return '$count documents';
  }

  @override
  String get batchPlan => 'Plan';

  @override
  String get batchFromOpen => 'The open file\'s plan';

  @override
  String get batchRun => 'Run';

  @override
  String batchProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get batchWritten => 'Written';

  @override
  String get batchFailedCount => 'Failed';

  @override
  String get batchUnchanged => 'Unchanged';

  @override
  String get batchNeverMatched => 'Colours in the plan matched no file';

  @override
  String get batchEmptyFolder => 'No supported documents in this folder.';

  @override
  String get batchNoPlan => 'Change some colours or pick a saved identity.';

  @override
  String get batchSameFolder =>
      'The output folder is the source; the source is never written over.';

  @override
  String tabPosition(int at, int total) {
    return '$at / $total';
  }

  @override
  String get filesEmpty => 'No files yet. Add files or a folder.';

  @override
  String get filesPanel => 'Files';

  @override
  String get openFolder => 'Open a folder';

  @override
  String get looseFiles => 'Added files';

  @override
  String get addFiles => 'Add files';

  @override
  String get addFolder => 'Add a folder';

  @override
  String get fileLocked => 'Excluded from the general plan';

  @override
  String get fileReviewed => 'Reviewed';

  @override
  String get tabMarks => 'Highlights';

  @override
  String get marksTitle => 'Text marks';

  @override
  String get marksHint =>
      'Highlighter pen and background shading. Removal applies to this file only.';

  @override
  String get emptyMarks => 'Open a document to see its marks.';

  @override
  String get noMarks => 'No marks in this document.';

  @override
  String get markHighlight => 'Highlighter';

  @override
  String get markShading => 'Text shading';

  @override
  String markUsage(int count, Object kind, Object parts) {
    return '$count places · $kind · $parts';
  }

  @override
  String get liftAll => 'Remove all';

  @override
  String get keepAll => 'Keep all';

  @override
  String get liftMark => 'Remove';

  @override
  String get markLifted => 'Will be removed';

  @override
  String get focusedMark => 'Tracked mark';

  @override
  String get tapMarkHint => 'Tap to track its places';

  @override
  String get reportMarksLifted => 'Marks removed';

  @override
  String get exportFailed => 'Could not write the file';

  @override
  String get exportFailedWhy =>
      'No file was created. Try another location, such as Documents or the Desktop.';

  @override
  String get fitSubstitute => 'Metric substitute';

  @override
  String get fitFallback => 'Not available here';

  @override
  String get fitFallbackWhy =>
      'Drawn with the app font, so the preview is approximate.';

  @override
  String get fitSubstituteWhy =>
      'Drawn with a metric-compatible substitute: the layout is right, the letterforms are not.';
}
