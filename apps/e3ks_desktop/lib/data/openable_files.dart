/// ما يقبله التطبيق من ملفات، واسم المخرج المقترح.
///
/// **الامتداد للحوار لا للقرار.** الصيغة الفعلية يقرّرها المحرّك من محتوى
/// الحاوية (`formatFor`)، فملفّ أُعيدت تسميته يُعالَج بما هو لا بما سُمّي.
/// هذه القائمة تُرشِد حوار الفتح وحده.
library;

import 'dart:io';

/// امتدادات نعرضها في حوار الفتح ونقبلها بالإفلات.
const List<String> openableExtensions = ['docx', 'pptx', 'ppsx', 'potx'];

/// ملفٌّ وُجد في مجلد: مساره الكامل، ومساره النسبي تحت جذره.
typedef FoundDocument = ({String path, String relative});

/// يجمع مستندات المجلد وما تحته، مرتّبةً.
///
/// **والقائمة واحدة**: كانت هنا مجموعةٌ ثانية بالنقاط (`.docx`) بجوار
/// [openableExtensions]، وقائمتان تنحرفان عند أوّل صيغةٍ تُضاف.
List<FoundDocument> findDocuments(Directory root) {
  final base = root.absolute.path;
  final found = <FoundDocument>[];

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    // `~$` ملفات قفل يكتبها Word، والمخفيّة ليست مستندات المستخدم.
    if (name.startsWith(r'~$') || name.startsWith('.')) continue;
    final dot = name.lastIndexOf('.');
    if (dot < 0) continue;
    final extension = name.substring(dot + 1).toLowerCase();
    if (!openableExtensions.contains(extension)) continue;

    found.add((
      path: entity.absolute.path,
      relative: entity.absolute.path.substring(base.length + 1),
    ));
  }

  found.sort((a, b) => a.relative.compareTo(b.relative));
  return found;
}

/// اسم المخرج المقترح: نفس الاسم بلاحقة، **وبنفس الامتداد**.
///
/// تثبيت الامتداد على `.docx` كان يُخرج عرضًا تقديميًّا باسم مستند، فيرفضه
/// النظام عند الفتح ويظنّه المستخدم ملفًّا مكسورًا.
String suggestedOutputName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0) return '${fileName}_E3KS';
  return '${fileName.substring(0, dot)}_E3KS${fileName.substring(dot)}';
}
