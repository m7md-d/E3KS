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
  });

  final String path;
  final String fileName;
  final Uint8List bytes;
  final InspectionReport report;
  final DocumentPreview preview;
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

Future<LoadResult> loadDocument(
  String path,
  String fileName,
  Uint8List bytes,
) => Isolate.run(() {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) {
    return (document: null, failure: LoadFailure(issues));
  }
  final package = (opened as Ok<DocumentPackage>).value;

  final inspected = const DocxInspector().inspect(package);
  if (inspected case Failed(:final issues)) {
    return (document: null, failure: LoadFailure(issues));
  }

  return (
    document: LoadedDocument(
      path: path,
      fileName: fileName,
      bytes: bytes,
      report: (inspected as Ok<InspectionReport>).value,
      preview: const PreviewExtractor().extract(package),
    ),
    failure: null,
  );
});

/// نتيجة التصدير: بايتات جاهزة، أو أسباب المنع.
typedef ExportResult = ({
  Uint8List? bytes,
  TransformReport? report,
  LoadFailure? failure,
});

Future<ExportResult> buildOutput(Uint8List source, StylePlan plan) =>
    Isolate.run(() {
      final result = restyleDocx(source, plan);
      if (result case Failed(:final issues)) {
        return (bytes: null, report: null, failure: LoadFailure(issues));
      }
      final outcome = (result as Ok<RestyleOutcome>).value;
      return (bytes: outcome.bytes, report: outcome.report, failure: null);
    });
