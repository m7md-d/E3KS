/// تحميل المستند وتصديره خارج خيط الواجهة.
///
/// القاعدة `03`: كل عملية على ملف تجري في isolate — الواجهة لا تتجمّد.
/// المحرّك يُرجع نماذج بيانات خالصة، وهي قابلة للنقل بين الـisolates.
library;

import 'dart:isolate';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';

/// مستند مفتوح، جاهز للعمل عليه.
final class LoadedDocument {
  const LoadedDocument({
    required this.path,
    required this.fileName,
    required this.bytes,
    required this.report,
    required this.preview,
    required this.format,
  });

  final String path;
  final String fileName;
  final Uint8List bytes;

  /// حصيلة الفحص، أو `null` ما دام الفحص جاريًا.
  ///
  /// **الفحص خارج مسار أوّل رسمة.** يكلّف ٣٢٥ms لمئة صفحة وأوّلُ صفحاتِ
  /// المعاينة ٤١، والصفحة لا تنتظره — يصل بعدها فتمتلئ اللوحات. و`null`
  /// هنا حالٌ يُعلَن في الواجهة، لا تقريرٌ فارغ يزعم أن المستند بلا ألوان
  /// (`00` §5).
  final InspectionReport? report;
  final DocumentPreview preview;

  /// الصيغة كما تعرّف عليها المحرّك من محتوى الملف لا من امتداده.
  final FormatId format;

  /// نسخةٌ بمعاينةٍ أتمّ — تحلّ محلّ معاينة أوّل الصفحات حين تجهز.
  LoadedDocument withPreview(DocumentPreview full) => LoadedDocument(
    path: path,
    fileName: fileName,
    bytes: bytes,
    report: report,
    preview: full,
    format: format,
  );

  /// نسخةٌ بحصيلة الفحص، حين تصل.
  LoadedDocument withReport(InspectionReport value) => LoadedDocument(
    path: path,
    fileName: fileName,
    bytes: bytes,
    report: value,
    preview: preview,
    format: format,
  );
}

/// سبب الفشل — **بالرموز لا بالنصّ**.
///
/// لو خزّنّا الرسالة جاهزة لبقيت محنّطة بلغة وقت وقوعها؛ وبالرموز تُترجَم
/// مع تبديل المستخدم للّغة.
final class LoadFailure {
  const LoadFailure(this.issues);
  final List<EngineIssue> issues;
}

/// نتيجة التحميل: مستند أو سبب واضح للفشل.
typedef LoadResult = ({LoadedDocument? document, LoadFailure? failure});

/// كم صفحةً تُستخرَج في الدفعة الأولى لكل جزء.
///
/// **العدد يكفي أوّل رسمة وزيادة**: القائمة المُحجَّمة تبني ما يُرى وحده
/// (٤ صفحات على أوسع نافذة)، وما بعده يصل قبل أن يبلغه التمرير.
const int firstPages = 8;

/// يفتح المستند ويستخرج منه **أوّل صفحات** المعاينة، ولا يفحصه.
///
/// **لأن الانتظار يُرى.** ثلاث دفعات، وترتيبها هو ترتيب ما يراه المستخدم:
///
/// | الدفعة | تكلفتها لمئة صفحة | ما تُظهره |
/// |---|---|---|
/// | هذه | ٤١ms | الصفحة على الشاشة |
/// | [loadInspection] | ٣٢٥ms | لوحات الألوان والخطوط والعلامات |
/// | [loadFullPreview] | ٦٠٩ms | بقيّة الصفحات |
///
/// وكانت الثلاث دفعةً واحدة بـ١٣٣٧ms قبل أن يظهر شيء.
Future<LoadResult> loadDocument(
  String path,
  String fileName,
  Uint8List bytes, {
  int? maxPages = firstPages,
}) => Isolate.run(() {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) {
    return (document: null, failure: LoadFailure(issues));
  }
  final package = (opened as Ok<DocumentPackage>).value;

  // الصيغة تُقرَّر من محتوى الحاوية. الواجهة لا تعرف Word من PowerPoint،
  // ولا تحتاج: إضافة صيغة ثالثة لا تغيّر سطرًا هنا.
  final detected = formatFor(package);
  if (detected case Failed(:final issues)) {
    return (document: null, failure: LoadFailure(issues));
  }
  final format = (detected as Ok<DocumentFormat>).value;

  return (
    document: LoadedDocument(
      path: path,
      fileName: fileName,
      bytes: bytes,
      report: null,
      preview: format.preview(package, maxPages: maxPages),
      format: format.id,
    ),
    failure: null,
  );
});

/// حصيلة الفحص، بعد أن عُرضت الصفحة.
///
/// `null` عند تعذّره — والمستند معروضٌ على كل حال، فلا يُسقَط ما نجح لأجل
/// ما فشل. وأسباب العطب الحقيقية يبلّغها فتحُ الملف قبل هذا بدفعة.
Future<InspectionReport?> loadInspection(Uint8List bytes) => Isolate.run(() {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed()) return null;
  final package = (opened as Ok<DocumentPackage>).value;
  final detected = formatFor(package);
  if (detected case Failed()) return null;
  final inspected = (detected as Ok<DocumentFormat>).value.inspect(package);
  return inspected is Ok<InspectionReport> ? inspected.value : null;
});

/// المعاينة كاملةً، بعد أن عُرضت أوائلها.
///
/// **يُعاد الفتح والتحليل** بدل حمل الحاوية بين النداءين: الفارق قياسه
/// ٧٪ من زمن الاستخراج، وحملُها يُبقي عشرات الميغابايت في الذاكرة بين
/// مرحلتين — وهو ما نتخلّص منه لا ما نزيده.
Future<DocumentPreview?> loadFullPreview(Uint8List bytes) => Isolate.run(() {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed()) return null;
  final package = (opened as Ok<DocumentPackage>).value;
  final detected = formatFor(package);
  if (detected case Failed()) return null;
  return (detected as Ok<DocumentFormat>).value.preview(package);
});

/// نتيجة التصدير: بايتات جاهزة، أو أسباب المنع.
typedef ExportResult = ({
  Uint8List? bytes,
  TransformReport? report,
  LoadFailure? failure,
});

Future<ExportResult> buildOutput(Uint8List source, StylePlan plan) =>
    Isolate.run(() {
      final result = restyle(source, plan);
      if (result case Failed(:final issues)) {
        return (bytes: null, report: null, failure: LoadFailure(issues));
      }
      final outcome = (result as Ok<RestyleOutcome>).value;
      return (bytes: outcome.bytes, report: outcome.report, failure: null);
    });
