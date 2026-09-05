/// نموذج مبسّط لمحتوى المستند، كافٍ لرسم معاينة صادقة.
///
/// ليس محرّك تخطيط ولا محاكاة لـ Word. الغرض محدّد: أن يرى المستخدم **ما
/// سيتغيّر فعلًا** بألوانه وخطوطه الحقيقية قبل أن يضغط «صدّر» (`05`، الطبقة ٢).
///
/// **حدّ معروف:** نقرأ الخصائص المصرَّحة مباشرةً (`rPr`/`pPr`) مع احتياطي من
/// `docDefaults`. لا نحلّ سلسلة وراثة الأنماط كاملة — وهذا يكفي لأن ألوان
/// الهوية في مستندات الواقع مصرَّحة مباشرةً في الغالب الأعمّ.
library;

import '../inspect/hex_color.dart';

/// مقطع نصّي بخصائصه.
final class PreviewRun {
  const PreviewRun({
    required this.text,
    this.color,
    this.latinFont,
    this.arabicFont,
    this.sizePt,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.shading,
  });

  final String text;
  final HexColor? color;
  final String? latinFont;
  final String? arabicFont;
  final double? sizePt;
  final bool bold;
  final bool italic;
  final bool underline;

  /// خلفية النصّ نفسه (`w:shd` داخل `rPr`).
  final HexColor? shading;

  PreviewRun copyWith({
    HexColor? color,
    String? latinFont,
    String? arabicFont,
    HexColor? shading,
  }) => PreviewRun(
    text: text,
    color: color ?? this.color,
    latinFont: latinFont ?? this.latinFont,
    arabicFont: arabicFont ?? this.arabicFont,
    sizePt: sizePt,
    bold: bold,
    italic: italic,
    underline: underline,
    shading: shading ?? this.shading,
  );
}

enum PreviewAlign { start, center, end, justify }

final class PreviewParagraph {
  const PreviewParagraph({
    required this.runs,
    this.fill,
    this.align = PreviewAlign.start,
    this.styleName,
    this.isRtl = false,
    this.outlineLevel,
    this.startsPage = false,
    this.spaceBeforePt = 0,
    this.spaceAfterPt = 0,
    this.lineHeight,
  });

  final List<PreviewRun> runs;

  /// خلفية الفقرة (`w:shd` داخل `pPr`).
  final HexColor? fill;

  final PreviewAlign align;

  /// اسم النمط كما ورد (`w:pStyle`) — يُستعمل لتمييز العناوين.
  final String? styleName;

  final bool isRtl;

  /// مستوى العنوان إن كان عنوانًا (0 = العنوان الأعلى).
  final int? outlineLevel;

  /// تبدأ هذه الفقرة صفحةً جديدة حسب ترقيم Word المخزَّن.
  final bool startsPage;

  /// `w:spacing` بالنقاط، محلولةً من الفقرة ثم نمطها ثم `docDefaults`.
  ///
  /// اختراعها بدل قراءتها كان يجعل كل صفحة أطول من ورقتها.
  final double spaceBeforePt;
  final double spaceAfterPt;

  /// مضاعف ارتفاع السطر. `null` تعني «لم يُصرَّح» فيتولّاها الراسم.
  final double? lineHeight;

  bool get isHeading => outlineLevel != null;

  String get text => runs.map((r) => r.text).join();
  bool get isEmpty => text.trim().isEmpty;
}

final class PreviewCell {
  const PreviewCell({required this.paragraphs, this.fill, this.columnSpan = 1});

  final List<PreviewParagraph> paragraphs;

  /// خلفية الخلية — أكثر أدوار اللون شيوعًا في مستندات الجداول.
  final HexColor? fill;

  final int columnSpan;
}

final class PreviewRow {
  const PreviewRow({required this.cells, this.isHeader = false});
  final List<PreviewCell> cells;
  final bool isHeader;
}

/// موضع كتلة على الصفحة بالنقاط.
///
/// **الفرق الجوهري بين Word وPowerPoint.** مستند Word تدفّق: الفقرة تلي التي
/// قبلها. والشريحة **لوحة**: كل شكل يعلن موضعه ومقاسه صراحةً. عرض الشريحة
/// تدفّقًا رأسيًّا يجعل المعاينة كذبًا.
///
/// `null` تعني «هذا المستند تدفّق» — فيبقى Word على ما هو.
final class BlockFrame {
  const BlockFrame({
    required this.leftPt,
    required this.topPt,
    required this.widthPt,
    required this.heightPt,
  });

  final double leftPt;
  final double topPt;
  final double widthPt;
  final double heightPt;
}

/// كتلة في المستند: فقرة أو جدول.
sealed class PreviewBlock {
  const PreviewBlock();

  /// تبدأ هذه الكتلة صفحةً جديدة حسب ترقيم Word المخزَّن.
  bool get startsPage;

  /// موضعها المعلَن، أو `null` إن كانت في تدفّق.
  BlockFrame? get frame => null;
}

final class ParagraphBlock extends PreviewBlock {
  const ParagraphBlock(this.paragraph);
  final PreviewParagraph paragraph;

  @override
  bool get startsPage => paragraph.startsPage;
}

final class TableBlock extends PreviewBlock {
  const TableBlock(
    this.rows, {
    this.isRtl = false,
    this.startsPage = false,
    this.columnFractions = const [],
    this.frame,
  });

  @override
  final BlockFrame? frame;

  final List<PreviewRow> rows;

  /// نسب عرض الأعمدة من `w:tblGrid`، مجموعها ١. فارغة إن لم يصرّح المستند.
  ///
  /// توزيع الأعمدة بالتساوي بدل قراءتها يضاعف التفاف النصّ في العمود الضيّق،
  /// فيطول الجدول كثيرًا عن حقيقته — وهو أكبر سبب لتجاوز الصفحة ورقتها.
  final List<double> columnFractions;

  /// ترتيب الأعمدة معكوس (`w:bidiVisual`) — العمود الأول يمينًا.
  final bool isRtl;

  /// جدول طويل يمتدّ على صفحات يُقسَّم عند صفوفه الفاصلة، فتحمل القطعة
  /// الثانية فما بعدها هذه الراية.
  @override
  final bool startsPage;
}

/// شكل على شريحة: فقرات داخل إطار معلَن.
///
/// وحدة PowerPoint ليست الفقرة بل **الشكل**: صندوق له موضع ومقاس وخلفية،
/// تتدفّق الفقرات داخله. تفكيكه إلى فقرات مستقلّة يُضيّع التخطيط كلّه.
final class ShapeBlock extends PreviewBlock {
  const ShapeBlock({
    required this.paragraphs,
    this.frame,
    this.fill,
    this.startsPage = false,
  });

  final List<PreviewParagraph> paragraphs;

  @override
  final BlockFrame? frame;

  /// تعبئة الشكل — أكثر أدوار اللون ظهورًا في العروض التقديمية.
  final HexColor? fill;

  @override
  final bool startsPage;

  bool get isEmpty => paragraphs.every((p) => p.isEmpty);
}

/// معاينة جزء واحد من المستند (المتن أو ترويسة أو تذييل).
/// نوع القسم. **بلا نصّ معروض** — تسميته شأن الواجهة (`01`).
enum PreviewSectionKind {
  body,
  header,
  footer,
  footnotes,
  endnotes,
  comments,

  /// شرائح العرض التقديمي.
  slides,
}

/// مقاس الصفحة وهوامشها كما صرّح بها المستند (`w:sectPr`).
///
/// بالنقاط الطباعية (1pt = 1/72 بوصة). القيم في OOXML بالـ twip (1/20 نقطة)،
/// وتُحوَّل هنا مرّة واحدة فلا يرى بقيّة الكود وحدةً غريبة.
///
/// **لماذا نقرؤها أصلًا:** الورقة المرسومة بمقاس محتواها تختلف من صفحة إلى
/// أخرى، فيفقد المستخدم إحساس الصفحة ولا يعرف أين ينتهي الهامش. المعاينة
/// تَعِد بعرض الملف بشكله الحقيقي، والمقاس جزء من الشكل.
final class PageGeometry {
  const PageGeometry({
    required this.widthPt,
    required this.heightPt,
    required this.marginTopPt,
    required this.marginRightPt,
    required this.marginBottomPt,
    required this.marginLeftPt,
  });

  /// A4 بهوامش بوصة — ما يفترضه Word حين لا يصرّح المستند بشيء.
  static const PageGeometry a4 = PageGeometry(
    widthPt: 595.3,
    heightPt: 841.9,
    marginTopPt: 72,
    marginRightPt: 72,
    marginBottomPt: 72,
    marginLeftPt: 72,
  );

  final double widthPt;
  final double heightPt;

  /// هوامش **فيزيائية** لا منطقية: `w:pgMar` يقول `left`/`right` ويعني
  /// اليسار واليمين على الورقة، ولو كان المستند عربيًّا. تسميتها
  /// `start`/`end` تقلبها في مستند RTL — خطأ صامت في المعاينة.
  final double marginRightPt;
  final double marginLeftPt;

  final double marginTopPt;
  final double marginBottomPt;

  bool get isLandscape => widthPt > heightPt;

  @override
  bool operator ==(Object other) =>
      other is PageGeometry &&
      other.widthPt == widthPt &&
      other.heightPt == heightPt &&
      other.marginTopPt == marginTopPt &&
      other.marginRightPt == marginRightPt &&
      other.marginBottomPt == marginBottomPt &&
      other.marginLeftPt == marginLeftPt;

  @override
  int get hashCode => Object.hash(
    widthPt,
    heightPt,
    marginTopPt,
    marginRightPt,
    marginBottomPt,
    marginLeftPt,
  );
}

/// صفحة واحدة كما رقّمها Word نفسه.
///
/// الحدود مأخوذة من `w:lastRenderedPageBreak` — ترقيم Word المخزَّن وقت آخر
/// حفظ. لسنا نحسب التخطيط، بل نقرأ ما حسبه Word، فالأرقام **حقيقية** لا
/// مُخترَعة، وهذا فرق جوهري: رقم صفحة مزيّف يقود المستخدم إلى خطأ.
final class PreviewPage {
  const PreviewPage({
    required this.number,
    required this.blocks,
    this.geometry = PageGeometry.a4,
  });

  /// رقم الصفحة داخل قسمها، يبدأ من ١.
  final int number;

  final List<PreviewBlock> blocks;

  /// مقاس هذه الصفحة. قد يختلف داخل المستند الواحد: قسمٌ أفقيّ لجدول عريض
  /// أمرٌ شائع، وعرضه بمقاس الصفحات الرأسية يكذب على المستخدم.
  final PageGeometry geometry;
}

final class PreviewSection {
  const PreviewSection({
    required this.partName,
    required this.kind,
    required this.pages,
    required this.truncated,
  });

  final String partName;

  final PreviewSectionKind kind;

  final List<PreviewPage> pages;

  /// تجاوز المستند الحدّ فاقتُطع — نُخبر المستخدم ولا نخفيه (`00` §5).
  final bool truncated;

  Iterable<PreviewBlock> get blocks => [
    for (final page in pages) ...page.blocks,
  ];
}

final class DocumentPreview {
  const DocumentPreview({required this.sections});
  final List<PreviewSection> sections;

  bool get isEmpty => sections.every((s) => s.pages.isEmpty);

  int get pageCount =>
      sections.fold(0, (sum, section) => sum + section.pages.length);
}
