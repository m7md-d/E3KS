/// ما يقبله التطبيق من ملفات، واسم المخرج المقترح.
///
/// **الامتداد للحوار لا للقرار.** الصيغة الفعلية يقرّرها المحرّك من محتوى
/// الحاوية (`formatFor`)، فملفّ أُعيدت تسميته يُعالَج بما هو لا بما سُمّي.
/// هذه القائمة تُرشِد حوار الفتح وحده.
library;

/// امتدادات نعرضها في حوار الفتح ونقبلها بالإفلات.
const List<String> openableExtensions = ['docx', 'pptx', 'ppsx', 'potx'];

/// اسم المخرج المقترح: نفس الاسم بلاحقة، **وبنفس الامتداد**.
///
/// تثبيت الامتداد على `.docx` كان يُخرج عرضًا تقديميًّا باسم مستند، فيرفضه
/// النظام عند الفتح ويظنّه المستخدم ملفًّا مكسورًا.
String suggestedOutputName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0) return '${fileName}_E3KS';
  return '${fileName.substring(0, dot)}_E3KS${fileName.substring(dot)}';
}
