/// بناء مستندات docx صغيرة مصنوعة يدويًا للاختبار.
///
/// القاعدة `04` §4: ملفات المرجع تُصنَع هنا، ولا تُستورد من مستندات عملاء.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

const _contentTypes = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
</Types>''';

const _rootRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

const _documentRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
</Relationships>''';

/// فقرة عربية وإنجليزية معًا، بخط `cs` مختلف عن `ascii` — `02` §7.
const _document = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
<w:p><w:pPr><w:shd w:val="clear" w:fill="EEF3F2"/></w:pPr>
<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Traditional Arabic"/><w:color w:val="4C2FB8" w:themeColor="accent1"/></w:rPr><w:t xml:space="preserve">مرحبا </w:t></w:r>
<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Traditional Arabic"/><w:color w:val="667085"/></w:rPr><w:t>world</w:t></w:r>
</w:p>
<w:p><w:r><w:rPr><w:color w:val="auto"/></w:rPr><w:t>auto colour</w:t></w:r></w:p>
<w:p><w:r><w:rPr><w:rFonts w:ascii="DejaVu Sans Mono" w:hAnsi="DejaVu Sans Mono" w:cs="DejaVu Sans Mono"/></w:rPr><w:t>const x = 1;</w:t></w:r></w:p>
<w:sectPr><w:headerReference w:type="default" r:id="rId1" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/><w:footerReference w:type="default" r:id="rId2" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/></w:sectPr>
</w:body>
</w:document>''';

const _header = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:p><w:r><w:rPr><w:color w:val="4C2FB8"/></w:rPr><w:t>Header line</w:t></w:r></w:p>
</w:hdr>''';

/// تذييل يحوي حقل PAGE كاملًا بناتجه المخزَّن — `02` §4.
const _footer = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:p>
<w:r><w:t xml:space="preserve">Page </w:t></w:r>
<w:r><w:fldChar w:fldCharType="begin"/></w:r>
<w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>
<w:r><w:fldChar w:fldCharType="separate"/></w:r>
<w:r><w:t>1</w:t></w:r>
<w:r><w:fldChar w:fldCharType="end"/></w:r>
</w:p>
</w:ftr>''';

/// الترتيب مقصود: `[Content_Types].xml` أولًا — `02` §1.
/// نمط جدول افتراضي بلون لا يظهر في المتن — يمثّل ضجيج ثيم Office (`02` §6).
const _styles = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:style w:type="table" w:styleId="LightGrid-Accent1">
<w:tblPr><w:tblBorders><w:top w:val="single" w:color="4F81BD"/><w:bottom w:val="single" w:color="4F81BD"/></w:tblBorders></w:tblPr>
</w:style>
</w:styles>''';

const Map<String, String> fixtureParts = {
  '[Content_Types].xml': _contentTypes,
  '_rels/.rels': _rootRels,
  'word/_rels/document.xml.rels': _documentRels,
  'word/document.xml': _document,
  'word/styles.xml': _styles,
  'word/header1.xml': _header,
  'word/footer1.xml': _footer,
};

/// مستند docx صغير صالح، فيه ترويسة وتذييل وحقل ورموز عربية وخط أحادي العرض.
Uint8List buildFixtureDocx() {
  final archive = Archive();
  for (final entry in fixtureParts.entries) {
    archive.add(ArchiveFile.bytes(entry.key, utf8.encode(entry.value.trim())));
  }
  return ZipEncoder().encodeBytes(archive);
}

/// مستند بقسمين مختلفَي المقاس: Letter رأسي ثم A4 أفقي.
///
/// القسم الأفقي شائع في المستندات الحقيقية (جدول عريض)، وعرضه بمقاس الصفحات
/// الرأسية يكذب على المستخدم. مفصول عن `buildFixtureDocx` كي لا يتغيّر مستند
/// مرجعيّ تعتمد عليه اختبارات الأمانة والفحص.
const String _sectionedDocument = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
<w:p><w:r><w:t>portrait</w:t></w:r></w:p>
<w:p><w:pPr><w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1080" w:bottom="1440" w:left="1800"/></w:sectPr></w:pPr>
<w:r><w:t>end of first section</w:t></w:r></w:p>
<w:p><w:r><w:br w:type="page"/><w:t>landscape</w:t></w:r></w:p>
<w:sectPr><w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/></w:sectPr>
</w:body>
</w:document>''';

/// مستند بقسمين، بلا ترويسة ولا تذييل — الغرض المقاس وحده.
Uint8List buildSectionedDocx() {
  final archive = Archive();
  final parts = {...fixtureParts, 'word/document.xml': _sectionedDocument}
    ..remove('word/header1.xml');
  for (final entry in parts.entries) {
    archive.add(ArchiveFile.bytes(entry.key, utf8.encode(entry.value.trim())));
  }
  return ZipEncoder().encodeBytes(archive);
}
