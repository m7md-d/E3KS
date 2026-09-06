/// كتابة المخرَج: أين تسكن المؤقّتات، وماذا يحدث حين تُرفض الكتابة.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/data/output_writer.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _bytes = Uint8List.fromList(List.generate(64, (i) => i));

Directory freshDirectory() =>
    Directory.systemTemp.createTempSync('e3ks_write_test');

void main() {
  test('يكتب الملف في الموضع المطلوب', () async {
    final directory = freshDirectory();
    addTearDown(() => directory.deleteSync(recursive: true));

    final target = '${directory.path}/مخرَج.docx';
    await writeOutput(target, _bytes);

    expect(File(target).readAsBytesSync(), equals(_bytes));
  });

  test('لا يُنشئ ملفًّا مجاورًا للهدف', () async {
    // **هذا هو الخلل الذي وُلد منه الاختبار:** المؤقّت كان `الهدف.part`
    // بجوار الهدف، وصندوق macOS الرملي يمنح إذنًا لمسارٍ واحد لا لمجلَّده،
    // فتُرفض الكتابة ولا يظهر ملفّ ولا سبب.
    final directory = freshDirectory();
    addTearDown(() => directory.deleteSync(recursive: true));

    final target = '${directory.path}/مخرَج.docx';
    await writeOutput(target, _bytes);

    final names = directory
        .listSync()
        .map((e) => e.path.split(Platform.pathSeparator).last)
        .toList();
    expect(names, equals(['مخرَج.docx']));
  });

  test('يستبدل ملفًّا قائمًا كاملًا', () async {
    // النقل ذرّي: لا يبقى نصف الملفّ القديم تحت نصف الجديد.
    final directory = freshDirectory();
    addTearDown(() => directory.deleteSync(recursive: true));

    final target = '${directory.path}/مخرَج.docx';
    File(target).writeAsBytesSync(Uint8List.fromList(List.filled(4096, 7)));
    await writeOutput(target, _bytes);

    expect(File(target).readAsBytesSync(), equals(_bytes));
  });

  test('الرفض يُرمى ولا يُبتلَع', () async {
    // الواجهة تلتقطه وتعرضه؛ ابتلاعه هنا يعيد الصمت من بابٍ آخر (`00` §5).
    if (Platform.isWindows) {
      markTestSkipped('صلاحيات المجلَّد تختلف على ويندوز');
      return;
    }
    final directory = freshDirectory();
    addTearDown(() {
      Process.runSync('chmod', ['755', directory.path]);
      directory.deleteSync(recursive: true);
    });

    Process.runSync('chmod', ['555', directory.path]);
    await expectLater(
      writeOutput('${directory.path}/مخرَج.docx', _bytes),
      throwsA(isA<FileSystemException>()),
    );
  });
}
