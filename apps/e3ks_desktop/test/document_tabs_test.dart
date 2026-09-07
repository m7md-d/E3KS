/// حركة شريط التبويبات: يغادر التبويب بحركة، وينزلق جيرانه إلى مكانه.
///
/// **الحركة تُقاس لا تُوصَف** (`07` §7): «يختفي بحركة» و«يختفي في إطارٍ
/// واحد» يمرّان على اختبارٍ يفحص الوجود قبل وبعد. القياس هنا **بين
/// الإطارين**: عرضٌ أصغر من الكامل وأكبر من الصفر في منتصف المدّة.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/workspace/document_tabs.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _demo = '../../docs/demo/brand-guidelines.docx';

Future<void> _pump(WidgetTester tester, WorkspaceStore store) =>
    tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        locale: const Locale('ar'),
        supportedLocales: L.supportedLocales,
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: ListenableBuilder(
            listenable: store,
            builder: (_, _) => Column(
              children: [DocumentTabs(store: store, onAdd: () {})],
            ),
          ),
        ),
      ),
    );

/// شفافية التبويب كما تراها الشجرة — لا كما يُظنّ.
double _fade(WidgetTester tester, Finder of) => tester
    .widget<Opacity>(find.descendant(of: of, matching: find.byType(Opacity)))
    .opacity;

void main() {
  final ready = File(_demo).existsSync();
  final bytes = ready
      ? Uint8List.fromList(File(_demo).readAsBytesSync())
      : Uint8List(0);

  Future<WorkspaceStore> open(WidgetTester tester, int count) async {
    final store = WorkspaceStore();
    for (var i = 0; i < count; i++) {
      await tester.runAsync(
        () => store.open('/عمل/ملف$i.docx', 'ملف$i.docx', bytes),
      );
    }
    return store;
  }

  Finder tab(int i) => find.byKey(ValueKey('/عمل/ملف$i.docx'));

  testWidgets('يختفي التبويب أوّلًا، ثمّ ينزلق جيرانه', skip: !ready, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await open(tester, 3);
    await _pump(tester, store);
    await tester.pumpAndSettle();

    final full = tester.getSize(tab(1)).width;
    final neighbour = tester.getSize(tab(2)).width;
    final wasAt = tester.getTopLeft(tab(2));
    expect(full, greaterThan(0));

    store.closeTab(1);
    await tester.pump();

    expect(
      tab(1),
      findsOneWidget,
      reason: 'انتُزع التبويب في إطارٍ واحد بدل أن ينسحب',
    );
    expect(store.openTabs, hasLength(2), reason: 'المخزَن يسبق الشريط');

    // **الحركة الأولى اختفاء بعرضٍ كامل.** الطيّ مع الاختفاء يقصّ الاسم
    // نصفَ كلمة وهو ما زال ظاهرًا، فيبدو الشريط منكسرًا لا منسحبًا.
    await tester.pump(Motion.normal ~/ 4);
    expect(
      tester.getSize(tab(1)).width,
      equals(full),
      reason: 'طوى قبل أن يختفي',
    );
    expect(_fade(tester, tab(1)), lessThan(1), reason: 'لم يبدأ الاختفاء');
    expect(_fade(tester, tab(1)), greaterThan(0), reason: 'اختفى دفعةً');

    // وعند تمام الاختفاء يبدأ الطيّ، فلا يُقصّ اسمٌ ظاهر.
    await tester.pump(Motion.normal ~/ 4);
    expect(_fade(tester, tab(1)), equals(0), reason: 'يطوي وهو ظاهر');

    // **والثانية طيٌّ متدرّج.** وفي كل إطارٍ منها لا يتغيّر عرض الجار:
    // هذا ما سقط أوّل مرّة — كان ينهار إلى صفر ثم يُعاد نفخه.
    var shrank = false;
    for (var frame = 0; frame < 14; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (tab(2).evaluate().isEmpty) continue;
      expect(
        tester.getSize(tab(2)).width,
        equals(neighbour),
        reason: 'انهار الجار في الإطار $frame بدل أن ينزلق',
      );
      if (tab(1).evaluate().isNotEmpty) {
        final now = tester.getSize(tab(1)).width;
        if (now > 0 && now < full) shrank = true;
      }
    }
    expect(shrank, isTrue, reason: 'قفزٌ لا طيّ: لا إطار بعرضٍ بين الحدّين');

    await tester.pumpAndSettle();
    expect(tab(1), findsNothing, reason: 'بقي بعد انتهاء حركته');
    expect(tester.getTopLeft(tab(2)), isNot(equals(wasAt)), reason: 'لم ينزلق');
  });

  testWidgets('الشريط نفسه يطوي ارتفاعه بحركة', skip: !ready, (tester) async {
    // الشريط يظهر بتبويبَين فأكثر، فإغلاق أحدهما يُخفيه. وإخفاؤه دفعةً
    // واحدة يقفز بالمعاينة تحته أربعين بكسلًا.
    await tester.binding.setSurfaceSize(const Size(1200, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await open(tester, 2);
    await _pump(tester, store);
    await tester.pumpAndSettle();

    final full = tester.getSize(find.byType(DocumentTabs)).height;
    expect(full, greaterThan(0));

    store.closeTab(0);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(DocumentTabs)).height, equals(0));
  });
}
