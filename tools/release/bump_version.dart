// أداة رفع رقم الإصدار في مواضعه الأربعة معًا.
//
// القاعدة `08` §3: رقم واحد للمنتج كلّه، واختبارٌ يحرس تطابقه. هذه الأداة
// هي الطرف الآخر من ذلك الحارس — ترفع الأربعة دفعةً فلا ينحرف واحد.
//
//   dart tools/release/bump_version.dart --check      يتحقّق من التطابق فقط
//   dart tools/release/bump_version.dart patch        0.1.0 → 0.1.1
//   dart tools/release/bump_version.dart minor        0.1.0 → 0.2.0
//   dart tools/release/bump_version.dart major        0.1.0 → 1.0.0
//   dart tools/release/bump_version.dart --set 0.4.2  رقم صريح
//
// ‏Dart خالص بلا حزم: يعمل في أي بيئة فيها Dart، ومنها منصّة التكامل.

import 'dart:io';

/// المواضع الأربعة، بمسارات نسبية إلى جذر المستودع.
const _pubspecs = [
  'apps/e3ks_desktop/pubspec.yaml',
  'packages/e3ks_engine/pubspec.yaml',
  'tools/e3ks_cli/pubspec.yaml',
];
const _dartSource = 'apps/e3ks_desktop/lib/app/about.dart';

// المسافة الأفقية وحدها: `\s` يبتلع سطر الفراغ بعد الرقم فيختفي من
// الملف مع كل رفع.
final _pubspecLine = RegExp(
  r'^version:[^\S\r\n]*(\S+)[^\S\r\n]*$',
  multiLine: true,
);
final _dartLine = RegExp(r"const String appVersion = '([^']+)';");
final _semver = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

void main(List<String> arguments) {
  final root = _repoRoot();

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
    stdout.writeln(current);
    return;
  }

  final next = _next(current, arguments);
  for (final pubspec in _pubspecs) {
    _write(root, pubspec, _pubspecLine, 'version: $next');
  }
  _write(root, _dartSource, _dartLine, "const String appVersion = '$next';");

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

String _next(String current, List<String> arguments) {
  if (arguments.first == '--set') {
    if (arguments.length < 2 || !_semver.hasMatch(arguments[1])) {
      stderr.writeln('‏--set يحتاج رقمًا بصيغة X.Y.Z');
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
      stderr.writeln('الخانة: major أو minor أو patch أو ‎--set X.Y.Z');
      exit(1);
    }(),
  };
}
