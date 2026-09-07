/// استخراج نموذج المعاينة من مستند Word.
///
/// قراءة محضة، ولا تُستدعى إلا مرّة واحدة عند فتح الملف. تطبيق الخطة على
/// المعاينة يجري في الذاكرة (`preview_restyler.dart`) فتكون الاستجابة فورية.
///
/// **ولا تُبنى شجرة المستند كاملةً.** يُقرأ التدفّق ويُجمَّع **ابنٌ واحد من
/// `w:body` في وقته** فيُقرأ ثم يُرمى، فتصير ذروة الذاكرة أطولَ فقرةٍ أو
/// جدولٍ في الملف لا الملفَّ كلّه. وقراءة الكتلة نفسها لم تتغيّر: ما تحتاجه
/// من شجرة يقع كلّه داخل تلك الشجرة الصغيرة.
library;

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

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

  DocumentPreview extract(DocumentPackage package, {int? maxPages}) {
    final sections = <PreviewSection>[];
    final book = StyleBook.read(package);
    PageGeometry? bodyGeometry;

    for (final partName in package.partNames) {
      final kind = _kindFor(partName);
      if (kind == null) continue;

      final text = package.textOf(partName);
      if (text == null) continue;

      final builder = _SectionBuilder(maxPages);
      var index = 0;
      for (final child in _bodyChildren(text)) {
        if (builder.full) break;
        // `w:sectPr` يصف القسم الذي **ينتهي** عنده (`02` §7/1)، فيُحلّ به
        // مقاسُ كل صفحةٍ معلَّقة بدأت قبله.
        final mark = _sectionMark(child);
        for (final block in _readBlocks(child, book)) {
          builder.add(index, block);
        }
        if (mark != null) builder.resolveUpTo(index, mark);
        index++;
      }
      final pages = builder.finish();

      if (pages.isEmpty) continue;
      final truncated = builder.full;
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

  /// أبناء `w:body` واحدًا واحدًا، مبنيّين من التدفّق ومرميّين بعد قراءتهم.
  ///
  /// **ولا `body` في الترويسة والتذييل**: جذرها `w:hdr`/`w:ftr` وأبناؤه هم
  /// الفقرات مباشرةً. فالقاعدة: ننزل داخل `w:body` إن وجدناه، وإلّا فأبناء
  /// الجذر هم المقصودون — وهو نفس ما كان يفعله `getElement('body') ?? root`.
  /// وما ليس فقرةً ولا جدولًا (`w:background` مثلًا) يتخطّاه [_readBlocks].
  Iterable<XmlElement> _bodyChildren(String text) sync* {
    var depth = 0;
    var containerDepth = 1;
    var collecting = <XmlEvent>[];
    var collectDepth = -1;

    // **إعلانات `xmlns` تسكن الجذر، والشجرة المقتطعة لا تحملها.** فبلا
    // إحاطتها بجذرها تصير مساحةُ كل عنصرٍ فيها `null`، ويرجع كل
    // `getElement(..., namespace: wNs)` فارغًا — فقرات بلا خصائص ولا
    // فواصل ولا `sectPr`. تُلفّ بجذرها، فتُحلّ البادئات كما تُحلّ في الملف.
    XmlStartElementEvent? root;

    for (final event in parseEvents(text)) {
      switch (event) {
        case XmlStartElementEvent():
          if (depth == 0) root = event;
          if (collectDepth < 0 &&
              depth == containerDepth &&
              _localOf(event.name) == 'body') {
            // الجذر `w:document`: المقصود ما داخل `w:body` لا ما جاوره.
            containerDepth = depth + 1;
            if (!event.isSelfClosing) depth++;
            continue;
          }
          if (collectDepth < 0 && depth == containerDepth) {
            collectDepth = depth;
            collecting = [event];
            if (event.isSelfClosing) {
              yield* _elementsOf(root, collecting);
              collectDepth = -1;
            }
          } else if (collectDepth >= 0) {
            collecting.add(event);
          }
          if (!event.isSelfClosing) depth++;

        case XmlEndElementEvent():
          depth--;
          if (collectDepth >= 0) {
            collecting.add(event);
            if (depth == collectDepth) {
              yield* _elementsOf(root, collecting);
              collectDepth = -1;
              collecting = <XmlEvent>[];
            }
          }

        default:
          if (collectDepth >= 0) collecting.add(event);
      }
    }
  }

  Iterable<XmlElement> _elementsOf(
    XmlStartElementEvent? root,
    List<XmlEvent> events,
  ) {
    if (root == null) return const [];
    final wrapped = <XmlEvent>[
      XmlStartElementEvent(root.name, root.attributes, false),
      ...events,
      XmlEndElementEvent(root.name),
    ];
    return const XmlNodeDecoder()
        .convert(wrapped)
        .whereType<XmlElement>()
        .expand((element) => element.childElements);
  }

  /// مقاس الصفحة الذي يعلنه هذا الابن، إن أعلن.
  PageGeometry? _sectionMark(XmlElement child) {
    final sectPr = switch (child.name.local) {
      'sectPr' => child,
      'p' =>
        child
            .getElement('pPr', namespace: wNs)
            ?.getElement('sectPr', namespace: wNs),
      _ => null,
    };
    return sectPr == null ? null : geometryOf(sectPr);
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

String _localOf(String qualified) {
  final colon = qualified.indexOf(':');
  return colon < 0 ? qualified : qualified.substring(colon + 1);
}

/// صفحةٌ اكتملت كتلها، ومقاسها إن عُرف.
final class _PendingPage {
  _PendingPage(this.number, this.blocks, this.firstChild, this.geometry);
  final int number;
  final List<PreviewBlock> blocks;

  /// فهرس الابن الذي بدأت عنده — به يُطابَق أوّلُ `sectPr` يليها.
  final int firstChild;
  PageGeometry? geometry;
}

/// يجمّع صفحات قسمٍ واحد، ويحلّ مقاساتها حين تُعلَن.
///
/// **الحلّ مؤجَّل بالضرورة**: `w:sectPr` يقع في نهاية قسمه لا في بدايته
/// (`02` §7/1)، فالصفحة تُبنى قبل أن يُعرَف مقاسها. تبقى معلَّقةً بفهرس
/// أوّل أبنائها، ويحلّها أوّلُ إعلانٍ يليه. وما بقي معلَّقًا فمقاسه A4 —
/// وهو نفس ما كان يفعله المسح من نهاية المتن إلى بدايته.
///
/// **والإعلان لا يُغلق صفحة.** `sectPr` ينهي قسمًا، والصفحة تنتهي بفاصلها
/// المخزَّن وحده؛ إغلاقها عنده يخترع صفحةً لا وجود لها.
final class _SectionBuilder {
  _SectionBuilder(this.maxPages);

  /// حدّ الصفحات لهذا الجزء، أو `null` بلا حدّ.
  ///
  /// **ليس صمّامًا بل استعجالًا**: أوّل رسمة لا تحتاج آخر المستند، والقارئ
  /// كسول فالوقوف هنا يوقف التحليل. وما بعده يُكمَل في نداءٍ ثانٍ.
  final int? maxPages;

  final List<_PendingPage> _pages = [];
  List<PreviewBlock> _current = [];
  int _firstChild = 0;
  PageGeometry? _openGeometry;
  int _count = 0;

  /// بلغ الصمّام حدَّه: ما بعده يُعلَن مقتطعًا ولا يُخفى (`00` §5).
  bool get full =>
      _count >= _maxBlocksPerSection ||
      (maxPages != null && _pages.length >= maxPages!);

  void add(int childIndex, PreviewBlock block) {
    _count++;
    // فاصل الصفحة يقع **قبل** الكتلة التي تحمله.
    if (block.startsPage && _current.isNotEmpty) _close();
    // مقاس الصفحة مقاس أول كتلة فيها: القسم الأفقيّ يبدأ بفاصل صفحة.
    if (_current.isEmpty) _firstChild = childIndex;
    _current.add(block);
  }

  void _close() {
    if (_current.isEmpty) return;
    _pages.add(
      _PendingPage(_pages.length + 1, _current, _firstChild, _openGeometry),
    );
    _current = [];
    _openGeometry = null;
  }

  /// يُسند [geometry] إلى كل صفحة لم يُعرَف مقاسها وبدأت عند [childIndex]
  /// أو قبله — ومنها الصفحة المفتوحة.
  void resolveUpTo(int childIndex, PageGeometry geometry) {
    for (final page in _pages) {
      if (page.geometry == null && page.firstChild <= childIndex) {
        page.geometry = geometry;
      }
    }
    if (_current.isNotEmpty &&
        _openGeometry == null &&
        _firstChild <= childIndex) {
      _openGeometry = geometry;
    }
  }

  List<PreviewPage> finish() {
    _close();
    return [
      for (final page in _pages)
        PreviewPage(
          number: page.number,
          blocks: page.blocks,
          geometry: page.geometry ?? PageGeometry.a4,
        ),
    ];
  }
}
