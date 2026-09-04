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

DocumentPackage _openOrExit(Uint8List bytes) {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) {
    for (final issue in issues) {
      stderr.writeln('✖ ${m.describeIssue(issue)}');
    }
    exit(65);
  }
  return (opened as Ok<DocumentPackage>).value;
}

void _inspect(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('✖ ${m.ui["noFile"]}');
    exit(64);
  }
  final package = _openOrExit(_readOrExit(args.first));
  final result = const DocxInspector().inspect(package);
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
  if (report.highlights.isNotEmpty) {
    stdout.writeln('\n── ${m.ui["highlights"]} ──\n  ${report.highlights}');
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
  final result = restyleDocx(_readOrExit(args.first), plan);

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
  stdout.writeln(
    '  ${m.ui["partsChanged"]}  : ${report.changedParts.length}'
    '  (${report.changedParts.join("، ")})',
  );
  if (report.preservedFonts.isNotEmpty) {
    stdout.writeln('  ${m.ui["fontsProtected"]}  : ${report.preservedFonts}');
  }
  for (final issue in result.issues) {
    stdout.writeln('  ⚠ ${m.describeIssue(issue)}');
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

  return StylePlan(
    colors: colors,
    fonts: fonts,
    preserveFonts: preserve,
    removeHighlight: root['removeHighlight'] == true,
  );
}
