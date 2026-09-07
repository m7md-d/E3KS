/// ما يقبله التطبيق من ملفات: البحث في المجلد، ومرجع الامتدادات الواحد.
///
/// **نُقلا من `batch_test.dart` عند حذف الحوار القديم**: لا شأن لهما به —
/// `findDocuments` باب المجلد في مجموعة العمل، وحارس الامتدادات يمسح `lib`
/// كلّها.
library;

import 'dart:io';

import 'package:e3ks_desktop/data/openable_files.dart';
import 'package:flutter_test/flutter_test.dart';

Directory _tempTree() {
  final root = Directory.systemTemp.createTempSync('e3ks_batch_');
  Directory('${root.path}/عروض').createSync();
  File('${root.path}/أول.docx').writeAsStringSync('x');
  File('${root.path}/عروض/ثانٍ.pptx').writeAsStringSync('x');
  // ما يجب أن يُتخطّى: قفل Word، ومخفيّ، وغير مدعوم.
  File(
    r'${root.path}/~$أول.docx'.replaceAll(r'${root.path}', root.path),
  ).writeAsStringSync('x');
  File('${root.path}/.مخفي.docx').writeAsStringSync('x');
  File('${root.path}/ملاحظات.txt').writeAsStringSync('x');
  return root;
}

void main() {
  test('البحث يجد المدعوم وحده، ويحفظ المسار النسبي', () {
    final root = _tempTree();
    addTearDown(() => root.deleteSync(recursive: true));

    final found = findDocuments(root);
    expect(
      found.map((f) => f.relative),
      equals(['أول.docx', 'عروض/ثانٍ.pptx']),
    );
    expect(found.first.path, startsWith(root.absolute.path));
  });

  test('امتدادات الفتح من مرجعها الواحد', () {
    // **الخلل الذي وُلد منه الاختبار:** `drop_zone.dart` كان يكتب
    // `extensions: ['docx']` بيده، فعجز زرّ الحالة الفارغة عن فتح عرضٍ
    // تقديمي والتطبيق يدعمه. قائمتان تنحرفان، والمرجع الواحد يُحرَس
    // آليًّا (`07` §1).
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('openable_files.dart')) continue;
      final text = entity.readAsStringSync();
      for (final extension in openableExtensions) {
        if (text.contains("'$extension'")) offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
