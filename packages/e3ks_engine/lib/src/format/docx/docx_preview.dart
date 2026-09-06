/// استخراج نموذج المعاينة من مستند Word.
///
/// قراءة محضة، ولا تُستدعى إلا مرّة واحدة عند فتح الملف. تطبيق الخطة على
/// المعاينة يجري في الذاكرة (`preview_restyler.dart`) فتكون الاستجابة فورية.
library;

import 'package:xml/xml.dart';

import '../../inspect/hex_color.dart';
import '../../inspect/text_mark.dart';
import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';
import '../../preview/preview_model.dart';
import 'docx_page_geometry.dart';
import 'docx_style_book.dart';

/// صمّام أمان لا حدّ عرض: الواجهة تعرض الصفحات على دفعات، فلا تكلفة على
/// المستند الطويل. ما بعد هذا الحدّ يُعلَن للمستخدم ولا يُخفى (`00` §5).
const int _maxBlocksPerSection = 4000;

const Map<String, PreviewSectionKind> _sectionKinds = {
  'document': PreviewSectionKind.body,
  'header': PreviewSectionKind.header,
  'footer': PreviewSectionKind.footer,
  'footnotes': PreviewSectionKind.footnotes,
  'endnotes': PreviewSectionKind.endnotes,
  'comments': PreviewSectionKind.comments,
};

final class DocxPreviewExtractor {
  const DocxPreviewExtractor();

  DocumentPreview extract(DocumentPackage package) {
    final sections = <PreviewSection>[];
    final book = StyleBook.read(package);
    PageGeometry? bodyGeometry;

    for (final partName in package.partNames) {
      final kind = _kindFor(partName);
      if (kind == null) continue;

      final text = package.textOf(partName);
      if (text == null) continue;

      final XmlDocument document;
      try {
        document = XmlDocument.parse(text);
      } on XmlException {
        continue; // الفحص يبلّغ عن الجزء التالف؛ المعاينة تتخطّاه بهدوء.
      }

      final body = document.rootElement;
      final children = _bodyChildren(body).toList();
      final geometries = geometriesForBody(children);

      final pages = <PreviewPage>[];
      var current = <PreviewBlock>[];
      var currentGeometry = PageGeometry.a4;
      var count = 0;
      var truncated = false;

      void closePage() {
        if (current.isEmpty) return;
        pages.add(
          PreviewPage(
            number: pages.length + 1,
            blocks: current,
            geometry: currentGeometry,
          ),
        );
        current = <PreviewBlock>[];
      }

      for (var i = 0; i < children.length; i++) {
        if (count >= _maxBlocksPerSection) {
          truncated = true;
          break;
        }
        for (final block in _readBlocks(children[i], book)) {
          count++;
          // فاصل الصفحة يقع **قبل** الكتلة التي تحمله.
          if (block.startsPage && current.isNotEmpty) closePage();
          // مقاس الصفحة مقاس أول كتلة فيها: القسم الأفقيّ يبدأ بفاصل صفحة.
          if (current.isEmpty) currentGeometry = geometries[i];
          current.add(block);
        }
      }
      closePage();

      if (pages.isEmpty) continue;
      if (kind == PreviewSectionKind.body) {
        bodyGeometry ??= pages.first.geometry;
      }

      sections.add(
        PreviewSection(
          partName: partName,
          kind: kind,
          pages: pages,
          truncated: truncated,
        ),
      );
    }

    return DocumentPreview(
      sections: _withBodyGeometry(sections, bodyGeometry ?? PageGeometry.a4),
    );
  }

  /// الترويسة والتذييل أجزاء مستقلّة بلا `sectPr` خاصّ بها، فتأخذ مقاس المتن.
  ///
  /// نصحّحها بعد المرور كلّه لأن ترتيب الأجزاء في الحاوية قد يضع الترويسة قبل
  /// المتن، فلا نعرف المقاس وقت قراءتها. البديل تحليل `document.xml` مرّتين،
  /// وهو أغلى جزء في المستند.
  List<PreviewSection> _withBodyGeometry(
    List<PreviewSection> sections,
    PageGeometry body,
  ) => [
    for (final section in sections)
      if (section.kind == PreviewSectionKind.body)
        section
      else
        PreviewSection(
          partName: section.partName,
          kind: section.kind,
          truncated: section.truncated,
          pages: [
            for (final page in section.pages)
              PreviewPage(
                number: page.number,
                blocks: page.blocks,
                geometry: body,
              ),
          ],
        ),
  ];

  PreviewSectionKind? _kindFor(String partName) {
    if (!partName.startsWith('word/') || !partName.endsWith('.xml')) {
      return null;
    }
    final leaf = partName.substring(5);
    if (leaf.contains('/')) return null;
    for (final entry in _sectionKinds.entries) {
      if (leaf == '${entry.key}.xml') return entry.value;
      if (leaf.startsWith(entry.key) &&
          RegExp(r'^\D+\d+\.xml$').hasMatch(leaf)) {
        return entry.value;
      }
    }
    return null;
  }

  Iterable<XmlElement> _bodyChildren(XmlElement root) {
    final body = root.getElement('body', namespace: wNs) ?? root;
    return body.childElements.where((e) => e.name.namespaceUri == wNs);
  }

  List<PreviewBlock> _readBlocks(XmlElement element, StyleBook book) =>
      switch (element.name.local) {
        'p' => [ParagraphBlock(_readParagraph(element, book))],
        'tbl' => _readTable(element, book),
        _ => const [],
      };

  /// يقرأ جدولًا، ويقسّمه عند الصفوف التي يبدأ عندها Word صفحةً جديدة.
  ///
  /// بلا هذا التقسيم تبتلع الجداول الطويلة فواصلَ صفحاتها، فيقلّ عدد الصفحات
  /// عن الحقيقة — وقد قاس ذلك اختبار الترقيم فعلًا (٢٤ بدل ٣٦).
  List<PreviewBlock> _readTable(XmlElement table, StyleBook book) {
    final properties = table.getElement('tblPr', namespace: wNs);
    final isRtl = properties?.getElement('bidiVisual', namespace: wNs) != null;
    final fractions = _columnFractions(table);

    final blocks = <PreviewBlock>[];
    var rows = <PreviewRow>[];
    var pendingBreak = false;

    void flush({required bool startsPage}) {
      if (rows.isEmpty) return;
      blocks.add(
        TableBlock(
          rows,
          isRtl: isRtl,
          startsPage: startsPage,
          columnFractions: fractions,
        ),
      );
      rows = <PreviewRow>[];
    }

    for (final row in table.findElements('tr', namespace: wNs)) {
      if (_breaksPage(row) && rows.isNotEmpty) {
        flush(startsPage: pendingBreak);
        pendingBreak = true;
      }
      final rowProperties = row.getElement('trPr', namespace: wNs);
      final isHeader =
          rowProperties?.getElement('tblHeader', namespace: wNs) != null;

      final cells = <PreviewCell>[];
      for (final cell in row.findElements('tc', namespace: wNs)) {
        final cellProperties = cell.getElement('tcPr', namespace: wNs);
        cells.add(
          PreviewCell(
            fill: _shadingFill(cellProperties),
            columnSpan:
                int.tryParse(
                  cellProperties
                          ?.getElement('gridSpan', namespace: wNs)
                          ?.getAttribute('val', namespace: wNs) ??
                      '',
                ) ??
                1,
            paragraphs: [
              for (final p in cell.findElements('p', namespace: wNs))
                _readParagraph(p, book),
            ],
          ),
        );
      }
      if (cells.isNotEmpty) {
        rows.add(PreviewRow(cells: cells, isHeader: isHeader));
      }
    }
    flush(startsPage: pendingBreak);
    return blocks;
  }

  /// نسب أعمدة الجدول من `w:tblGrid`، مطبَّعة على ١.
  List<double> _columnFractions(XmlElement table) {
    final grid = table.getElement('tblGrid', namespace: wNs);
    if (grid == null) return const [];

    final widths = <double>[];
    for (final column in grid.findElements('gridCol', namespace: wNs)) {
      final value = double.tryParse(
        column.getAttribute('w', namespace: wNs) ?? '',
      );
      // شبكة ناقصة لا تُخمَّن: عمود بلا عرض يفسد النسب كلّها.
      if (value == null || value <= 0) return const [];
      widths.add(value);
    }

    final total = widths.fold<double>(0, (sum, w) => sum + w);
    if (widths.isEmpty || total <= 0) return const [];
    return [for (final width in widths) width / total];
  }

  PreviewParagraph _readParagraph(XmlElement paragraph, StyleBook book) {
    final properties = paragraph.getElement('pPr', namespace: wNs);
    final styleName = properties
        ?.getElement('pStyle', namespace: wNs)
        ?.getAttribute('val', namespace: wNs);

    // الترتيب: المصرَّح في الفقرة، ثم نمطها، ثم `docDefaults`.
    final style = readParagraphProperties(properties)
        .over(readRunProperties(properties?.getElement('rPr', namespace: wNs)))
        .over(book.of(styleName));

    return PreviewParagraph(
      runs: _readRuns(paragraph, style),
      fill: _shadingFill(properties),
      align: _alignOf(properties),
      styleName: styleName,
      isRtl: properties?.getElement('bidi', namespace: wNs) != null,
      outlineLevel: _outlineLevel(style, styleName),
      startsPage: _breaksPage(paragraph),
      spaceBeforePt: style.spaceBeforePt ?? 0,
      spaceAfterPt: style.spaceAfterPt ?? 0,
      lineHeight: _lineHeight(style),
    );
  }

  /// ارتفاع السطر كمضاعف. القاعدة `exact`/`atLeast` تعطي مقدارًا بالنقاط،
  /// فنقسمه على حجم الخطّ لأن الراسم لا يعرف إلا المضاعف.
  double? _lineHeight(ParagraphStyle style) {
    if (style.lineMultiple != null) return style.lineMultiple;
    final exact = style.lineExactPt;
    final size = style.sizePt;
    if (exact == null || size == null || size <= 0) return null;
    return exact / size;
  }

  /// يقرأ مقاطع النصّ، متخطّيًا آلة الحقول وناتجها المخزَّن.
  ///
  /// المعاينة تعرض ما يراه القارئ؛ وتعليمة `PAGE` ليست نصًّا يُقرأ (`02` §4).
  List<PreviewRun> _readRuns(XmlElement paragraph, ParagraphStyle style) {
    final runs = <PreviewRun>[];
    var fieldDepth = 0;

    for (final child in paragraph.childElements) {
      if (child.name.namespaceUri != wNs) continue;

      // الروابط التشعّبية تحوي runs في مستوى أعمق.
      final containers = child.name.local == 'hyperlink'
          ? child.findElements('r', namespace: wNs)
          : (child.name.local == 'r' ? [child] : const <XmlElement>[]);

      for (final run in containers) {
        final fieldChar = run.getElement('fldChar', namespace: wNs);
        if (fieldChar != null) {
          final kind = fieldChar.getAttribute('fldCharType', namespace: wNs);
          if (kind == 'begin') fieldDepth++;
          if (kind == 'end') fieldDepth = fieldDepth > 0 ? fieldDepth - 1 : 0;
          continue;
        }
        if (run.getElement('instrText', namespace: wNs) != null) continue;
        if (fieldDepth > 0) continue;

        final text = StringBuffer();
        for (final node in run.childElements) {
          if (node.name.namespaceUri != wNs) continue;
          switch (node.name.local) {
            case 't':
              text.write(node.innerText);
            case 'tab':
              text.write('\t');
            case 'br':
              text.write('\n');
          }
        }
        if (text.isEmpty) continue;
        runs.add(_readRunStyle(run, text.toString(), style));
      }
    }
    return runs;
  }

  PreviewRun _readRunStyle(XmlElement run, String text, ParagraphStyle style) {
    final properties = run.getElement('rPr', namespace: wNs);
    final own = readRunProperties(properties);

    return PreviewRun(
      text: text,
      color: HexColor.tryParse(
        properties
            ?.getElement('color', namespace: wNs)
            ?.getAttribute('val', namespace: wNs),
      ),
      latinFont: own.latin ?? style.latin,
      arabicFont: own.arabic ?? style.arabic,
      sizePt: own.sizePt ?? style.sizePt,
      bold: own.bold ?? style.bold ?? false,
      italic: _isOn(properties, 'i'),
      underline: properties?.getElement('u', namespace: wNs) != null,
      shading: _shadingFill(properties),
      highlight: _pen(properties),
    );
  }

  /// هل تبدأ هذه الفقرة صفحةً جديدة؟
  ///
  /// مصدران: `w:br w:type="page"` فاصل صريح كتبه المؤلّف، و
  /// `w:lastRenderedPageBreak` وهو ترقيم Word المخزَّن وقت آخر حفظ.
  /// الثاني هو ما يمنحنا أرقام صفحات مطابقة لما يراه المستخدم في Word.
  bool _breaksPage(XmlElement paragraph) {
    for (final element in paragraph.descendants.whereType<XmlElement>()) {
      if (element.name.namespaceUri != wNs) continue;
      if (element.name.local == 'lastRenderedPageBreak') return true;
      if (element.name.local == 'br' &&
          element.getAttribute('type', namespace: wNs) == 'page') {
        return true;
      }
    }
    return false;
  }

  /// عناصر التبديل في OOXML: وجود العنصر يعني «مفعَّل» ما لم يقل `val="0"`.
  bool _isOn(XmlElement? properties, String name) {
    final element = properties?.getElement(name, namespace: wNs);
    if (element == null) return false;
    final value = element.getAttribute('val', namespace: wNs);
    return value != '0' && value != 'false';
  }

  /// قلم التمييز باسمه الثابت. `none` قولٌ صريح بلا تمييز.
  TextMark? _pen(XmlElement? properties) {
    final value = properties
        ?.getElement('highlight', namespace: wNs)
        ?.getAttribute('val', namespace: wNs);
    return (value == null || value == 'none')
        ? null
        : TextMark(MarkKind.highlight, value);
  }

  HexColor? _shadingFill(XmlElement? properties) => HexColor.tryParse(
    properties
        ?.getElement('shd', namespace: wNs)
        ?.getAttribute('fill', namespace: wNs),
  );

  PreviewAlign _alignOf(XmlElement? properties) {
    final value = properties
        ?.getElement('jc', namespace: wNs)
        ?.getAttribute('val', namespace: wNs);
    return switch (value) {
      'center' => PreviewAlign.center,
      'right' || 'end' => PreviewAlign.end,
      'both' || 'distribute' => PreviewAlign.justify,
      _ => PreviewAlign.start,
    };
  }

  int? _outlineLevel(ParagraphStyle style, String? styleName) {
    if (style.outlineLevel != null) return style.outlineLevel;

    // احتياطي بالاسم لمستند لا يصرّح بـ`outlineLvl` في أنماطه.
    final name = styleName?.toLowerCase().replaceAll(' ', '') ?? '';
    if (!name.startsWith('heading') && !name.startsWith('title')) return null;
    if (name.startsWith('title')) return 0;
    return (int.tryParse(name.substring(7)) ?? 1) - 1;
  }
}
