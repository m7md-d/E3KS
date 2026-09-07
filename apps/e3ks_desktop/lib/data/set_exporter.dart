/// تصدير مجموعة العمل: كل ملفٍّ بخطّته الفعّالة، والبنية محفوظة.
///
/// **يحلّ محلّ الدفعة ذات الخطة الواحدة** ([`ADR 0005`](../../../../docs/adr/0005-مجموعة-العمل.md) §٨):
/// الملفّ المقفل يخرج بخطّته وحدها، والمستثنى يخرج بلونه الأصلي — وهذا ما
/// يتعذّر على خطّةٍ واحدة تُمرَّر على أربعين ملفًا.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';

import 'output_writer.dart';

/// ملفٌّ في التصدير: مصدره، وموضعه في المخرَج، واسمه في التقرير، وخطّته.
typedef ExportJob = ({
  String source,
  String relative,
  String name,
  StylePlan plan,
});

/// **بالعدد وحده** (`ADR 0005` §٨): مع عدّة مسارات لا يُعرف أيّها يسبق،
/// ونسبةٌ لملفٍّ بعينه تتقافز بلا معنى.
typedef ExportProgress = void Function(int done, int total);

/// عدد المسارات المتوازية.
///
/// **واحدٌ اليوم، والترتيب ملزِم: التدفّق أوّلًا ثم التوازي** (`ADR 0005` §٨).
/// كتابة التبديل ما زالت تبني الشجرة، وأربعة ملفات معًا بها ٣٫٧GB مقيسة —
/// فالتوازي قبل التدفّق يشتري زمنًا بذاكرةٍ لا يملكها جهاز المستخدم.
/// ورفعُه بعد التدفّق سطرٌ واحد، والحدّ يومها **من ميزانية الذاكرة وحجم
/// الملفّ على القرص لا من عدد الأنوية**.
const int exportLanes = 1;

/// عطلٌ من القرص لا من المستند: تعذّرت قراءة المصدر أو كتابة المخرَج.
///
/// **ولا يُصاغ برمز مشكلة من المحرّك** (`00` §4): المحرّك لا يعرف قرصًا،
/// و`IssueCode` مفرداته عن المستندات. ورسالة النظام تُعرَض كما قالها
/// (`00` §5) لا تُترجَم إلى تخمين.
typedef ExportMishap = ({String name, String reason});

/// حصيلة تصدير المجموعة: تقرير المحرّك، وما تعثّر منه على القرص.
typedef SetExport = ({BatchReport report, List<ExportMishap> mishaps});

/// يطبّق خطّة كل ملفّ ويكتب المخرَجات تحت [outDirectory].
///
/// **ولا تُحجَز مساحة ملفٍّ قبل دوره**: البايتات تُقرأ داخل عزلته وتُطلَق
/// بانتهائها، فلا تُفتح أربعون لتنتظر دورها محمَّلة.
Future<SetExport> exportSet({
  required List<ExportJob> jobs,
  required String outDirectory,
  ExportProgress? onProgress,
}) async {
  final entries = <BatchEntry>[];
  final mishaps = <ExportMishap>[];
  var done = 0;
  onProgress?.call(0, jobs.length);

  for (final job in jobs) {
    final outcome = await _exportOne(job, outDirectory);
    if (outcome.entry case final entry?) entries.add(entry);
    if (outcome.mishap case final mishap?) mishaps.add(mishap);
    onProgress?.call(++done, jobs.length);
  }

  return (report: BatchReport(entries), mishaps: mishaps);
}

/// **ملفٌّ سقط لا يُوقف البقيّة** (`BatchEntry.of`): أربعون فيها واحد تالف
/// تعني تسعة وثلاثين مخرَجًا وتقريرًا بالأخير، لا صفرًا وشكوى.
Future<({BatchEntry? entry, ExportMishap? mishap})> _exportOne(
  ExportJob job,
  String outDirectory,
) => Isolate.run(() async {
  final Uint8List bytes;
  try {
    bytes = Uint8List.fromList(File(job.source).readAsBytesSync());
  } on FileSystemException catch (error) {
    return (
      entry: null,
      mishap: (name: job.name, reason: error.osError?.message ?? error.message),
    );
  }

  final result = restyle(bytes, job.plan);
  if (result case Failed(:final issues)) {
    return (entry: BatchEntry(name: job.name, issues: issues), mishap: null);
  }

  // `!` مضمون: ما ليس `Failed` هو `Ok`، وقد رجعنا بالأولى قبل سطر.
  final outcome = (result as Ok<RestyleOutcome>).value;
  final target = '$outDirectory${Platform.pathSeparator}${job.relative}';
  try {
    File(target).parent.createSync(recursive: true);
    // **الكتابة ذرّية ومؤقّتها بعيدٌ عن الهدف** (`03`): الصندوق الرملي يمنح
    // إذنًا لما اختاره المستخدم، وملفٌّ مجاور خارجه.
    await writeOutput(target, outcome.bytes);
  } on FileSystemException catch (error) {
    return (
      entry: null,
      mishap: (name: job.name, reason: error.osError?.message ?? error.message),
    );
  }

  return (
    entry: BatchEntry(name: job.name, report: outcome.report),
    mishap: null,
  );
});
