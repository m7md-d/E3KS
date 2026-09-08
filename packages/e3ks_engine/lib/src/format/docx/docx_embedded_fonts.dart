/// الخطوط المضمَّنة في مستند Word.
///
/// `word/fontTable.xml` يعلن لكل عائلة أوجهها المضمَّنة، وكلٌّ منها علاقةٌ
/// إلى ملفٍّ في `word/fonts/` مشوَّش بمفتاح `w:fontKey`.
library;

import 'package:xml/xml.dart';

import '../../inspect/embedded_font.dart';
import '../../ooxml/ooxml_names.dart';
import '../../package/document_package.dart';
import '../embedded_font_reader.dart';

const String _fontTable = 'word/fontTable.xml';
const String _fontTableRels = 'word/_rels/fontTable.xml.rels';

const Map<String, FontFace> _faces = {
  'embedRegular': FontFace.regular,
  'embedBold': FontFace.bold,
  'embedItalic': FontFace.italic,
  'embedBoldItalic': FontFace.boldItalic,
};

/// كل خطٍّ ضمّنه المستند، بعد فكّ تشويشه والتحقّق من توقيعه.
///
/// **ما لا يُفكّ يُترك.** خطٌّ خرج بلا توقيع صالح لا يُسجَّل: تسجيله يرسم
/// المستند بمربّعات، والسقوط إلى المسار المعتاد يرسمه بأقرب ما نملك.
List<EmbeddedFont> readEmbeddedFonts(DocumentPackage package) {
  final text = package.textOf(_fontTable);
  if (text == null) return const [];

  final XmlDocument table;
  try {
    table = XmlDocument.parse(text);
  } on XmlException {
    return const [];
  }

  final targets = relationshipTargets(package, _fontTableRels, 'word');
  if (targets.isEmpty) return const [];

  final fonts = <EmbeddedFont>[];
  for (final font in table.findAllElements('font', namespace: wNs)) {
    final family = font.getAttribute('name', namespace: wNs)?.trim();
    if (family == null || family.isEmpty) continue;

    for (final child in font.childElements) {
      final face = _faces[child.name.local];
      if (face == null || child.name.namespaceUri != wNs) continue;

      final target = targets[child.getAttribute('id', namespace: rNs)];
      if (target == null) continue;
      final data = package.bytesOf(target);
      if (data == null) continue;

      final bytes = readableFontBytes(
        data,
        child.getAttribute('fontKey', namespace: wNs),
      );
      if (bytes == null) continue;

      fonts.add(
        EmbeddedFont(
          family: family,
          face: face,
          bytes: bytes,
          subsetted: child.getAttribute('subsetted', namespace: wNs) == 'true',
        ),
      );
    }
  }
  return fonts;
}
