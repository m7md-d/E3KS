/// الخطوط المضمَّنة في عرض PowerPoint.
///
/// `ppt/presentation.xml` يعلنها في `p:embeddedFontLst`، وكلٌّ منها علاقةٌ
/// إلى ملفّ `.fntdata` تحت `ppt/fonts/`. **وبلا تشويش**: البايتات كما هي،
/// والتوقيع يحكم عليها.
library;

import 'package:xml/xml.dart';

import '../../inspect/embedded_font.dart';
import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';
import '../embedded_font_reader.dart';

const String _presentation = 'ppt/presentation.xml';
const String _presentationRels = 'ppt/_rels/presentation.xml.rels';

const Map<String, FontFace> _faces = {
  'regular': FontFace.regular,
  'bold': FontFace.bold,
  'italic': FontFace.italic,
  'boldItalic': FontFace.boldItalic,
};

List<EmbeddedFont> readEmbeddedFonts(DocumentPackage package) {
  final text = package.textOf(_presentation);
  if (text == null) return const [];

  final XmlDocument document;
  try {
    document = XmlDocument.parse(text);
  } on XmlException {
    return const [];
  }

  final targets = relationshipTargets(package, _presentationRels, 'ppt');
  if (targets.isEmpty) return const [];

  final fonts = <EmbeddedFont>[];
  for (final embedded in document.findAllElements(
    'embeddedFont',
    namespace: pNs,
  )) {
    final family = embedded
        .getElement('font', namespace: pNs)
        ?.getAttribute('typeface')
        ?.trim();
    if (family == null || family.isEmpty) continue;

    for (final child in embedded.childElements) {
      final face = _faces[child.name.local];
      if (face == null || child.name.namespaceUri != pNs) continue;

      final target = targets[child.getAttribute('id', namespace: rNs)];
      if (target == null) continue;
      final data = package.bytesOf(target);
      if (data == null) continue;

      final bytes = readableFontBytes(data, null);
      if (bytes == null) continue;

      fonts.add(
        EmbeddedFont(
          family: family,
          face: face,
          bytes: bytes,
          // العرض يعلن التضمين للملفّ كلّه لا لكل خطّ، فلا ادّعاء هنا.
          subsetted: false,
        ),
      );
    }
  }
  return fonts;
}
