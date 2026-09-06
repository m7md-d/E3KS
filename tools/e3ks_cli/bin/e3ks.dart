// E3KS — اعكس. واجهة سطر الأوامر.
// Copyright (C) 2026  m7md-d
//
// برنامج حرّ تحت رخصة جنو العمومية العامة، الإصدار الثالث أو أيّ إصدار
// لاحق. يُوزَّع بلا أيّ ضمان. النصّ الكامل في `LICENSE` بجذر المشروع.
/// واجهة سطر أوامر رفيعة. كل المنطق في المحرّك — القاعدة `01`.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_cli/messages_ar.dart' as m;
import 'package:e3ks_engine/e3ks_engine.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stdout.writeln(m.usage);
    exit(64);
  }
  switch (args.first) {
    case 'inspect':
      _inspect(args.skip(1).toList());
    case 'restyle':
      _restyle(args.skip(1).toList());
    case 'restyle-dir':
      _restyleDir(args.skip(1).toList());
    default:
      stderr.writeln('${m.ui["unknownCommand"]}: ${args.first}\n');
      stdout.writeln(m.usage);
      exit(64);
  }
}

String? _option(List<String> args, String name) {
  final index = args.indexOf('--$name');
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

Uint8List _readOrExit(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('✖ ${m.ui["missingFile"]}: $path');
    exit(66);
  }
  return Uint8List.fromList(file.readAsBytesSync());
}

Never _failWith(List<EngineIssue> issues) {
  for (final issue in issues) {
    stderr.writeln('✖ ${m.describeIssue(issue)}');
  }
  exit(65);
}

DocumentPackage _openOrExit(Uint8List bytes) {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) _failWith(issues);
  return (opened as Ok<DocumentPackage>).value;
}

void _inspect(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('✖ ${m.ui["noFile"]}');
    exit(64);
  }
  final package = _openOrExit(_readOrExit(args.first));
  final detected = formatFor(package);
  if (detected case Failed(:final issues)) _failWith(issues);
  final result = (detected as Ok<DocumentFormat>).value.inspect(package);
  final report = (result as Ok<InspectionReport>).value;

  if (args.contains('--json')) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'colors': [
          for (final c in report.colors)
            {
              'hex': c.color.value,
              'count': c.count,
              'role': c.dominantRole.name,
              'inContent': c.isInContent,
              'themeLinked': c.themeLinked,
              'samples': c.samples,
            },
        ],
        'fonts': [
          for (final f in report.fonts)
            {
              'name': f.name,
              'count': f.count,
              'inContent': f.isInContent,
              'monospaced': f.looksMonospaced,
            },
        ],
        'marks': [
          for (final mark in report.marks)
            {
              // نفس صيغة `removeMarks` في الخطة: ما يخرج من الفحص يدخل
              // في الخطة بلا صياغة يدوية.
              'mark': mark.mark.toString(),
              'kind': mark.mark.kind.name,
              'count': mark.count,
              'inContent': mark.isInContent,
              'samples': mark.samples,
            },
        ],
      }),
    );
    return;
  }

  stdout.writeln(
    '${m.ui["scannedParts"]}: ${report.scannedParts.length}   '
    '${m.ui["colors"]}: ${report.colors.length}   '
    '${m.ui["fonts"]}: ${report.fonts.length}',
  );

  stdout.writeln('\n── ${m.ui["identityColors"]} ──');
  for (final c in report.contentColors) {
    _printColor(c);
  }

  final inherited = report.inheritedColors;
  if (inherited.isNotEmpty) {
    stdout.writeln('\n── ${m.ui["inheritedColors"]} (${inherited.length}) ──');
    stdout.writeln(
      '   ${inherited.take(10).map((c) => c.color.value).join("  ")}'
      '${inherited.length > 10 ? "  …" : ""}',
    );
  }

  stdout.writeln('\n── ${m.ui["fonts"]} ──');
  for (final f in report.fonts) {
    final slots = f.bySlot.entries.map((e) => m.slotNames[e.key]).join('، ');
    stdout.writeln(
      '  ${f.name.padRight(24)} ${f.count.toString().padLeft(5)}  '
      '$slots${f.looksMonospaced ? '   ⟵ ${m.ui["suggestProtect"]}' : ''}',
    );
  }
  if (report.marks.isNotEmpty) {
    stdout.writeln('\n── ${m.ui["marks"]} ──');
    for (final mark in report.marks) {
      final sample = mark.samples.isEmpty ? '' : '  «${mark.samples.first}»';
      stdout.writeln(
        '  ${mark.mark.toString().padRight(24)} '
        '${mark.count.toString().padLeft(5)}  '
        '${(m.markKinds[mark.mark.kind] ?? "").padRight(13)}$sample',
      );
    }
  }
}

void _printColor(ColorUsage c) {
  final sample = c.samples.isEmpty ? '' : '  «${c.samples.first}»';
  stdout.writeln(
    '  ${c.color.value}  ${c.count.toString().padLeft(5)}  '
    '${(m.roleNames[c.dominantRole] ?? "").padRight(13)}'
    '${m.describeColor(c.color).padRight(20)}'
    '${c.themeLinked ? "[ثيم] " : ""}$sample',
  );
}

void _restyle(List<String> args) {
  final planPath = _option(args, 'plan');
  final outPath = _option(args, 'out');
  if (args.isEmpty || planPath == null || outPath == null) {
    stderr.writeln('✖ يلزم: <ملف> --plan <خطة.json> --out <مخرج.docx>');
    exit(64);
  }

  final plan = _parsePlan(utf8.decode(_readOrExit(planPath)));
  final result = restyle(_readOrExit(args.first), plan);

  if (result case Failed(:final issues)) {
    stderr.writeln('✖ ${m.ui["writeCancelled"]}');
    for (final issue in issues) {
      stderr.writeln('   ${m.describeIssue(issue)}');
      if (issue.detail != null) stderr.writeln('     ↳ ${issue.detail}');
    }
    exit(65);
  }

  final outcome = (result as Ok<RestyleOutcome>).value;
  final report = outcome.report;

  // كتابة ذرّية: مؤقّت ثم إعادة تسمية — `00` §١/٣.
  final temp = File('$outPath.part')..writeAsBytesSync(outcome.bytes);
  temp.renameSync(outPath);

  stdout.writeln('✔ $outPath');
  stdout.writeln(
    '  ${m.ui["colorsReplaced"]} : '
    '${report.totalColorReplacements} ${m.ui["in_"]} '
    '${report.colorReplacements.length} ${m.ui["colorsWord"]}',
  );
  stdout.writeln(
    '  ${m.ui["fontsReplaced"]} : ${report.totalFontReplacements}',
  );
  stdout.writeln('  ${m.ui["themeRemoved"]}: ${report.themeAttributesRemoved}');
  if (report.markRemovals.isNotEmpty) {
    stdout.writeln(
      '  ${m.ui["marksLifted"]} : ${report.totalMarkRemovals} '
      '${m.ui["in_"]} ${report.markRemovals.length}',
    );
  }
  stdout.writeln(
    '  ${m.ui["partsChanged"]}  : ${report.changedParts.length}'
    '  (${report.changedParts.join("، ")})',
  );
  if (report.preservedFonts.isNotEmpty) {
    stdout.writeln('  ${m.ui["fontsProtected"]}  : ${report.preservedFonts}');
  }
  for (final issue in result.issues) {
    stdout.writeln('  ! ${m.describeIssue(issue)}');
  }
}

StylePlan _parsePlan(String source) {
  final root = jsonDecode(source);
  if (root is! Map<String, dynamic>) {
    stderr.writeln('✖ ${m.ui["planNotObject"]}');
    exit(65);
  }

  final colors = <HexColor, HexColor>{};
  final rawColors = root['colors'];
  if (rawColors is Map<String, dynamic>) {
    rawColors.forEach((from, to) {
      final source = HexColor.tryParse(from);
      final target = HexColor.tryParse(to is String ? to : null);
      if (source == null || target == null) {
        stderr.writeln('✖ ${m.ui["badColor"]}: "$from" → "$to"');
        exit(65);
      }
      colors[source] = target;
    });
  }

  FontPlan? fonts;
  final rawFonts = root['fonts'];
  if (rawFonts is Map<String, dynamic>) {
    fonts = FontPlan(
      latin: rawFonts['latin'] as String?,
      arabic: rawFonts['arabic'] as String?,
      eastAsian: rawFonts['eastAsian'] as String?,
    );
  }

  final preserve = <String>{};
  final rawPreserve = root['preserveFonts'];
  if (rawPreserve is List) {
    for (final item in rawPreserve) {
      if (item is String) preserve.add(item);
    }
  }

  // علامات بعينها تُرفع: `highlight:yellow` أو `textShading:#D9D9D9`.
  final marks = <TextMark>{};
  final rawMarks = root['removeMarks'];
  if (rawMarks is List) {
    for (final item in rawMarks) {
      final mark = TextMark.tryParse(item is String ? item : null);
      if (mark == null) {
        stderr.writeln('✖ ${m.ui["badMark"]}: $item');
        exit(65);
      }
      marks.add(mark);
    }
  }

  return StylePlan(
    colors: colors,
    fonts: fonts,
    preserveFonts: preserve,
    removeMarks: marks,
    removeHighlight: root['removeHighlight'] == true,
    removeTextShading: root['removeTextShading'] == true,
  );
}

/// امتدادات البحث في المجلد.
///
/// **للعثور على الملفات وحدها.** الصيغة الفعلية يقرّرها المحرّك من محتوى
/// الملف (`formatFor`)، فملفٌ أُعيدت تسميته يُعالَج بما هو أو يسقط بتقرير.
const Set<String> _documentExtensions = {'.docx', '.pptx', '.ppsx', '.potx'};

/// كتابة ذرّية: مؤقّت ثم إعادة تسمية — `00` §١/٣.
void _writeAtomically(String path, Uint8List bytes) {
  final target = File(path);
  target.parent.createSync(recursive: true);
  File('$path.part')
    ..writeAsBytesSync(bytes)
    ..renameSync(path);
}

List<File> _documentsIn(Directory root) {
  final found = <File>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    // ‏`~$` ملفات قفل يكتبها Word، والمخفيّة ليست مستندات المستخدم.
    if (name.startsWith('~\$') || name.startsWith('.')) continue;
    final dot = name.lastIndexOf('.');
    if (dot < 0) continue;
    if (!_documentExtensions.contains(name.substring(dot).toLowerCase())) {
      continue;
    }
    found.add(entity);
  }
  found.sort((a, b) => a.path.compareTo(b.path));
  return found;
}

void _restyleDir(List<String> args) {
  final planPath = _option(args, 'plan');
  final outPath = _option(args, 'out');
  if (args.isEmpty || planPath == null || outPath == null) {
    stderr.writeln('✖ ${m.ui["needDirPlanAndOut"]}');
    exit(64);
  }

  final source = Directory(args.first);
  if (!source.existsSync()) {
    stderr.writeln('✖ ${m.ui["missingDir"]}: ${args.first}');
    exit(66);
  }

  // المصدر مقدّس (`00` §١/٤): لا نكتب فوقه ولو طلب المستخدم.
  final out = Directory(outPath);
  if (out.absolute.path == source.absolute.path) {
    stderr.writeln('✖ ${m.ui["sameDir"]}');
    exit(64);
  }

  final files = _documentsIn(source);
  if (files.isEmpty) {
    stderr.writeln('✖ ${m.ui["noDocuments"]}');
    exit(66);
  }

  final plan = _parsePlan(utf8.decode(_readOrExit(planPath)));
  final base = source.absolute.path;
  final entries = <BatchEntry>[];

  for (final file in files) {
    // البنية تُحفَظ: مسار الملف تحت المصدر هو مساره تحت المخرَج.
    final relative = file.absolute.path.substring(base.length + 1);
    final result = restyle(Uint8List.fromList(file.readAsBytesSync()), plan);
    entries.add(BatchEntry.of(relative, result));

    if (result case Ok(:final value)) {
      _writeAtomically('${out.absolute.path}/$relative', value.bytes);
      final report = value.report;
      // بصيغة «الاسم: العدد» لا «العدد اسمًا»: العربية تُعرب المعدود،
      // وصياغةٌ آلية تُخرج «31 خطوط».
      stdout.writeln(
        '✔ $relative  '
        '${m.ui["colors"]}: ${report.totalColorReplacements}  '
        '${m.ui["fonts"]}: ${report.totalFontReplacements}',
      );
    } else if (result case Failed(:final issues)) {
      stderr.writeln('✖ $relative');
      for (final issue in issues) {
        stderr.writeln('   ${m.describeIssue(issue)}');
      }
    }
  }

  final report = BatchReport(entries);
  stdout.writeln('');
  stdout.writeln(
    '${m.ui["batchWritten"]}: ${report.written.length} '
    '${m.ui["batchOf"]} ${entries.length}'
    '${report.unchanged.isEmpty ? "" : "  (${m.ui["batchUnchanged"]}: ${report.unchanged.length})"}',
  );
  if (report.failed.isNotEmpty) {
    stdout.writeln('${m.ui["batchFailed"]}: ${report.failed.length}');
  }
  stdout.writeln(
    '${m.ui["colorsReplaced"]}: ${report.totalColorReplacements}  '
    '${m.ui["fontsReplaced"]}: ${report.totalFontReplacements}',
  );

  // لونٌ لا يُطابق ملفًّا واحدًا عادي؛ ولا يُطابق أربعين خطأٌ في الخطة.
  final never = report.unmatchedEverywhere;
  if (never.isNotEmpty) {
    stdout.writeln(
      '! ${m.ui["neverMatched"]}: ${never.map((c) => c.value).join("، ")}',
    );
  }

  if (report.failed.isNotEmpty) exit(65);
}
