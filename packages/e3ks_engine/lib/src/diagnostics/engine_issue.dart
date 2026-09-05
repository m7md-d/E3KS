/// مشكلة يبلّغ عنها المحرّك.
///
/// المحرّك لا يرمي استثناءات للتحكّم في المسار (`03`) — يُرجع نتيجة تحمل هذه.
library;

/// رمز ثابت للمشكلة. الرمز للبرمجة، والرسالة للإنسان.
enum IssueCode {
  /// الملف ليس أرشيف ZIP صالحًا.
  notAnArchive,

  /// فشل التحقّق من CRC — الملف تالف أو مبتور.
  checksumMismatch,

  /// `[Content_Types].xml` غير موجود — ليس مستند OOXML.
  missingContentTypes,

  /// `[Content_Types].xml` ليس أول مُدخَل في الأرشيف — `02` §1.
  contentTypesNotFirst,

  /// عدد الأجزاء في المخرج يخالف المصدر — `02` §9.
  partCountMismatch,

  /// طُلب جزء غير موجود.
  partNotFound,

  /// جزء XML تعذّر تحليله.
  malformedXml,

  /// عنصر في الخطة لم يُطابق شيئًا في المستند.
  unmatchedMapping,

  /// عنصر `w:t` بلا عقدة نصية — يكسر مستورد Google Docs.
  emptyTextNode,

  /// حقول Word غير متوازنة.
  unbalancedField,

  /// فشل بناء الأرشيف.
  encodeFailed,

  /// الحاوية ليست من صيغة يعرفها المحرّك.
  unsupportedFormat,

  /// صيغةٌ كتبت في جزء لا تملكه — حارس العزل بين الصيغ.
  ///
  /// خطأ برمجي عندنا لا خطأ في ملف المستخدم، ولذلك يوقف الكتابة فورًا:
  /// صيغة تلمس أجزاء غيرها قد تُخرج ملفًّا يفتحه Word ويرفضه PowerPoint.
  foreignPartTouched,
}

enum IssueSeverity { error, warning }

/// مشكلة واحدة: رمز، وموضع، ومعاملات، وتفصيل تقني للسجل.
///
/// **بلا نصّ معروض.** المحرّك يصف *ما* حدث، والواجهة تقرّر *كيف يُقال* وبأي
/// لغة (`01`). لو حمل المحرّك رسالة جاهزة لتعذّرت ترجمتها.
final class EngineIssue {
  const EngineIssue({
    required this.code,
    this.severity = IssueSeverity.error,
    this.part,
    this.detail,
    this.args = const {},
  });

  final IssueCode code;

  final IssueSeverity severity;

  /// اسم الجزء المتأثر داخل الحاوية، إن كان للمشكلة موضع.
  final String? part;

  /// تفصيل تقني للسجل — إنجليزي، لا يُعرَض للمستخدم ولا يُترجَم.
  final String? detail;

  /// معاملات تملأ فراغات الرسالة عند صياغتها: عدد، اسم، قائمة…
  final Map<String, Object?> args;

  bool get isError => severity == IssueSeverity.error;

  @override
  String toString() {
    final where = part == null ? '' : ' [$part]';
    final what = args.isEmpty ? '' : ' $args';
    final why = detail == null ? '' : ' — $detail';
    return '${code.name}$where$what$why';
  }
}
