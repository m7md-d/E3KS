/// خطوط مقترحة **للمستندات**، لا للتطبيق.
///
/// نطاق مختلف عن `Type` في `tokens.dart`: تلك هوية البرنامج، وهذه اقتراحات
/// لمستند المستخدم. خلطهما يعني أن تغيير هوية التطبيق يغيّر ما نقترحه على
/// المستخدم لملفّه — وهما قراران لا علاقة لأحدهما بالآخر.
///
/// المعيار: خطوط شائعة، وأكثرها يرسم العربية واللاتينية بجودة متقاربة.
library;

/// خطوط عربية مقترحة. المعتمد لدينا أوّلها.
const List<String> arabicFontSuggestions = [
  'IBM Plex Sans Arabic',
  'Noto Sans Arabic',
  'Cairo',
  'Tajawal',
  'Dubai',
  'Geeza Pro',
];

const List<String> latinFontSuggestions = [
  'IBM Plex Sans',
  'Inter',
  'Helvetica Neue',
  'Arial',
  'Calibri',
  'Georgia',
];
