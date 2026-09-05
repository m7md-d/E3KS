/// خصائص الفقرات الموروثة من `styles.xml` و`docDefaults`.
///
/// **لماذا لزمنا هذا:** المعاينة كانت تخترع المسافات وأحجام العناوين، فتخرج
/// الصفحة أطول من ورقتها دائمًا. والمستند الواقعي يصرّح بالمسافة في ٩٣٪ من
/// فقراته (١٢١٦ من ١٣٠٩ في مستند القياس)، والباقي يرثها من نمطه.
///
/// **الحدّ:** نحلّ سلسلة `w:basedOn` للفقرات فقط، ولا نحاكي محرّك تخطيط Word.
/// الغرض أن يكون ارتفاع الصفحة قريبًا من الحقيقة، لا مطابقًا لها.
library;

import 'package:xml/xml.dart';

import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';

/// أقصى عمق لسلسلة `w:basedOn` — حارس ضدّ الدور المغلق في مستند تالف.
const int _maxInheritance = 12;

/// ما نقرؤه من نمط الفقرة. `null` تعني «لم يُصرَّح» لا «صفر».
final class ParagraphStyle {
  const ParagraphStyle({
    this.spaceBeforePt,
    this.spaceAfterPt,
    this.lineMultiple,
    this.lineExactPt,
    this.sizePt,
    this.bold,
    this.outlineLevel,
    this.latin,
    this.arabic,
  });

  static const ParagraphStyle empty = ParagraphStyle();

  final double? spaceBeforePt;
  final double? spaceAfterPt;

  /// `w:lineRule="auto"` — مضاعف ارتفاع السطر.
  final double? lineMultiple;

  /// `w:lineRule="exact"` أو `"atLeast"` — ارتفاع السطر بالنقاط.
  final double? lineExactPt;

  final double? sizePt;
  final bool? bold;
  final int? outlineLevel;
  final String? latin;
  final String? arabic;

  /// هذا النمط فوق أصله: المصرَّح هنا يفوز، والمسكوت عنه يُورَث.
  ParagraphStyle over(ParagraphStyle parent) => ParagraphStyle(
    spaceBeforePt: spaceBeforePt ?? parent.spaceBeforePt,
    spaceAfterPt: spaceAfterPt ?? parent.spaceAfterPt,
    // ارتفاع السطر قاعدة واحدة: مضاعف أو مقدار، فلا يُخلط نصفان.
    lineMultiple: (lineMultiple ?? lineExactPt) != null
        ? lineMultiple
        : parent.lineMultiple,
    lineExactPt: (lineMultiple ?? lineExactPt) != null
        ? lineExactPt
        : parent.lineExactPt,
    sizePt: sizePt ?? parent.sizePt,
    bold: bold ?? parent.bold,
    outlineLevel: outlineLevel ?? parent.outlineLevel,
    latin: latin ?? parent.latin,
    arabic: arabic ?? parent.arabic,
  );
}

/// أنماط المستند محلولةً مرّة واحدة عند الفتح.
final class StyleBook {
  const StyleBook({required this.defaults, required this.styles});

  static const StyleBook empty = StyleBook(
    defaults: ParagraphStyle.empty,
    styles: {},
  );

  /// `docDefaults` — ما يسري على فقرة بلا نمط.
  final ParagraphStyle defaults;

  /// أنماط الفقرات محلولة السلسلة، مفهرسة بـ`w:styleId`.
  final Map<String, ParagraphStyle> styles;

  ParagraphStyle of(String? styleId) =>
      styleId == null ? defaults : (styles[styleId] ?? defaults).over(defaults);

  static StyleBook read(DocumentPackage package) {
    final text = package.textOf('word/styles.xml');
    if (text == null) return empty;
    final XmlDocument document;
    try {
      document = XmlDocument.parse(text);
    } on XmlException {
      return empty; // الفحص يبلّغ عن الجزء التالف؛ المعاينة تتخطّاه.
    }

    final root = document.rootElement;
    final docDefaults = root.getElement('docDefaults', namespace: wNs);
    final defaults =
        readParagraphProperties(
          docDefaults
              ?.getElement('pPrDefault', namespace: wNs)
              ?.getElement('pPr', namespace: wNs),
        ).over(
          readRunProperties(
            docDefaults
                ?.getElement('rPrDefault', namespace: wNs)
                ?.getElement('rPr', namespace: wNs),
          ),
        );

    // تُقرأ خامًا أولًا ثم تُحلّ سلسلة `basedOn`، لأن النمط قد يسبق أصله.
    final raw = <String, ParagraphStyle>{};
    final basedOn = <String, String>{};
    for (final style in root.findElements('style', namespace: wNs)) {
      if (style.getAttribute('type', namespace: wNs) != 'paragraph') continue;
      final id = style.getAttribute('styleId', namespace: wNs);
      if (id == null) continue;

      raw[id] = readParagraphProperties(
        style.getElement('pPr', namespace: wNs),
      ).over(readRunProperties(style.getElement('rPr', namespace: wNs)));

      final parent = style
          .getElement('basedOn', namespace: wNs)
          ?.getAttribute('val', namespace: wNs);
      if (parent != null) basedOn[id] = parent;
    }

    return StyleBook(
      defaults: defaults,
      styles: {for (final id in raw.keys) id: _resolve(id, raw, basedOn)},
    );
  }

  static ParagraphStyle _resolve(
    String id,
    Map<String, ParagraphStyle> raw,
    Map<String, String> basedOn,
  ) {
    var result = raw[id] ?? ParagraphStyle.empty;
    var parent = basedOn[id];
    final seen = <String>{id};
    for (var depth = 0; parent != null && depth < _maxInheritance; depth++) {
      if (!seen.add(parent)) break; // دور مغلق في مستند تالف.
      result = result.over(raw[parent] ?? ParagraphStyle.empty);
      parent = basedOn[parent];
    }
    return result;
  }
}

/// `w:spacing` و`w:outlineLvl` من `pPr` — يُستعمل للأنماط وللفقرة نفسها.
ParagraphStyle readParagraphProperties(XmlElement? properties) {
  if (properties == null) return ParagraphStyle.empty;
  final spacing = properties.getElement('spacing', namespace: wNs);

  double? twips(String attribute) {
    final value = double.tryParse(
      spacing?.getAttribute(attribute, namespace: wNs) ?? '',
    );
    return value == null ? null : value / 20;
  }

  // `w:line` بالـ twip حين تكون القاعدة مقدارًا، وبالعشرينات من السطر
  // (‏240 = سطر واحد) حين تكون `auto`. خلطهما يضاعف ارتفاع المستند.
  final rule = spacing?.getAttribute('lineRule', namespace: wNs) ?? 'auto';
  final rawLine = double.tryParse(
    spacing?.getAttribute('line', namespace: wNs) ?? '',
  );

  return ParagraphStyle(
    spaceBeforePt: twips('before'),
    spaceAfterPt: twips('after'),
    lineMultiple: rawLine == null || rule != 'auto' ? null : rawLine / 240,
    lineExactPt: rawLine == null || rule == 'auto' ? null : rawLine / 20,
    outlineLevel: int.tryParse(
      properties
              .getElement('outlineLvl', namespace: wNs)
              ?.getAttribute('val', namespace: wNs) ??
          '',
    ),
  );
}

/// `w:sz` و`w:b` و`w:rFonts` من `rPr` — نفس الدالة للنمط وللمقطع.
ParagraphStyle readRunProperties(XmlElement? properties) {
  if (properties == null) return ParagraphStyle.empty;
  final fonts = properties.getElement('rFonts', namespace: wNs);
  final halfPoints = double.tryParse(
    properties
            .getElement('sz', namespace: wNs)
            ?.getAttribute('val', namespace: wNs) ??
        '',
  );
  final bold = properties.getElement('b', namespace: wNs);

  return ParagraphStyle(
    sizePt: halfPoints == null ? null : halfPoints / 2,
    bold: bold == null
        ? null
        : bold.getAttribute('val', namespace: wNs) != '0' &&
              bold.getAttribute('val', namespace: wNs) != 'false',
    latin: fonts?.getAttribute('ascii', namespace: wNs),
    arabic: fonts?.getAttribute('cs', namespace: wNs),
  );
}
