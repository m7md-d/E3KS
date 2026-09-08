/// مستندات Word حقيقية نختبر عليها — من مجلد خارج المستودع.
///
/// القاعدة `04` §1: المصنوع يكشف ما صنعناه له، والحقيقي يكشف ما لم نتوقّعه —
/// ضغط مختلط، وأجزاء ثنائية، وغلافًا كتبه غيرنا. والقاعدة `04` §4: ملفات
/// العملاء لا تدخل المستودع، فالمجلد بجواره لا فيه.
///
/// غيابه لا يُسقط اختبارًا بل يتخطّاه: المستودع يُستنسَخ عند غير مالكه.
library;

import 'dart:io';

/// مجلد المستندات، بمسار نسبي من جذر حزمة المحرّك.
const realDocsDir = '../../../Docx';

/// مستندات `.docx` في المجلد وما تحته، مرتَّبةً ليثبت ترتيب التشغيل.
List<File> realDocuments() {
  final dir = Directory(realDocsDir);
  if (!dir.existsSync()) return const [];

  final found = [
    for (final entry in dir.listSync(recursive: true).whereType<File>())
      if (entry.path.toLowerCase().endsWith('.docx') &&
          // ‏Word يترك ملفّ قفلٍ بهذا البادئ بجوار المفتوح؛ ليس مستندًا.
          !entry.uri.pathSegments.last.startsWith('~\$'))
        entry,
  ];
  return found..sort((a, b) => a.path.compareTo(b.path));
}
