/// استخراج الهوية من ملفّ: ترتيبٌ مقيس، وتسميةٌ مرجَّحة، وصمتٌ عمّا لا نعرف.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/data/document_loader.dart';
import 'package:e3ks_desktop/data/identity.dart';
import 'package:e3ks_desktop/data/identity_extract.dart';
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
  late LoadedDocument document;

  setUpAll(() async {
    final file = File(_realPath);
    if (!file.existsSync()) return;
    final result = await loadDocument(
      _realPath,
      'manual.docx',
      Uint8List.fromList(file.readAsBytesSync()),
    );
    document = result.document!;
  });

  test('الألوان مرتّبة بالأكثر استعمالًا ومحدودة العدد', () {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    final identity = extractIdentity(document, name: 'مرجع', labels: _labels);

    expect(identity.colors, isNotEmpty);
    expect(
      identity.colors.length,
      lessThanOrEqualTo(8),
      reason: 'هوية يقرؤها إنسان لا جدولُ كل لون في الملف',
    );

    // الترتيب هو ترتيب التقرير نفسه: كثرة الاستعمال، وهي حقيقة مقيسة.
    final expected = document.report.contentColors
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
    final identity = extractIdentity(document, name: 'مرجع', labels: _labels);
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
    final identity = extractIdentity(document, name: 'مرجع', labels: _labels);

    // من الموروث تأتي خطوط لا يراها القارئ أصلًا.
    final contentNames = document.report.contentFonts.map((f) => f.name);
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
    final identity = extractIdentity(document, name: 'مرجع', labels: _labels);
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
