/// حصيلة تنسيق مجموعة ملفات بخطة واحدة.
///
/// **الدفعة ليست حلقةً على `restyle` وكفى.** قيمتها في الحصيلة المجمَّعة:
/// أي ملف سقط ولماذا، وأيّها كان على الهوية الجديدة أصلًا، ولونٌ في الخطة
/// لم يُطابق شيئًا في **أي** ملف. والأخير خطأ في الخطة لا في ملف، ولا يُرى
/// إلا من فوق المجموعة — ملفٌ واحد لا يكفي للحكم عليه.
///
/// والمحرّك لا يقرأ قرصًا ولا يكتب فيه (`00` §4): المستدعي يمرّ على ملفاته،
/// ويضيف نتيجة كلّ ملف هنا.
library;

import '../diagnostics/engine_issue.dart';
import '../diagnostics/engine_result.dart';
import '../inspect/hex_color.dart';
import '../transform/transform_report.dart';
import 'restyle.dart';

/// نتيجة ملفٍّ واحد داخل الدفعة.
final class BatchEntry {
  const BatchEntry({required this.name, this.report, this.issues = const []});

  /// اسم الملف كما يعرفه المستخدم — لا مسار مطلق.
  final String name;

  /// حصيلة التحويل، أو `null` إن سقط الملف.
  final TransformReport? report;

  /// أسباب السقوط. فارغة عند النجاح.
  final List<EngineIssue> issues;

  bool get ok => report != null;

  /// **ملفٌ سقط لا يُوقف البقيّة.** أربعون ملفًا فيها واحد تالف تعني تسعة
  /// وثلاثين مخرَجًا وتقريرًا بالأخير، لا صفرًا وشكوى.
  factory BatchEntry.of(String name, EngineResult<RestyleOutcome> result) =>
      switch (result) {
        Ok(:final value) => BatchEntry(name: name, report: value.report),
        Failed(:final issues) => BatchEntry(name: name, issues: issues),
      };
}

final class BatchReport {
  const BatchReport(this.entries);

  final List<BatchEntry> entries;

  List<BatchEntry> get written => [
    for (final entry in entries)
      if (entry.ok) entry,
  ];

  List<BatchEntry> get failed => [
    for (final entry in entries)
      if (!entry.ok) entry,
  ];

  /// ملفات مرّت ولم يتغيّر فيها شيء: على الهوية الجديدة أصلًا.
  List<BatchEntry> get unchanged => [
    // `!` مضمون: `written` لا يمرّر إلا ما تقريره غير فارغ.
    for (final entry in written)
      if (entry.report!.changedNothing) entry,
  ];

  int get totalColorReplacements => written.fold(
    0,
    (sum, entry) => sum + entry.report!.totalColorReplacements,
  );

  int get totalFontReplacements => written.fold(
    0,
    (sum, entry) => sum + entry.report!.totalFontReplacements,
  );

  /// في كم ملفًّا بُدِّل كل لون. أساس السؤال «أي الملفات ما زالت على القديم».
  Map<HexColor, int> get filesByColor {
    final counts = <HexColor, int>{};
    for (final entry in written) {
      for (final color in entry.report!.colorReplacements.keys) {
        counts[color] = (counts[color] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(counts);
  }

  /// ألوان في الخطة لم تُطابق شيئًا في أي ملف مرّ.
  ///
  /// لونٌ لا يُطابق ملفًّا واحدًا أمرٌ عادي؛ ولونٌ لا يُطابق أربعين ملفًا
  /// خطأٌ في الخطة يستحقّ أن يُقال (`00` §5). ومن لا ملفّ ناجح عنده لا
  /// يَحكم: تُرجَع فارغة.
  Set<HexColor> get unmatchedEverywhere {
    final ok = written;
    if (ok.isEmpty) return const {};

    var common = ok.first.report!.unmatchedColors.toSet();
    for (final entry in ok.skip(1)) {
      common = common.intersection(entry.report!.unmatchedColors);
      if (common.isEmpty) break;
    }
    return Set.unmodifiable(common);
  }
}
