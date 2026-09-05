/// استخراج معاينة الشرائح.
///
/// **أصدق من معاينة Word، ولسبب بنيوي:** الشريحة لوحةٌ لا تدفّق — كل شكل
/// يعلن موضعه ومقاسه بالـEMU. فلا نحسب تخطيطًا ولا نخمّنه: نقرأه.
///
/// **الفخّ:** الشكل النائب (placeholder) كثيرًا ما يترك `a:xfrm` ليرث موضعه
/// من التخطيط. تجاهله يعني عنوانًا بلا موضع في أغلب الشرائح، فنتبع علاقة
/// الشريحة إلى تخطيطها ونقرأ منه.
library;

import 'package:xml/xml.dart';

import '../../inspect/hex_color.dart';
import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';
import '../../preview/preview_model.dart';
import 'pptx_parts.dart';

/// وحدة PowerPoint: ‏914400 EMU للبوصة، و‎12700‎ للنقطة الطباعية.
const double _emuPerPoint = 12700;

/// مقاس ‎4:3‎ الافتراضي بالنقاط — ما يفترضه PowerPoint حين لا يصرّح العرض.
const PageGeometry _defaultSlide = PageGeometry(
  widthPt: 720,
  heightPt: 540,
  marginTopPt: 0,
  marginRightPt: 0,
  marginBottomPt: 0,
  marginLeftPt: 0,
);

/// حجم الخطّ الافتراضي في PowerPoint حين لا يصرّح المقطع ولا نمطه.
const double _defaultSizePt = 18;

final class PptxPreviewExtractor {
  const PptxPreviewExtractor();

  DocumentPreview extract(DocumentPackage package) {
    final geometry = _slideSize(package);
    final slides = <String>[
      for (final name in package.partNames)
        if (isSlidePart(name)) name,
    ]..sort(_bySlideNumber);

    final pages = <PreviewPage>[];
    for (final name in slides) {
      final document = _parse(package, name);
      if (document == null) continue;
      pages.add(
        PreviewPage(
          number: pages.length + 1,
          geometry: geometry,
          blocks: _shapesOf(document.rootElement, _layoutOf(package, name)),
        ),
      );
    }

    if (pages.isEmpty) return const DocumentPreview(sections: []);
    return DocumentPreview(
      sections: [
        PreviewSection(
          partName: 'ppt/slides',
          kind: PreviewSectionKind.slides,
          pages: pages,
          truncated: false,
        ),
      ],
    );
  }

  XmlDocument? _parse(DocumentPackage package, String partName) {
    final text = package.textOf(partName);
    if (text == null) return null;
    try {
      return XmlDocument.parse(text);
    } on XmlException {
      return null; // الفحص يبلّغ عن الجزء التالف؛ المعاينة تتخطّاه بهدوء.
    }
  }

  /// ‏`p:sldSz` من `presentation.xml` — مقاس كل شريحة في العرض.
  PageGeometry _slideSize(DocumentPackage package) {
    final document = _parse(package, 'ppt/presentation.xml');
    final size = document?.rootElement.getElement('sldSz', namespace: pNs);
    final cx = double.tryParse(size?.getAttribute('cx') ?? '');
    final cy = double.tryParse(size?.getAttribute('cy') ?? '');
    if (cx == null || cy == null || cx <= 0 || cy <= 0) return _defaultSlide;
    return PageGeometry(
      widthPt: cx / _emuPerPoint,
      heightPt: cy / _emuPerPoint,
      marginTopPt: 0,
      marginRightPt: 0,
      marginBottomPt: 0,
      marginLeftPt: 0,
    );
  }

  /// تخطيط الشريحة، لقراءة مواضع الأشكال النائبة منه.
  XmlElement? _layoutOf(DocumentPackage package, String slidePart) {
    final slash = slidePart.lastIndexOf('/');
    final rels =
        '${slidePart.substring(0, slash)}/_rels'
        '${slidePart.substring(slash)}.rels';
    final document = _parse(package, rels);
    if (document == null) return null;

    for (final relationship in document.rootElement.childElements) {
      final target = relationship.getAttribute('Target');
      if (target == null || !target.contains('slideLayout')) continue;
      // الهدف نسبيّ (`../slideLayouts/slideLayout3.xml`).
      final leaf = target.substring(target.lastIndexOf('/') + 1);
      return _parse(package, 'ppt/slideLayouts/$leaf')?.rootElement;
    }
    return null;
  }

  /// أشكال الشريحة، كلٌّ بإطاره وفقراته.
  List<PreviewBlock> _shapesOf(XmlElement slide, XmlElement? layout) {
    final blocks = <PreviewBlock>[];
    for (final shape in slide.descendants.whereType<XmlElement>()) {
      if (shape.name.namespaceUri != pNs || shape.name.local != 'sp') continue;

      final body = shape.getElement('txBody', namespace: pNs);
      if (body == null) continue;

      final paragraphs = [
        for (final p in body.findElements('p', namespace: aNs)) _paragraph(p),
      ];
      if (paragraphs.every((p) => p.isEmpty)) continue;

      blocks.add(
        ShapeBlock(
          paragraphs: paragraphs,
          frame: _frameOf(shape, layout),
          fill: _fillOf(shape.getElement('spPr', namespace: pNs)),
        ),
      );
    }
    return blocks;
  }

  /// إطار الشكل: من `a:xfrm` الخاصّ به، وإلّا من نائبه في التخطيط.
  BlockFrame? _frameOf(XmlElement shape, XmlElement? layout) {
    final own = _xfrmOf(shape);
    if (own != null) return own;

    final placeholder = shape
        .getElement('nvSpPr', namespace: pNs)
        ?.getElement('nvPr', namespace: pNs)
        ?.getElement('ph', namespace: pNs);
    if (placeholder == null || layout == null) return null;

    final index = placeholder.getAttribute('idx');
    final type = placeholder.getAttribute('type');

    for (final candidate in layout.descendants.whereType<XmlElement>()) {
      if (candidate.name.namespaceUri != pNs || candidate.name.local != 'sp') {
        continue;
      }
      final other = candidate
          .getElement('nvSpPr', namespace: pNs)
          ?.getElement('nvPr', namespace: pNs)
          ?.getElement('ph', namespace: pNs);
      if (other == null) continue;
      // المطابقة بالفهرس أولًا، فهو الأدقّ؛ ثم بالنوع (`title`, `body`…).
      final matches = index != null
          ? other.getAttribute('idx') == index
          : (type != null && other.getAttribute('type') == type);
      if (matches) return _xfrmOf(candidate);
    }
    return null;
  }

  BlockFrame? _xfrmOf(XmlElement shape) {
    final xfrm = shape
        .getElement('spPr', namespace: pNs)
        ?.getElement('xfrm', namespace: aNs);
    final offset = xfrm?.getElement('off', namespace: aNs);
    final extent = xfrm?.getElement('ext', namespace: aNs);
    final x = double.tryParse(offset?.getAttribute('x') ?? '');
    final y = double.tryParse(offset?.getAttribute('y') ?? '');
    final cx = double.tryParse(extent?.getAttribute('cx') ?? '');
    final cy = double.tryParse(extent?.getAttribute('cy') ?? '');
    if (x == null || y == null || cx == null || cy == null) return null;
    return BlockFrame(
      leftPt: x / _emuPerPoint,
      topPt: y / _emuPerPoint,
      widthPt: cx / _emuPerPoint,
      heightPt: cy / _emuPerPoint,
    );
  }

  HexColor? _fillOf(XmlElement? properties) => HexColor.tryParse(
    properties
        ?.getElement('solidFill', namespace: aNs)
        ?.getElement('srgbClr', namespace: aNs)
        ?.getAttribute('val'),
  );

  PreviewParagraph _paragraph(XmlElement paragraph) {
    final properties = paragraph.getElement('pPr', namespace: aNs);
    final defaults = properties?.getElement('defRPr', namespace: aNs);
    final level = int.tryParse(properties?.getAttribute('lvl') ?? '') ?? 0;

    return PreviewParagraph(
      runs: [
        for (final run in paragraph.findElements('r', namespace: aNs))
          _run(run, defaults),
      ],
      align: _alignOf(properties?.getAttribute('algn')),
      isRtl: properties?.getAttribute('rtl') == '1',
      // مستوى التعداد في PowerPoint هو ما يميّز العنوان عن النقطة الفرعية.
      outlineLevel: level == 0 ? null : level,
    );
  }

  PreviewRun _run(XmlElement run, XmlElement? defaults) {
    final properties = run.getElement('rPr', namespace: aNs) ?? defaults;
    final size = double.tryParse(properties?.getAttribute('sz') ?? '');

    String? typeface(String slot) {
      final value = properties
          ?.getElement(slot, namespace: aNs)
          ?.getAttribute('typeface');
      return value == null || value.isEmpty || value.startsWith('+')
          ? null
          : value;
    }

    return PreviewRun(
      text: run.getElement('t', namespace: aNs)?.innerText ?? '',
      color: _fillOf(properties),
      latinFont: typeface('latin'),
      arabicFont: typeface('cs'),
      // ‏`sz` بمئات النقاط: ‏1800 = 18pt.
      sizePt: size == null ? _defaultSizePt : size / 100,
      bold: properties?.getAttribute('b') == '1',
      italic: properties?.getAttribute('i') == '1',
      underline: (properties?.getAttribute('u') ?? 'none') != 'none',
    );
  }

  PreviewAlign _alignOf(String? value) => switch (value) {
    'ctr' => PreviewAlign.center,
    'r' => PreviewAlign.end,
    'just' || 'dist' => PreviewAlign.justify,
    _ => PreviewAlign.start,
  };
}

/// ‏`slide10.xml` بعد `slide9.xml` لا قبله — الترتيب النصّي يخون هنا.
int _bySlideNumber(String a, String b) => _number(a).compareTo(_number(b));

int _number(String partName) {
  final digits = RegExp(r'(\d+)\.xml$').firstMatch(partName)?.group(1);
  return int.tryParse(digits ?? '') ?? 0;
}
