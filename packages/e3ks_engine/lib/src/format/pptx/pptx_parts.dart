/// أجزاء PowerPoint: أيّها ملك الصيغة، وأيّها يُفحَص، وبأي صنف.
///
/// التقسيم هنا مرآة لتقسيم Word لكن بمنطق العرض التقديمي: **الشريحة محتوى**،
/// و**التخطيط والنموذج الرئيس أنماط موروثة**. أغلب ألوان العرض تسكن في
/// النموذج الرئيس، وعرضها مختلطةً بألوان الشرائح يغرق المستخدم (`02` §6).
library;

import '../../inspect/part_class.dart';

PartClass classifyPptxPart(String name) {
  if (!name.startsWith('ppt/') || !name.endsWith('.xml')) return PartClass.other;
  final leaf = name.substring('ppt/'.length);

  // ما يراه الحاضر على الشاشة.
  if (_numbered(leaf, 'slides/slide')) return PartClass.content;
  if (_numbered(leaf, 'notesSlides/notesSlide')) return PartClass.content;

  // ما تُبنى عليه الشرائح — مصدر أغلب الألوان الموروثة.
  if (_numbered(leaf, 'slideLayouts/slideLayout')) return PartClass.styles;
  if (_numbered(leaf, 'slideMasters/slideMaster')) return PartClass.styles;
  if (_numbered(leaf, 'notesMasters/notesMaster')) return PartClass.styles;
  if (_numbered(leaf, 'handoutMasters/handoutMaster')) return PartClass.styles;
  if (leaf == 'presentation.xml' || leaf == 'tableStyles.xml') {
    return PartClass.styles;
  }

  if (_numbered(leaf, 'theme/theme')) return PartClass.theme;

  return PartClass.other;
}

/// هل الاسم على صيغة `<prefix><رقم>.xml`؟
bool _numbered(String leaf, String prefix) {
  if (!leaf.startsWith(prefix) || !leaf.endsWith('.xml')) return false;
  final digits = leaf.substring(prefix.length, leaf.length - 4);
  return digits.isNotEmpty && int.tryParse(digits) != null;
}

bool isInspectablePptxPart(String name) =>
    classifyPptxPart(name) != PartClass.other;

/// كل ما تحت `ppt/` ملك صيغة PowerPoint — حارس العزل.
///
/// لا تقاطع مع `word/`، واختبارٌ يثبت ذلك بدل أن يفترضه.
bool ownsPptxPart(String name) => name.startsWith('ppt/');

/// شريحة معروضة — لا ملاحظات المحاضر ولا تخطيط.
///
/// المعاينة تعرض ما يراه الحاضر، وملاحظات المحاضر ليست منه.
bool isSlidePart(String name) =>
    name.startsWith('ppt/slides/slide') && name.endsWith('.xml');
