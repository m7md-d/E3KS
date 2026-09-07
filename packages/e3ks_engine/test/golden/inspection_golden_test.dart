/// المخرَج الذهبي للفحص — `04` §2.
///
/// **الغرض حارسٌ لإعادة كتابة الفحص.** الفحص ينتقل من شجرة XML إلى تدفّق
/// أحداث، وهو تغيير في الوسيلة **لا في النتيجة**. فيُثبَّت الوصف الكامل هنا
/// أوّلًا — كل لون بعدده وأدواره وأجزائه وعيّناته، وكل خطّ بفتحاته، وكل
/// علامة — ويصير أي فرق سقوطًا لا مفاجأة.
///
/// والوصف **مرتَّب حتميًّا**: خرائط تُفرَز بمفاتيحها ومجموعات كذلك، وإلّا
/// سقط الاختبار على ترتيب لا يعني شيئًا.
///
/// وملفّاته من `fixtures/` وحدها: مستندات العملاء لا تدخل المستودع، ولا
/// عيّناتُ نصّها (`03`).
///
/// لتحديث الذهبي بعد تغييرٍ **مقصود**: E3KS_UPDATE_GOLDEN=1 dart test
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:test/test.dart';

import '../fixtures/docx_fixture.dart';
import '../fixtures/pptx_fixture.dart';

/// وصفٌ نصّيّ كامل لتقرير الفحص، مرتَّبٌ حتميًّا.
String describeReport(InspectionReport report) {
  final out = StringBuffer();

  out.writeln('# الأجزاء المفحوصة');
  for (final part in [...report.scannedParts]..sort()) {
    out.writeln('  $part');
  }

  out.writeln('\n# الألوان');
  for (final usage in report.colors) {
    out.writeln('  ${usage.color.value}  عدد=${usage.count}');
    out.writeln('    محتوى=${usage.isInContent}  ثيم=${usage.themeLinked}');
    out.writeln('    أدوار: ${_sorted(usage.byRole.map(_roleKey))}');
    out.writeln('    أجزاء: ${_sorted(usage.byPart)}');
    out.writeln('    تصنيفات: ${_names(usage.partClasses)}');
    for (final sample in usage.samples) {
      out.writeln('    عيّنة: «$sample»');
    }
  }

  out.writeln('\n# الخطوط');
  for (final usage in report.fonts) {
    out.writeln('  ${usage.name}  عدد=${usage.count}');
    out.writeln('    ثيم=${usage.themeLinked}  محتوى=${usage.isInContent}');
    out.writeln('    فتحات: ${_sorted(usage.bySlot.map(_slotKey))}');
    out.writeln('    أجزاء: ${_sorted(usage.byPart)}');
    out.writeln('    تصنيفات: ${_names(usage.partClasses)}');
  }

  out.writeln('\n# العلامات');
  for (final usage in report.marks) {
    out.writeln('  ${usage.mark}  عدد=${usage.count}');
    out.writeln('    أجزاء: ${_sorted(usage.byPart)}');
    out.writeln('    تصنيفات: ${_names(usage.partClasses)}');
    for (final sample in usage.samples) {
      out.writeln('    عيّنة: «$sample»');
    }
  }

  return out.toString();
}

MapEntry<String, int> _roleKey(ColorRole role, int count) =>
    MapEntry(role.name, count);
MapEntry<String, int> _slotKey(FontSlot slot, int count) =>
    MapEntry(slot.name, count);

String _sorted(Map<String, int> values) {
  final keys = values.keys.toList()..sort();
  return [for (final key in keys) '$key=${values[key]}'].join('، ');
}

String _names(Set<PartClass> classes) =>
    ([for (final c in classes) c.name]..sort()).join('، ');

InspectionReport reportFor(Uint8List bytes) {
  final opened = DocumentPackage.open(bytes);
  if (opened case Failed(:final issues)) fail('فتح: ${issues.join("، ")}');
  final package = (opened as Ok<DocumentPackage>).value;
  final detected = formatFor(package);
  if (detected case Failed(:final issues)) fail('صيغة: ${issues.join("، ")}');
  final result = (detected as Ok<DocumentFormat>).value.inspect(package);
  if (result case Failed(:final issues)) fail('فحص: ${issues.join("، ")}');
  return (result as Ok<InspectionReport>).value;
}

void expectGolden(String name, String actual) {
  final file = File('test/golden/$name.txt');
  if (Platform.environment['E3KS_UPDATE_GOLDEN'] == '1' || !file.existsSync()) {
    file.writeAsStringSync(actual);
    if (!file.existsSync()) fail('تعذّر كتابة الذهبي: ${file.path}');
    return;
  }
  expect(actual, equals(file.readAsStringSync()), reason: 'خالف $name.txt');
}

void main() {
  final cases = <String, Uint8List Function()>{
    'docx_fixture': buildFixtureDocx,
    'docx_sectioned': buildSectionedDocx,
    'docx_marked': buildMarkedDocx,
    'pptx_fixture': buildFixturePptx,
    'pptx_marked': buildMarkedPptx,
  };

  cases.forEach((name, build) {
    test('تقرير الفحص الذهبي — $name', () {
      expectGolden(name, describeReport(reportFor(build())));
    });
  });
}
