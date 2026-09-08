/// شجرة الملفات على الشاشة: تظهر حين تصير المجموعة مجموعة، وتنسحب عند الضيق.
///
/// **الاختبار يكشف ما لا يكشفه المحلّل** (`03`): تجاوز التخطيط لا يراه
/// `flutter analyze`، ويُقاس عند **أضيق نافذة مسموحة** لأنها أكثر ما ينكسر.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/workspace/file_tree_panel.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
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
        home: ListenableBuilder(
          listenable: store,
          builder: (_, _) => WorkspaceScreen(
            store: store,
            identities: IdentityStore(Directory.systemTemp),
            fonts: FontService(FontCache(Directory.systemTemp))
              ..fetchEnabled = false,
            settings: SettingsStore(
              File('${Directory.systemTemp.path}/e3ks_tree.json'),
              const Locale('ar'),
            ),
          ),
        ),
      ),
    );

void main() {
  final ready = File(_demo).existsSync();

  testWidgets('باب المجلد مفتوح قبل أي ملف', (tester) async {
    // **الخلل الذي وُلد منه الاختبار:** زرّ «إضافة مجلد» كان في رأس شجرة
    // الملفات وحدها، والشجرة لا تظهر إلا بملفَّين — فلا سبيل إلى فتح مجلد
    // إلا بعد فتح مجلد. بابٌ داخل الغرفة التي يفتحها. والشجرة اليوم ظاهرة
    // دائمًا، فالحارس على زرّها هو.
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(tester, WorkspaceStore());
    await tester.pumpAndSettle();

    // التلميح فوق الزرّ، فيُنزَل منه إلى ما يستقبل الضغطة.
    final button = find.descendant(
      of: find.byTooltip('إضافة مجلد'),
      matching: find.byType(InkWell),
    );
    expect(button, findsOneWidget, reason: 'لا باب إلى المجلد بلا ملف مفتوح');
    expect(tester.widget<InkWell>(button).onTap, isNotNull);
  });

  testWidgets('زرّ الفتح يحمل البابين: ملفات أو مجلد', (tester) async {
    // **الحصر بالملفات كان قيدًا من الأداة.** الزرّ الكبير هو أوّل ما يلمسه
    // القادم، وكان يفتح حوار الملفات وحده — والمجلد خلف أيقونةٍ منفردة في
    // الشريط. الأيقونة رُفعت، والبابان صارا في الزرّ نفسه واسمه كما هو.
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(tester, WorkspaceStore());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'اختر ملف…'));
    await tester.pumpAndSettle();

    expect(find.text('إضافة ملفات'), findsOneWidget, reason: 'باب الملفات');
    expect(find.text('إضافة مجلد'), findsOneWidget, reason: 'باب المجلد');
  });

  testWidgets(
    'الشجرة ظاهرة دائمًا، وتُظهر البنية، وتبقى عند أضيق نافذة',
    skip: !ready,
    (tester) async {
      final store = WorkspaceStore();
      final bytes = Uint8List.fromList(File(_demo).readAsBytesSync());

      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // **الشجرة ظاهرة قبل أي ملف.** زرّاها هما الطريق إلى فتح الملفات،
      // فإخفاؤها حتى تُفتح ملفاتٌ يخفي معها بابَها — وهو الخلل نفسه الذي
      // وقع حين سكن زرّ «أضف مجلدًا» داخل شجرةٍ لا تظهر إلا بملفَّين.
      await _pump(tester, store);
      await tester.pumpAndSettle();
      expect(find.byType(FileTreePanel), findsOneWidget);
      expect(find.text('لا ملفات بعد. أضف ملفات أو مجلدًا.'), findsOneWidget);

      await tester.runAsync(
        () => store.open('/عمل/أول.docx', 'أول.docx', bytes),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(
        () => store.open('/عمل/فرع/ثانٍ.docx', 'ثانٍ.docx', bytes),
      );
      store.addDirectory('/عمل');
      await tester.pumpAndSettle();

      expect(find.byType(FileTreePanel), findsOneWidget);
      expect(find.text('عمل'), findsOneWidget, reason: 'الجذر باسمه');
      expect(find.text('فرع'), findsOneWidget, reason: 'البنية تحته');
      expect(find.text('أول.docx'), findsWidgets);
      expect(tester.takeException(), isNull);

      // **أضيق نافذة مسموحة، والشجرة باقية.** موضعها تحت لوحة التحكّم لا في
      // عمودٍ خامس، فلا تزاحم المعاينة أصلًا.
      await tester.binding.setSurfaceSize(const Size(1180, 720));
      await tester.pumpAndSettle();
      expect(find.byType(FileTreePanel), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'تجاوز عند أضيق نافذة');
    },
  );

  testWidgets('الضغط على ملفٍّ في الشجرة ينتقل إليه', skip: !ready, (
    tester,
  ) async {
    final store = WorkspaceStore();
    final bytes = Uint8List.fromList(File(_demo).readAsBytesSync());
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() => store.open('/عمل/أول.docx', 'أول.docx', bytes));
    await tester.runAsync(
      () => store.open('/عمل/ثانٍ.docx', 'ثانٍ.docx', bytes),
    );
    store.addDirectory('/عمل');
    await _pump(tester, store);
    await tester.pumpAndSettle();

    expect(store.activeIndex, equals(1));
    await tester.tap(find.text('أول.docx').last);
    await tester.pumpAndSettle();
    expect(store.activeIndex, equals(0));
  });

  testWidgets('إغلاق تبويبٍ لا يُخرج ملفَّه من الشجرة', skip: !ready, (
    tester,
  ) async {
    // **الشريط غير الشجرة.** كما في محرّرات الأكواد: إغلاق تبويبٍ إخفاءٌ من
    // النظر لا إخراجٌ من العمل. وكان الاثنان قائمةً واحدة عندنا.
    final store = WorkspaceStore();
    final bytes = Uint8List.fromList(File(_demo).readAsBytesSync());
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() => store.open('/عمل/أول.docx', 'أول.docx', bytes));
    await tester.runAsync(
      () => store.open('/عمل/ثانٍ.docx', 'ثانٍ.docx', bytes),
    );
    store.addDirectory('/عمل');
    await _pump(tester, store);
    await tester.pumpAndSettle();

    expect(store.openTabs, hasLength(2));
    store.closeTab(1);
    await tester.pumpAndSettle();

    expect(store.openTabs, hasLength(1), reason: 'لم يُغلَق التبويب');
    expect(store.files, hasLength(2), reason: 'خرج الملفّ من المجموعة');
    expect(find.text('ثانٍ.docx'), findsOneWidget, reason: 'اختفى من الشجرة');

    // والإخراج التامّ فعلٌ آخر معلَن (`ADR 0005` §١).
    store.removeFile(1);
    await tester.pumpAndSettle();
    expect(store.files, hasLength(1));
    expect(find.text('ثانٍ.docx'), findsNothing);
  });
}
