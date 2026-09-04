/// نتيجة عملية في المحرّك: إمّا قيمة، وإمّا قائمة مشاكل.
library;

import 'engine_issue.dart';

sealed class EngineResult<T> {
  const EngineResult();

  bool get isOk => this is Ok<T>;

  /// القيمة عند النجاح، و`null` عند الفشل.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Failed<T>() => null,
  };

  List<EngineIssue> get issues => switch (this) {
    Ok<T>(:final warnings) => warnings,
    Failed<T>(:final issues) => issues,
  };
}

final class Ok<T> extends EngineResult<T> {
  const Ok(this.value, {this.warnings = const []});

  final T value;

  /// تنبيهات لا تمنع النجاح. المبدأ `00` §5: الصمت ممنوع.
  final List<EngineIssue> warnings;
}

final class Failed<T> extends EngineResult<T> {
  const Failed(this.issues);

  @override
  final List<EngineIssue> issues;
}
