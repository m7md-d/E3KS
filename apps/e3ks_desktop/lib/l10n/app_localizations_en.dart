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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0 · $role · $parts';
  }

  @override
  String occurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
      zero: 'No places',
    );
    return '$_temp0';
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
  String get inspectingDocument => 'Inspecting the document';

  @override
  String get previewLoadingRest => 'The remaining pages are still being read';

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
  String get export => 'Export';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
      zero: 'No changes',
    );
    return '$_temp0';
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
  String get noOtherFiles => 'No other files open';

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
  String get fontFolder => 'Font folder';

  @override
  String get fontFolderHint => 'An additional source for preview fonts.';

  @override
  String get fontFolderClear => 'Remove the folder';

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
    return '“$family” is not available. The app font was used.';
  }

  @override
  String fontsMissingMany(int count) {
    return '$count fonts are not available. The app font was used.';
  }

  @override
  String get fontsFetching => 'Fetching fonts…';

  @override
  String get showDetails => 'Details';

  @override
  String get retryFonts => 'Try again';

  @override
  String get originEmbedded => 'Embedded in the document';

  @override
  String get originBundled => 'Bundled with the app';

  @override
  String get originSystem => 'Installed on this machine';

  @override
  String get originFolder => 'From your font folder';

  @override
  String get originCached => 'Stored locally';

  @override
  String get originFetched => 'Fetched';

  @override
  String get originUnavailable => 'Not found on Google Fonts';

  @override
  String get originSubstituted => 'Metric-compatible substitute';

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
  String get batchOutput => 'Output folder';

  @override
  String get batchChoose => 'Choose…';

  @override
  String get batchConfirmSource => 'Read from this folder';

  @override
  String get batchConfirmOutput => 'Write into this folder';

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
  String get exportSetTitle => 'Export the set';

  @override
  String get exportSetHint =>
      'Each file with its effective plan; the tree structure is preserved.';

  @override
  String get exportSetRun => 'Export';

  @override
  String get exportThisFile => 'This file';

  @override
  String get exportWholeSet => 'The whole set';

  @override
  String get exportOverwrite => 'Overwrites an existing file';

  @override
  String exportOverwriteCount(int count) {
    return '$count destination paths are taken and will be overwritten';
  }

  @override
  String get exportRenamedPath => 'Path repeated, so it was numbered';

  @override
  String get exportNoChanges => 'No changes';

  @override
  String get exportDiskFailed => 'Writing to disk failed';

  @override
  String get exportSetEmpty => 'The set has no files.';

  @override
  String tabPosition(int at, int total) {
    return '$at / $total';
  }

  @override
  String get filesEmpty => 'No files yet. Add files or a folder.';

  @override
  String get filesPanel => 'Files';

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
  String get fileProperties => 'Properties';

  @override
  String get propsTitle => 'File properties';

  @override
  String get propsFormat => 'Format';

  @override
  String get propsSize => 'Size';

  @override
  String get propsModified => 'Last modified';

  @override
  String get propsPages => 'Pages';

  @override
  String get propsSlides => 'Slides';

  @override
  String propsSizeMb(double size) {
    final intl.NumberFormat sizeNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String sizeString = sizeNumberFormat.format(size);

    return '$sizeString MB';
  }

  @override
  String propsSizeKb(int size) {
    final intl.NumberFormat sizeNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String sizeString = sizeNumberFormat.format(size);

    return '$sizeString KB';
  }

  @override
  String get propsPlan => 'What the plan does to this file';

  @override
  String get propsColorsLabel => 'Colours replaced';

  @override
  String propsColorsValue(int mapped, int total, int spots) {
    final intl.NumberFormat mappedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String mappedString = mappedNumberFormat.format(mapped);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);
    final intl.NumberFormat spotsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String spotsString = spotsNumberFormat.format(spots);

    String _temp0 = intl.Intl.pluralLogic(
      spots,
      locale: localeName,
      other: '$spotsString occurrences',
      one: '1 occurrence',
    );
    return '$mappedString of $totalString · $_temp0';
  }

  @override
  String get propsNothing => 'Nothing';

  @override
  String get propsReaches => 'Reaches';

  @override
  String get propsMarksLabel => 'Marks removed';

  @override
  String propsOf(int part, int total) {
    final intl.NumberFormat partNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String partString = partNumberFormat.format(part);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$partString of $totalString';
  }

  @override
  String localizedCount(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString';
  }

  @override
  String get propsUnchanged => 'Unchanged';

  @override
  String get propsUntouched => 'Colours the plan does not touch';

  @override
  String get propsUntouchedHint =>
      'Present in this file\'s content with no rule to replace them.';

  @override
  String get propsAllMapped => 'Every content colour has a rule.';

  @override
  String get formatDocx => 'Word';

  @override
  String get formatPptx => 'PowerPoint';

  @override
  String get scopeFileOnly => 'This file only';

  @override
  String get scopeFileOnlyOn =>
      'The rule applies to this file alone. Clearing it moves the rule to the general plan.';

  @override
  String get scopeFileOnlyOff =>
      'The rule lives in the general plan. Checking it limits the rule to this file.';

  @override
  String get scopeExcluded => 'Excluded from the general plan';

  @override
  String get lockedBanner =>
      'This file is locked: the general plan does not apply to it.';

  @override
  String get fileNote => 'Note';

  @override
  String get fileNoteAdd => 'Write a note';

  @override
  String get fileNoteEdit => 'Edit the note';

  @override
  String get fileNoteHint => 'What to remember about this file';

  @override
  String get removeFromSet => 'Remove from the set';

  @override
  String get fileActions => 'File options';

  @override
  String get resetFileEdits => 'Undo this file\'s edits';

  @override
  String get resetGeneralEdits => 'Undo the general plan';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0 · $kind · $parts';
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
  String get tapMarkHint => 'Track this mark on the page';

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
  String get fitFallback => 'Not available';

  @override
  String get fitFallbackWhy => 'The app font was used.';

  @override
  String get fitSubstituteWhy => 'A metric-compatible substitute was used.';
}
