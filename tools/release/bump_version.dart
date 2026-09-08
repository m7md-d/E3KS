// أداة رفع رقم الإصدار في مواضعه كلّها معًا.
//
// القاعدة `08` §3: رقم واحد للمنتج كلّه، واختبارٌ يحرس تطابقه. هذه الأداة
// هي الطرف الآخر من ذلك الحارس — ترفعها دفعةً فلا ينحرف واحد.
//
// **ومواضع منها مشتقّة لا مكتوبة باليد:** `pubspec.lock` في التطبيق وفي
// سطر الأوامر يسجّل نسخة `e3ks_engine` لأنها اعتمادية مسار. وتركهما على
// الرقم القديم يُسقط `pub get --enforce-lockfile` بـ«Unable to satisfy
// pubspec.yaml using pubspec.lock» — فيسقط الفحص عند العامل، **ويسقط
// الإصدار نفسه** لأن `release.yml` يرفع الرقم ثم يجلب الحزم بنفس الراية.
// وقع هذا فعلًا عند رفع ٠٫٢٫٠. والسطر المكتوب هنا هو نفسه الذي يكتبه
// `pub get`، والقفل يبقى قفلًا: بقيّة الحزم مثبَّتة كما كانت.
//
// ومنها `README.md`: يعلن الرقم في شارة الرأس وفي فقرة «Versioning». وقع
// هذا فعلًا عند رفع ٠٫٢٫١ — رُفعت المواضع الستّة وبقي الريدمي يقول ٠٫٢٫٠،
// وهو أول ما يقرأه القادم إلى المستودع.
//
//   dart tools/release/bump_version.dart --check      يتحقّق من التطابق فقط
//   dart tools/release/bump_version.dart patch        0.1.0 → 0.1.1
//   dart tools/release/bump_version.dart minor        0.1.0 → 0.2.0
//   dart tools/release/bump_version.dart major        0.1.0 → 1.0.0
//   dart tools/release/bump_version.dart --set 0.4.2  رقم صريح
//   dart tools/release/bump_version.dart --next v0.3.1 رقمُ الإصدار القادم
//
// `--next` استعلام لا يكتب شيئًا: يأخذ آخر وسم منشور ويطبع ما يُصدَر بعده.
// إن كان رقم الشجرة أعلى منه فهو المطلوب — رفعه المالك بيده لإصدار أكبر.
// وإلا فالخانة الأخيرة وحدها ترتفع. **الآلة لا تقرّر أكثر من هذا** (`08` §6).
//
// Dart خالص بلا حزم: يعمل في أي بيئة فيها Dart، ومنها منصّة التكامل.

import 'dart:io';

/// المواضع الأربعة، بمسارات نسبية إلى جذر المستودع.
const _pubspecs = [
  'apps/e3ks_desktop/pubspec.yaml',
  'packages/e3ks_engine/pubspec.yaml',
  'tools/e3ks_cli/pubspec.yaml',
];
const _dartSource = 'apps/e3ks_desktop/lib/app/about.dart';

/// أقفال الحزم التي تعتمد المحرّك بالمسار.
const _lockfiles = [
  'apps/e3ks_desktop/pubspec.lock',
  'tools/e3ks_cli/pubspec.lock',
];

/// الواجهة المقروءة: الشارة اسمًا وصورةً، وفقرة «Versioning».
const _readme = 'README.md';

// المسافة الأفقية وحدها: `\s` يبتلع سطر الفراغ بعد الرقم فيختفي من
// الملف مع كل رفع.
final _pubspecLine = RegExp(
  r'^version:[^\S\r\n]*(\S+)[^\S\r\n]*$',
  multiLine: true,
);
final _dartLine = RegExp(r"const String appVersion = '([^']+)';");

/// سطر نسخة `e3ks_engine` داخل مدخلته في القفل، لا أيّ `version:` آخر.
final _lockLine = RegExp(
  r'^  e3ks_engine:\n(?:[ ]{4}.*\n)*?[ ]{4}version: "([^"]+)"',
  multiLine: true,
);

/// ما يسبق الرقم في README يبقى كما هو، والرقم وحده يُستبدل.
final _readmeSites = RegExp(
  r'(alt="Version |/badge/version-|Current version \*\*)(\d+\.\d+\.\d+)',
);
final _semver = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

void main(List<String> arguments) {
  final root = _repoRoot();

  // **المواضع المكتوبة باليد هي المرجع.** الأقفال مشتقّة منها، فانحرافها
  // خللٌ يُصلَح لا رأيٌ يُوازَن — ولو أُدخلت في الموازنة لامتنع الرفع الذي
  // يصلحها.
  final found = <String, String>{
    for (final pubspec in _pubspecs)
      pubspec: _read(root, pubspec, _pubspecLine),
    _dartSource: _read(root, _dartSource, _dartLine),
  };

  final distinct = found.values.toSet();
  if (distinct.length != 1) {
    stderr.writeln('الإصدار منحرف بين المواضع:');
    found.forEach((file, version) => stderr.writeln('  $version  $file'));
    exit(1);
  }

  final current = distinct.single;
  if (arguments.isEmpty || arguments.first == '--check') {
    final stale = {
      for (final lock in _lockfiles)
        if (_read(root, lock, _lockLine) != current)
          lock: _read(root, lock, _lockLine),
    };
    final behind = _readmeVersions(root).where((v) => v != current).toSet();
    if (behind.isNotEmpty) stale[_readme] = behind.join('، ');
    if (stale.isNotEmpty) {
      stderr.writeln('موضعٌ مشتقّ على رقمٍ قديم (المطلوب $current):');
      stale.forEach((file, version) => stderr.writeln('  $version  $file'));
      stderr.writeln(
        'أصلحه: dart tools/release/bump_version.dart --set $current',
      );
      exit(1);
    }
    stdout.writeln(current);
    return;
  }

  if (arguments.first == '--next') {
    final last = arguments.length > 1 ? arguments[1] : '';
    stdout.writeln(_nextRelease(current, last));
    return;
  }

  final next = _next(current, arguments);
  for (final pubspec in _pubspecs) {
    _write(root, pubspec, _pubspecLine, 'version: $next');
  }
  _write(root, _dartSource, _dartLine, "const String appVersion = '$next';");
  for (final lock in _lockfiles) {
    _writeLock(root, lock, next);
  }
  _readmeVersions(root); // يصرخ إن غاب الملف أو غاب الرقم منه
  _writeReadme(root, next);

  stdout.writeln(next);
}

/// جذر المستودع من موضع هذه الأداة — فتعمل من أي مجلد.
Directory _repoRoot() => Directory.fromUri(Platform.script.resolve('../../'));

String _read(Directory root, String path, RegExp pattern) {
  final file = File.fromUri(root.uri.resolve(path));
  if (!file.existsSync()) {
    stderr.writeln('مفقود: $path');
    exit(1);
  }
  final match = pattern.firstMatch(file.readAsStringSync());
  if (match == null) {
    stderr.writeln('لا سطر إصدار في: $path');
    exit(1);
  }
  return match.group(1)!;
}

void _write(Directory root, String path, RegExp pattern, String line) {
  final file = File.fromUri(root.uri.resolve(path));
  file.writeAsStringSync(file.readAsStringSync().replaceFirst(pattern, line));
}

/// يكتب النسخة في مدخلة `e3ks_engine` وحدها من القفل.
///
/// الاستبدال على آخر ظهور داخل المطابقة — وهو سطر النسخة، آخر سطورها.
void _writeLock(Directory root, String path, String version) {
  final file = File.fromUri(root.uri.resolve(path));
  final text = file.readAsStringSync();
  file.writeAsStringSync(
    text.replaceFirstMapped(_lockLine, (match) {
      final whole = match.group(0)!;
      final old = '"${match.group(1)!}"';
      final at = whole.lastIndexOf(old);
      return whole.replaceRange(at, at + old.length, '"$version"');
    }),
  );
}

/// كل رقمٍ يعلنه README، بترتيب وروده.
List<String> _readmeVersions(Directory root) {
  final file = File.fromUri(root.uri.resolve(_readme));
  if (!file.existsSync()) {
    stderr.writeln('مفقود: $_readme');
    exit(1);
  }
  final found = [
    for (final match in _readmeSites.allMatches(file.readAsStringSync()))
      match.group(2)!,
  ];
  if (found.isEmpty) {
    stderr.writeln('لا رقم إصدار في: $_readme');
    exit(1);
  }
  return found;
}

void _writeReadme(Directory root, String version) {
  final file = File.fromUri(root.uri.resolve(_readme));
  file.writeAsStringSync(
    file.readAsStringSync().replaceAllMapped(
      _readmeSites,
      (match) => '${match.group(1)}$version',
    ),
  );
}

/// رقم الإصدار القادم بالنظر إلى آخر وسم منشور.
///
/// بلا وسم ⇒ الشجرة هي أول إصدار كما هي. وإن سبقت الشجرةُ آخرَ وسم فقد
/// رفعها المالك عمدًا فتُحترم. وإلا فالخانة الأخيرة ترتفع فوق آخر منشور،
/// فلا يتكرّر رقم ولا يتراجع.
String _nextRelease(String current, String lastTag) {
  final last = _parse(lastTag.replaceFirst(RegExp('^v'), ''));
  if (last == null) return current;

  final tree = _parse(current);
  if (tree == null) {
    stderr.writeln('الإصدار الحالي ليس بصيغة X.Y.Z: $current');
    exit(1);
  }
  if (_compare(tree, last) > 0) return current;
  return '${last[0]}.${last[1]}.${last[2] + 1}';
}

List<int>? _parse(String value) {
  final match = _semver.firstMatch(value.trim());
  if (match == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
}

int _compare(List<int> a, List<int> b) {
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return 0;
}

String _next(String current, List<String> arguments) {
  if (arguments.first == '--set') {
    if (arguments.length < 2 || !_semver.hasMatch(arguments[1])) {
      stderr.writeln('--set يحتاج رقمًا بصيغة X.Y.Z');
      exit(1);
    }
    return arguments[1];
  }

  final parts = _semver.firstMatch(current);
  if (parts == null) {
    stderr.writeln('الإصدار الحالي ليس بصيغة X.Y.Z: $current');
    exit(1);
  }
  final major = int.parse(parts.group(1)!);
  final minor = int.parse(parts.group(2)!);
  final patch = int.parse(parts.group(3)!);

  return switch (arguments.first) {
    'major' => '${major + 1}.0.0',
    'minor' => '$major.${minor + 1}.0',
    'patch' => '$major.$minor.${patch + 1}',
    _ => () {
      stderr.writeln('الخانة: major أو minor أو patch أو --set X.Y.Z');
      exit(1);
    }(),
  };
}
