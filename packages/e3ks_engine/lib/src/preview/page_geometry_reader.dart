/// قراءة مقاس الصفحة وهوامشها من `w:sectPr`.
///
/// مفصولة عن استخراج المحتوى: هذه تقرأ الورقة، وتلك تقرأ ما عليها.
library;

import 'package:xml/xml.dart';

import '../ooxml/ooxml_names.dart';
import 'preview_model.dart';

/// مقاس الصفحة لكل عنصر من عناصر المتن.
///
/// `w:sectPr` يقع في **نهاية** قسمه لا في بدايته: إمّا داخل `pPr` آخر فقرة
/// في القسم، وإمّا آخر أبناء `w:body` للقسم الأخير. لذلك نمسح من النهاية إلى
/// البداية ونُسند إلى كل عنصر أوّلَ `sectPr` يليه.
List<PageGeometry> geometriesForBody(List<XmlElement> children) {
  final marks = List<PageGeometry?>.filled(children.length, null);
  for (var i = 0; i < children.length; i++) {
    final child = children[i];
    final sectPr = switch (child.name.local) {
      'sectPr' => child,
      'p' =>
        child
            .getElement('pPr', namespace: wNs)
            ?.getElement('sectPr', namespace: wNs),
      _ => null,
    };
    if (sectPr != null) marks[i] = geometryOf(sectPr);
  }

  final result = List<PageGeometry>.filled(children.length, PageGeometry.a4);
  var pending = PageGeometry.a4;
  for (var i = children.length - 1; i >= 0; i--) {
    pending = marks[i] ?? pending;
    result[i] = pending;
  }
  return result;
}

/// يقرأ `w:pgSz` و`w:pgMar` بالـ twip ويحوّلها إلى نقاط.
///
/// القيم الشاذّة تُقيَّد لا تُصدَّق: Word يقبل هامشًا سالبًا (لوضع الترويسة)
/// وصفحةً بمقاس صفر بعد تحرير خاطئ، وكلاهما يُخرج ورقةً مشوَّهة في المعاينة.
PageGeometry geometryOf(XmlElement sectPr) {
  final size = sectPr.getElement('pgSz', namespace: wNs);
  final margin = sectPr.getElement('pgMar', namespace: wNs);

  double points(XmlElement? element, String attribute, double fallback) {
    final raw = element?.getAttribute(attribute, namespace: wNs);
    final value = double.tryParse(raw ?? '');
    return value == null ? fallback : value / 20;
  }

  // ‏72pt أصغر صفحة معقولة، و‎1584pt‎ (‏22 بوصة) أكبر ما يسمح به Word.
  final width = points(size, 'w', PageGeometry.a4.widthPt).clamp(72.0, 1584.0);
  final height = points(
    size,
    'h',
    PageGeometry.a4.heightPt,
  ).clamp(72.0, 1584.0);

  double inset(String attribute, double fallback, double extent) =>
      points(margin, attribute, fallback).clamp(0.0, extent * 0.45);

  return PageGeometry(
    widthPt: width,
    heightPt: height,
    marginTopPt: inset('top', PageGeometry.a4.marginTopPt, height),
    marginRightPt: inset('right', PageGeometry.a4.marginRightPt, width),
    marginBottomPt: inset('bottom', PageGeometry.a4.marginBottomPt, height),
    marginLeftPt: inset('left', PageGeometry.a4.marginLeftPt, width),
  );
}
