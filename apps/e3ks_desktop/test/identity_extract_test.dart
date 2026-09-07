/// استخراج الهوية من ملفّ: ترتيبٌ مقيس، وتسميةٌ مرجَّحة، وصمتٌ عمّا لا نعرف.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/data/document_loader.dart';
import 'package:e3ks_desktop/data/identity.dart';
import 'package:e3ks_desktop/data/identity_extract.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _realPath =
    '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';

const IdentityLabels _labels = (
  primary: 'الأساسي',
  text: 'لون النصّ',
  background: 'الخلفية',
  accent: 'مُكمّل',
);

void main() {
  late final InspectionReport report;
  setUpAll(() async {
    final file = File(_realPath);
    if (!file.existsSync()) return;
    // **الفحص يُطلَب صراحةً**: فتحُ المستند صار يعرض صفحته ولا يفحصه، وهذا
    // الاختبار يخصّ الفحص وحده.
    report = (await loadInspection(
      Uint8List.fromList(file.readAsBytesSync()),
    ))!;
  });

  test('الأدوار تُحفَظ حقولًا لا أسماءً', () {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    // الاسم مترجَم فلا يُقارَن به شيء؛ الدور يُقارَن، فيجب أن يكون حقلًا.
    final identity = extractIdentity(report, name: 'مرجع', labels: _labels);
    expect(identity.colors.first.role, equals(IdentityRole.primary));
    expect(
      identity.colors.map((c) => c.role),
      isNot(everyElement(equals(IdentityRole.other))),
    );
  });

  test('القاعدة الصريحة تسبق الترجيح بالإضاءة', () async {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    final store = WorkspaceStore();
    await store.open(
      _realPath,
      'manual.docx',
      Uint8List.fromList(File(_realPath).readAsBytesSync()),
    );

    final source = store.report!.contentColors.first.color;
    final target = HexColor.tryParse('#0F3D3E')!;

    // هوية فيها لون بعيد عن المصدر في الإضاءة، وقاعدة صريحة تخالف الترجيح.
    store.applyIdentity(
      Identity(
        name: 'صريحة',
        colors: [NamedColor(name: 'فاتح', hex: HexColor.tryParse('#F7F7F7')!)],
        map: {source: target},
      ),
    );

    expect(store.colorMap[source], equals(target));
  });

  test('الألوان مرتّبة بالأكثر استعمالًا ومحدودة العدد', () {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    final identity = extractIdentity(report, name: 'مرجع', labels: _labels);

    expect(identity.colors, isNotEmpty);
    expect(
      identity.colors.length,
      lessThanOrEqualTo(8),
      reason: 'هوية يقرؤها إنسان لا جدولُ كل لون في الملف',
    );

    // الترتيب هو ترتيب التقرير نفسه: كثرة الاستعمال، وهي حقيقة مقيسة.
    final expected = report.contentColors
        .where((c) => c.count >= 2)
        .take(8)
        .map((c) => c.color.value)
        .toList();
    expect(identity.colors.map((c) => c.hex.value), orderedEquals(expected));
  });

  test('التسميات مرجَّحة لا مخترَعة', () {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    final identity = extractIdentity(report, name: 'مرجع', labels: _labels);
    final names = identity.colors.map((c) => c.name).toList();

    expect(names.first, equals('الأساسي'), reason: 'الأكثر استعمالًا');
    // الباقي إمّا دور مرجَّح وإمّا مُكمّل مرقَّم — لا اسم من فراغ.
    for (final name in names.skip(1)) {
      expect(
        name == 'لون النصّ' || name == 'الخلفية' || name.startsWith('مُكمّل '),
        isTrue,
        reason: 'اسم غير مبرَّر: $name',
      );
    }
    expect(names.toSet().length, equals(names.length), reason: 'أسماء مكرّرة');
  });

  test('الخطوط من المحتوى لا من الموروث', () {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    final identity = extractIdentity(report, name: 'مرجع', labels: _labels);

    // من الموروث تأتي خطوط لا يراها القارئ أصلًا.
    final contentNames = report.contentFonts.map((f) => f.name);
    expect(contentNames, contains(identity.latinFont));

    // والخطوط أحادية العرض تُحمَل في قائمة الحماية لا في قائمة التبديل.
    expect(identity.preserveFonts, isNotEmpty);
    expect(identity.preserveFonts, isNot(contains(identity.latinFont)));
  });

  test('الهوية المستخرَجة تُكتب وتُقرأ بلا فقد', () {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    final identity = extractIdentity(report, name: 'مرجع', labels: _labels);
    // الحفظ JSON يقرؤه الإنسان؛ دورةٌ كاملة تثبت أنه لا يُضيّع شيئًا.
    final decoded = Identity.fromJson(jsonDecode(identity.encode()))!;

    expect(decoded.name, equals(identity.name));
    expect(
      decoded.colors.map((c) => '${c.name}|${c.hex.value}'),
      orderedEquals(identity.colors.map((c) => '${c.name}|${c.hex.value}')),
    );
    expect(decoded.latinFont, equals(identity.latinFont));
    expect(decoded.arabicFont, equals(identity.arabicFont));
  });
}
