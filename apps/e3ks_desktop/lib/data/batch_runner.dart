/// تشغيل الدفعة: مجلد كامل بخطة واحدة.
///
/// القاعدة `03`: كل عملية على ملف تجري في isolate — الواجهة لا تتجمّد.
/// وملفٌ واحد في دليل التخرّج بلغ ٢٦ ألف تبديل خطّ؛ أربعون مثله على خيط
/// الواجهة تعني نافذة ميّتة دقيقة كاملة.
///
/// والقراءة والتبديل والكتابة تجري كلها **داخل** الـisolate: إعادة بايتات
/// المخرَج إلى خيط الواجهة لتكتبها نسخةٌ بلا سبب.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';

/// امتدادات البحث في المجلد.
///
/// **للعثور على الملفات وحدها.** الصيغة الفعلية يقرّرها المحرّك من محتوى
/// الملف، فملفٌ أُعيدت تسميته يُعالَج بما هو أو يسقط بتقرير.
const Set<String> batchExtensions = {'.docx', '.pptx', '.ppsx', '.potx'};

/// ملفّ في الدفعة: مساره الكامل، ومساره النسبي كما سيخرج.
typedef BatchFile = ({String path, String relative});

/// يجمع مستندات المجلد وما تحته، مرتّبةً.
List<BatchFile> findDocuments(Directory root) {
  final base = root.absolute.path;
  final found = <BatchFile>[];

  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    // `~$` ملفات قفل يكتبها Word، والمخفيّة ليست مستندات المستخدم.
    if (name.startsWith(r'~$') || name.startsWith('.')) continue;
    final dot = name.lastIndexOf('.');
    if (dot < 0) continue;
    if (!batchExtensions.contains(name.substring(dot).toLowerCase())) continue;

    found.add((
      path: entity.absolute.path,
      relative: entity.absolute.path.substring(base.length + 1),
    ));
  }

  found.sort((a, b) => a.relative.compareTo(b.relative));
  return found;
}

typedef BatchProgress = void Function(int done, int total, String name);

/// يطبّق [plan] على [files] ويكتب المخرَجات تحت [outDirectory].
Future<BatchReport> runBatch({
  required List<BatchFile> files,
  required String outDirectory,
  required StylePlan plan,
  BatchProgress? onProgress,
}) async {
  final entries = <BatchEntry>[];

  for (var i = 0; i < files.length; i++) {
    onProgress?.call(i, files.length, files[i].relative);
    entries.add(await _restyleOne(files[i], outDirectory, plan));
  }

  onProgress?.call(files.length, files.length, '');
  return BatchReport(entries);
}

Future<BatchEntry> _restyleOne(
  BatchFile file,
  String outDirectory,
  StylePlan plan,
) => Isolate.run(() {
  final bytes = Uint8List.fromList(File(file.path).readAsBytesSync());
  final result = restyle(bytes, plan);

  if (result case Ok(:final value)) {
    // البنية تُحفَظ، والكتابة ذرّية: مؤقّت ثم إعادة تسمية (`00` §١/٣).
    final target = '$outDirectory${Platform.pathSeparator}${file.relative}';
    File(target).parent.createSync(recursive: true);
    File('$target.part')
      ..writeAsBytesSync(value.bytes)
      ..renameSync(target);
  }

  return BatchEntry.of(file.relative, result);
});
