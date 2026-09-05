/// عرض PowerPoint صغير مصنوع يدويًا للاختبار.
///
/// القاعدة `04` §4: ملفات المرجع تُصنَع هنا، ولا تُستورد من ملفات عملاء.
///
/// مصمَّم ليحمل كل فخّ نعرفه: شكل نائب بلا `a:xfrm` يرث موضعه من التخطيط،
/// وخطّ عربي في `a:cs` وحده، وإحالة ثيم `+mj-lt` لا تُبدَّل، ولون لا يظهر
/// إلا في النموذج الرئيس (ضجيج موروث)، ولوحة ثيم كاملة.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

const _contentTypes = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
<Override PartName="/ppt/slides/slide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
</Types>''';

const _rootRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';

/// 16:9 = 12192000×6858000 EMU = 960×540 نقطة.
const _presentation = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>
<p:sldIdLst><p:sldId id="256" r:id="rId2"/></p:sldIdLst>
<p:sldSz cx="12192000" cy="6858000"/>
<p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>''';

const _presentationRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide1.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
</Relationships>''';

/// العنوان **بلا** `a:xfrm` — يرث موضعه من التخطيط بالفهرس `idx="0"`.
/// والمتن بإطاره الصريح وتعبئة، وفيه خطّ عربي في `a:cs` وحده وإحالة ثيم.
const _slide = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:cSld><p:spTree>
<p:sp>
<p:nvSpPr><p:cNvPr id="2" name="Title"/><p:cNvSpPr/><p:nvPr><p:ph type="title" idx="0"/></p:nvPr></p:nvSpPr>
<p:spPr/>
<p:txBody><a:bodyPr/><a:lstStyle/>
<a:p><a:pPr algn="ctr"/><a:r><a:rPr lang="ar-SA" sz="4400" b="1"><a:solidFill><a:srgbClr val="1B7F79"/></a:solidFill><a:latin typeface="Cairo"/><a:cs typeface="Traditional Arabic"/></a:rPr><a:t>هوية العرض</a:t></a:r></a:p>
</p:txBody>
</p:sp>
<p:sp>
<p:nvSpPr><p:cNvPr id="3" name="Body"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
<p:spPr><a:xfrm><a:off x="838200" y="2286000"/><a:ext cx="10515600" cy="2160000"/></a:xfrm><a:solidFill><a:srgbClr val="EEF3F2"/></a:solidFill><a:ln><a:solidFill><a:srgbClr val="1B7F79"/></a:solidFill></a:ln></p:spPr>
<p:txBody><a:bodyPr/><a:lstStyle/>
<a:p><a:r><a:rPr lang="en-US" sz="2000"><a:solidFill><a:srgbClr val="667085"/></a:solidFill><a:latin typeface="+mj-lt"/></a:rPr><a:t>theme reference stays</a:t></a:r></a:p>
<a:p><a:pPr lvl="1"/><a:r><a:rPr lang="en-US" sz="1600"><a:solidFill><a:schemeClr val="accent1"/></a:solidFill><a:latin typeface="DejaVu Sans Mono"/></a:rPr><a:t>const x = 1;</a:t></a:r></a:p>
</p:txBody>
</p:sp>
</p:spTree></p:cSld>
</p:sld>''';

const _slideRels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';

/// موضع العنوان يسكن هنا: 838200×685800 EMU = 66×54 نقطة.
const _slideLayout = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:cSld><p:spTree>
<p:sp>
<p:nvSpPr><p:cNvPr id="2" name="Title Placeholder"/><p:cNvSpPr/><p:nvPr><p:ph type="title" idx="0"/></p:nvPr></p:nvSpPr>
<p:spPr><a:xfrm><a:off x="838200" y="685800"/><a:ext cx="10515600" cy="1143000"/></a:xfrm></p:spPr>
<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr lang="en-US"/></a:p></p:txBody>
</p:sp>
</p:spTree></p:cSld>
</p:sldLayout>''';

/// لون لا يظهر إلا هنا — ضجيج موروث لا هوية (`02` §6).
const _slideMaster = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:cSld><p:bg><p:bgPr><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill></p:bgPr></p:bg>
<p:spTree>
<p:sp><p:nvSpPr><p:cNvPr id="2" name="Master Title"/><p:cNvSpPr/><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>
<p:spPr/>
<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:r><a:rPr lang="en-US"><a:solidFill><a:srgbClr val="4F81BD"/></a:solidFill></a:rPr><a:t>Master</a:t></a:r></a:p></p:txBody>
</p:sp>
</p:spTree></p:cSld>
</p:sldMaster>''';

const _theme = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="E3KS">
<a:themeElements>
<a:clrScheme name="E3KS"><a:dk1><a:srgbClr val="000000"/></a:dk1><a:lt1><a:srgbClr val="FFFFFF"/></a:lt1><a:accent1><a:srgbClr val="9BBB59"/></a:accent1></a:clrScheme>
<a:fontScheme name="E3KS"><a:majorFont><a:latin typeface="IBM Plex Sans"/><a:cs typeface="IBM Plex Sans Arabic"/></a:majorFont><a:minorFont><a:latin typeface="IBM Plex Sans"/><a:cs typeface="IBM Plex Sans Arabic"/></a:minorFont></a:fontScheme>
</a:themeElements>
</a:theme>''';

/// الترتيب مقصود: `[Content_Types].xml` أولًا — `02` §1.
const Map<String, String> pptxFixtureParts = {
  '[Content_Types].xml': _contentTypes,
  '_rels/.rels': _rootRels,
  'ppt/presentation.xml': _presentation,
  'ppt/_rels/presentation.xml.rels': _presentationRels,
  'ppt/slides/slide1.xml': _slide,
  'ppt/slides/_rels/slide1.xml.rels': _slideRels,
  'ppt/slideLayouts/slideLayout1.xml': _slideLayout,
  'ppt/slideMasters/slideMaster1.xml': _slideMaster,
  'ppt/theme/theme1.xml': _theme,
};

Uint8List buildFixturePptx() {
  final archive = Archive();
  for (final entry in pptxFixtureParts.entries) {
    archive.add(ArchiveFile.bytes(entry.key, utf8.encode(entry.value.trim())));
  }
  return ZipEncoder().encodeBytes(archive);
}
