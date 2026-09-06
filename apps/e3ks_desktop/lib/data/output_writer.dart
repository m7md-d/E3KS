/// كتابة المخرَج حيث اختار المستخدم، ذرّيًّا وبلا صمت.
///
/// **الخلل الذي وُلد منه هذا الملف:** كانت الكتابة تُنشئ `مخرَج.docx.part`
/// **بجوار** الهدف ثم تعيد تسميته. وتطبيق macOS في صندوق رملي، وحوار الحفظ
/// يمنحه إذنًا **لمسارٍ واحد بعينه لا لمجلَّده**. فالملفّ المجاور خارج
/// الإذن، والكتابة تُرفض، والاستثناء يقع خارج أي مُلتقِط — فيبقى الزرّ
/// يدور ولا يظهر ملفّ ولا سبب.
///
/// **والذرّية تبقى** (`00` §١/٣): المؤقّت يسكن مجلَّدنا المؤقّت — وهو داخل
/// الصندوق — ثم يُنقَل إلى الهدف بنقلةٍ واحدة. وحين يتعذّر النقل (قرصٌ آخر
/// مثلًا) نكتب مباشرةً ونقول ذلك في الشيفرة لا في الصمت.
library;

import 'dart:io';
import 'dart:typed_data';

/// يكتب [bytes] في [path]. يرمي [FileSystemException] إن تعذّر.
Future<void> writeOutput(String path, Uint8List bytes) async {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final temp = File('${Directory.systemTemp.path}/e3ks-$stamp.part');

  await temp.writeAsBytes(bytes, flush: true);
  try {
    // النقل ذرّي على القرص الواحد: لا يرى أحدٌ ملفًّا نصفه قديم ونصفه جديد.
    await temp.rename(path);
  } on FileSystemException {
    // قرصٌ آخر أو نظام ملفات لا يسمح بالنقل: لا مفرّ من كتابة مباشرة.
    try {
      await File(path).writeAsBytes(bytes, flush: true);
    } finally {
      if (temp.existsSync()) await temp.delete();
    }
  }
}
