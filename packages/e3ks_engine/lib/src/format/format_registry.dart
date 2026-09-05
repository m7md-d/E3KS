/// سجلّ الصيغ المدعومة والتعرّف عليها.
///
/// **إضافة صيغة = سطر واحد هنا** بعد كتابة ملفّها. لا شيء آخر في المحرّك
/// يعرف أسماء الصيغ، فلا مكان ثانٍ يُنسى تحديثه.
library;

import '../diagnostics/engine_issue.dart';
import '../diagnostics/engine_result.dart';
import '../package/document_package.dart';
import 'docx/docx_format.dart';
import 'document_format.dart';
import 'pptx/pptx_format.dart';

const List<DocumentFormat> supportedFormats = [DocxFormat(), PptxFormat()];

/// الصيغة التي تدّعي هذه الحاوية، أو إخفاق إن لم تدّعِها صيغة.
///
/// **لا نخمّن بالامتداد.** ملفّ `.pptx` أعاد أحدهم تسميته من `.docx` يجب أن
/// يُعالَج بما هو، لا بما سُمّي — وإلّا كتبنا في أجزاء لا وجود لها وأخرجنا
/// ملفًّا مكسورًا (`00` §١).
EngineResult<DocumentFormat> formatFor(DocumentPackage package) {
  for (final format in supportedFormats) {
    if (format.claims(package)) return Ok(format);
  }
  return const Failed([
    EngineIssue(
      code: IssueCode.unsupportedFormat,
      detail: 'no registered format claims this package',
    ),
  ]);
}
