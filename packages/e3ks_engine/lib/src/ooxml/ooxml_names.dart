/// مساحات أسماء OOXML والأسماء المؤهَّلة التي نتعامل معها.
///
/// مركزتها هنا تمنع تكرار السلاسل الطويلة وأخطاءها الصامتة.
library;

/// WordprocessingML — المتن والأنماط.
const String wNs =
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

/// DrawingML — الرسوميات والثيم.
const String aNs = 'http://schemas.openxmlformats.org/drawingml/2006/main';

/// العلاقات.
const String rNs =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

/// عناصر الحدود داخل `w:pBdr` و`w:tcBorders` وأخواتها — `02` §5.
const Set<String> borderElements = {
  'top',
  'bottom',
  'left',
  'right',
  'start',
  'end',
  'insideH',
  'insideV',
  'tl2br',
  'tr2bl',
  'bar',
  'between',
};

/// سمات الخطوط في `w:rFonts` — العربية تُقرأ من `cs`، وإغفالها خطأ شائع (`02` §7).
const List<String> fontAttributes = ['ascii', 'hAnsi', 'cs', 'eastAsia'];

/// سمات الثيم في `w:rFonts` — تُحذف عند التبديل الصريح (`02` §7).
const List<String> fontThemeAttributes = [
  'asciiTheme',
  'hAnsiTheme',
  'cstheme',
  'eastAsiaTheme',
];

/// سمات ألوان الثيم — تُحذف عند تبديل اللون الصريح (`02` §6).
const List<String> colorThemeAttributes = [
  'themeColor',
  'themeFill',
  'themeTint',
  'themeShade',
  'themeFillTint',
  'themeFillShade',
];
