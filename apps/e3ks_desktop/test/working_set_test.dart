/// نموذج مجموعة العمل: طبقتا خطّة، والصريح يسبق — `ADR 0005` §٢–§٤.
///
/// **يُختبر بلا بكسل واحد.** هذا أخطر جزء في الخطة وأقلّه ظهورًا: خللٌ فيه
/// يُخرج ملفًّا بخطّة غير التي رآها المستخدم، ولا شيء على الشاشة يقول ذلك.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/data/style_edits.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _demo = '../../docs/demo/brand-guidelines.docx';

/// `!` مضمون: القيم أدناه بصيغة `#RRGGBB` صحيحة.
HexColor hex(String value) => HexColor.tryParse(value)!;

final _a = hex('#111111');
final _b = hex('#222222');
final _c = hex('#333333');

void main() {
  group('حلّ الطبقتين', () {
    test('الخاصّ يفوز على العامّ', () {
      final general = StyleEdits()..colors[_a] = _b;
      final own = StyleEdits()..colors[_a] = _c;
      expect(resolvePlan(general, own).colors[_a], equals(_c));
    });

    test('العامّ يسري حيث لا رأي للملفّ', () {
      final general = StyleEdits()..colors[_a] = _b;
      expect(resolvePlan(general, StyleEdits()).colors[_a], equals(_b));
    });

    test('استثناءٌ صريح يُبطل القاعدة العامّة ولا يضع بديلًا', () {
      // `null` قولٌ لا غياب: «هذا الملفّ يُبقي هذا اللون».
      final general = StyleEdits()..colors[_a] = _b;
      final own = StyleEdits()..colors[_a] = null;
      expect(resolvePlan(general, own).colors, isNot(contains(_a)));
    });

    test('الملفّ المقفل لا تسري عليه العامّة', () {
      final general = StyleEdits()
        ..colors[_a] = _b
        ..latinFont = 'Inter';
      final own = StyleEdits()..colors[_c] = _b;
      final plan = resolvePlan(null, own); // `null` = مقفل
      expect(plan.colors, isNot(contains(_a)));
      expect(plan.colors[_c], equals(_b));
      expect(plan.fonts?.latin, isNull);
      expect(general.colors, isNotEmpty, reason: 'العامّة لا تُمَس');
    });

    test('الحماية والعلامات تتجمّع من الطبقتين', () {
      final mark = TextMark(MarkKind.highlight, 'yellow');
      final other = TextMark(MarkKind.highlight, 'green');
      final general = StyleEdits()
        ..preserveFonts.add('Courier')
        ..liftedMarks.add(mark);
      final own = StyleEdits()
        ..preserveFonts.add('Consolas')
        ..liftedMarks.add(other);
      final plan = resolvePlan(general, own);
      expect(plan.preserveFonts, containsAll(['Courier', 'Consolas']));
      expect(plan.removeMarks, containsAll([mark, other]));
    });

    test('خطّ الملفّ يسبق خطّ المجموعة', () {
      final general = StyleEdits()
        ..latinFont = 'Inter'
        ..arabicFont = 'Cairo';
      final own = StyleEdits()..latinFont = 'IBM Plex Sans';
      final plan = resolvePlan(general, own);
      expect(plan.fonts?.latin, equals('IBM Plex Sans'));
      expect(plan.fonts?.arabic, equals('Cairo'), reason: 'ما لا رأي فيه يعمّ');
    });
  });

  final ready = File(_demo).existsSync();

  group('على المخزَن', skip: ready ? null : 'لا يوجد مستند العرض', () {
    late WorkspaceStore store;

    setUp(() async {
      if (!ready) return;
      store = WorkspaceStore();
      final bytes = Uint8List.fromList(File(_demo).readAsBytesSync());
      await store.open('$_demo#1', 'أول.docx', bytes);
      await store.open('$_demo#2', 'ثانٍ.docx', bytes);
    });

    test('القاعدة العامّة تسري على كل الملفات', () {
      store.mapColor(_a, _b, EditScope.general);
      expect(store.planFor(0).colors[_a], equals(_b));
      expect(store.planFor(1).colors[_a], equals(_b));
    });

    test('التعديل الخاصّ لا يتسرّب إلى غيره', () {
      store.selectDocument(0);
      store.mapColor(_a, _b);
      expect(store.planFor(0).colors[_a], equals(_b));
      expect(store.planFor(1).colors, isNot(contains(_a)));
    });

    test('القفل يمنع العامّة ولا يمنع الخاصّة', () {
      store.mapColor(_a, _b, EditScope.general);
      store.selectDocument(1);
      store.mapColor(_c, _b);
      store.setLocked(1, true);

      expect(store.planFor(0).colors[_a], equals(_b));
      expect(store.planFor(1).colors, isNot(contains(_a)));
      expect(store.planFor(1).colors[_c], equals(_b));
    });

    test('رفعُ لونٍ تحكمه قاعدة عامّة استثناءٌ لا عودةٌ صامتة', () {
      store.mapColor(_a, _b, EditScope.general);
      store.selectDocument(0);
      store.mapColor(_a, null);

      expect(store.planFor(0).colors, isNot(contains(_a)));
      expect(store.isFileSpecific(_a), isTrue);
      expect(store.planFor(1).colors[_a], equals(_b), reason: 'غيره لا يتأثّر');

      store.clearFileColor(_a);
      expect(
        store.planFor(0).colors[_a],
        equals(_b),
        reason: 'يعود إلى العامّة',
      );
    });

    test('راجعته وملاحظته قرارُ المستخدم، ويبقيان عبر التنقّل', () {
      store.setReviewed(1, true);
      store.setNote(1, 'يحتاج مراجعة العنوان');
      store.selectDocument(0);
      expect(store.reviewed, isFalse);
      store.selectDocument(1);
      expect(store.reviewed, isTrue);
      expect(store.note, equals('يحتاج مراجعة العنوان'));
    });

    test('محو العامّة لا يمحو الخاصّة', () {
      store.mapColor(_a, _b, EditScope.general);
      store.selectDocument(0);
      store.mapColor(_c, _b);

      store.resetChanges(EditScope.general);
      expect(store.planFor(0).colors, isNot(contains(_a)));
      expect(store.planFor(0).colors[_c], equals(_b));
    });
  });
}
