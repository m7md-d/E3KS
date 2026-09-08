/// جسر بين نماذج المحرّك وبين النصّ المعروض.
///
/// المحرّك يُرجع رموزًا لا كلمات (`01`)، وهذا الملف هو **الموضع الوحيد** الذي
/// يحوّلها إلى لغة المستخدم. إضافة لغة جديدة = ملف ARB فقط، بلا لمس هذا الملف.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/widgets.dart';

import '../data/document_loader.dart';
import '../data/font_service.dart';
import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  L get l10n => L.of(this);
}

extension ColorRoleText on ColorRole {
  String label(L t) => switch (this) {
    ColorRole.text => t.roleText,
    ColorRole.paragraphFill => t.roleParagraphFill,
    ColorRole.cellFill => t.roleCellFill,
    ColorRole.rowFill => t.roleRowFill,
    ColorRole.tableFill => t.roleTableFill,
    ColorRole.runFill => t.roleRunFill,
    ColorRole.shadingPattern => t.roleShadingPattern,
    ColorRole.border => t.roleBorder,
    ColorRole.shapeFill => t.roleShapeFill,
    ColorRole.pageBackground => t.rolePageBackground,
    ColorRole.graphics => t.roleGraphics,
    ColorRole.themePalette => t.roleThemePalette,
    ColorRole.other => t.roleOther,
  };
}

extension ColorFamilyText on ColorFamily {
  String label(L t) => switch (this) {
    ColorFamily.red => t.familyRed,
    ColorFamily.orange => t.familyOrange,
    ColorFamily.gold => t.familyGold,
    ColorFamily.green => t.familyGreen,
    ColorFamily.teal => t.familyTeal,
    ColorFamily.cyan => t.familyCyan,
    ColorFamily.blue => t.familyBlue,
    ColorFamily.purple => t.familyPurple,
    ColorFamily.pink => t.familyPink,
    ColorFamily.neutral => t.familyNeutral,
  };
}

extension ColorToneText on ColorTone {
  String label(L t) => switch (this) {
    ColorTone.veryDark => t.toneVeryDark,
    ColorTone.dark => t.toneDark,
    ColorTone.medium => t.toneMedium,
    ColorTone.light => t.toneLight,
    ColorTone.veryLight => t.toneVeryLight,
  };
}

extension HexColorText on HexColor {
  /// وصف مختصر مثل «أزرق مخضرّ داكن» أو "dark teal".
  String describe(L t) => '${family.label(t)} ${tone.label(t)}';
}

extension MarkKindText on MarkKind {
  String label(L t) => switch (this) {
    MarkKind.highlight => t.markHighlight,
    MarkKind.textShading => t.markShading,
  };
}

extension FontSlotText on FontSlot {
  String label(L t) => switch (this) {
    FontSlot.ascii => t.slotAscii,
    FontSlot.highAnsi => t.slotHighAnsi,
    FontSlot.complexScript => t.slotComplexScript,
    FontSlot.eastAsian => t.slotEastAsian,
    FontSlot.drawing => t.slotDrawing,
  };
}

extension PreviewSectionKindText on PreviewSectionKind {
  String label(L t) => switch (this) {
    PreviewSectionKind.body => t.sectionBody,
    PreviewSectionKind.header => t.sectionHeader,
    PreviewSectionKind.footer => t.sectionFooter,
    PreviewSectionKind.footnotes => t.sectionFootnotes,
    PreviewSectionKind.endnotes => t.sectionEndnotes,
    PreviewSectionKind.comments => t.sectionComments,
    PreviewSectionKind.slides => t.sectionSlides,
  };
}

extension FontOriginText on FontOrigin {
  String label(L t) => switch (this) {
    FontOrigin.embedded => t.originEmbedded,
    FontOrigin.bundled => t.originBundled,
    FontOrigin.system => t.originSystem,
    FontOrigin.folder => t.originFolder,
    FontOrigin.cached => t.originCached,
    FontOrigin.fetched => t.originFetched,
    FontOrigin.unavailable => t.originUnavailable,
    FontOrigin.substituted => t.originSubstituted,
    FontOrigin.offline => t.originOffline,
    FontOrigin.disabled => t.originDisabled,
  };
}

/// حجم بصيغة يقرأها الإنسان. الأرقام الخام لا تعني شيئًا لمن يراقب قرصه.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// اسم الجزء كما يفهمه المستخدم، لا كما هو في الأرشيف.
String partLabel(L t, String partName) {
  if (partName.contains('header')) return t.sectionHeader;
  if (partName.contains('footer')) return t.sectionFooter;
  if (partName.contains('document')) return t.sectionBody;
  if (partName.contains('footnotes')) return t.sectionFootnotes;
  if (partName.contains('endnotes')) return t.sectionEndnotes;
  if (partName.contains('comments')) return t.sectionComments;
  if (partName.contains('styles')) return t.partStyles;
  if (partName.contains('theme')) return t.partTheme;
  if (partName.contains('numbering')) return t.partNumbering;
  return partName;
}

/// اسم الصيغة بلغة المستخدم.
///
/// **الاسم للعرض وحده.** القرار في الصيغة يبقى داخل `format/` (`01`)،
/// وهذا ترجمةُ تعدادٍ كما يفعل [issueText] و[partLabel].
String formatLabel(L t, FormatId id) => switch (id) {
  FormatId.docx => t.formatDocx,
  FormatId.pptx => t.formatPptx,
};

/// صياغة مشكلة من المحرّك بلغة المستخدم.
String issueText(L t, EngineIssue issue) => switch (issue.code) {
  IssueCode.notAnArchive => t.errNotAnArchive,
  IssueCode.missingContentTypes => t.errMissingContentTypes,
  IssueCode.checksumMismatch => t.errChecksumMismatch,
  IssueCode.malformedXml => t.errMalformedXml(partLabel(t, issue.part ?? '')),
  IssueCode.emptyTextNode => t.errEmptyTextNode(
    (issue.args['count'] as int?) ?? 0,
  ),
  IssueCode.unbalancedField => t.errUnbalancedField,
  IssueCode.contentTypesNotFirst => t.errContentTypesNotFirst,
  IssueCode.partCountMismatch => t.errPartCountMismatch,
  IssueCode.partNotFound => t.errPartNotFound,
  IssueCode.encodeFailed => t.errEncodeFailed,
  IssueCode.unmatchedMapping => t.errUnmatchedMapping(
    (issue.args['colors'] as List?)?.join('، ') ?? '',
  ),
  IssueCode.unsupportedFormat => t.errUnsupportedFormat,
  IssueCode.foreignPartTouched => t.errForeignPartTouched,
};

/// أسباب الفشل التي حُفظت وقت التحميل، مصاغةً الآن بلغة المستخدم.
///
/// التخزين بالرموز لا بالنصّ: لو بدّل المستخدم اللغة بعد الخطأ تُترجم الرسالة
/// معه، ولا تبقى محنّطة بلغة قديمة.
List<String> failureLines(L t, LoadFailure failure) => [
  for (final issue in failure.issues) issueText(t, issue),
];

/// اسم اللغة بلغتها نفسها.
///
/// يُقرأ من ملف ARB الخاص بتلك اللغة (`languageName`) لا من جدول في الكود —
/// فإضافة لغة ثالثة لا تتطلّب لمس أي سطر برمجي. ولا نترجم أسماء اللغات:
/// «الإنجليزية» مكتوبةً بالعربية تعمي عنها من لا يقرأ العربية.
String nativeLanguageName(Locale locale) => lookupL(locale).languageName;
