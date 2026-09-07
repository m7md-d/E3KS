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
    // **الخلل الذي وُلد منه الاختبار:** زرّ «أضف مجلدًا» كان في رأس شجرة
    // الملفات وحدها، والشجرة لا تظهر إلا بملفَّين — فلا سبيل إلى فتح مجلد
    // إلا بعد فتح مجلد. بابٌ داخل الغرفة التي يفتحها.
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(tester, WorkspaceStore());
    await tester.pumpAndSettle();

    // التلميح يبنيه `IconButton` داخله، فيُصعَد منه إلى الزرّ.
    final button = find.ancestor(
      of: find.byTooltip('افتح مجلدًا'),
      matching: find.byType(IconButton),
    );
    expect(button, findsOneWidget, reason: 'لا باب إلى المجلد بلا ملف مفتوح');
    expect(tester.widget<IconButton>(button).onPressed, isNotNull);
  });

  testWidgets('الشجرة تظهر بملفّين وتبقى عند أضيق نافذة', skip: !ready, (
    tester,
  ) async {
    final store = WorkspaceStore();
    final bytes = Uint8List.fromList(File(_demo).readAsBytesSync());

    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() => store.open('/عمل/أول.docx', 'أول.docx', bytes));
    await _pump(tester, store);
    await tester.pumpAndSettle();
    expect(
      find.byType(FileTreePanel),
      findsNothing,
      reason: 'ملفٌّ واحد لا يحتاج شجرة',
    );

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

    // أضيق نافذة مسموحة: المساحة الفائضة للمعاينة، فتنسحب الشجرة.
    await tester.binding.setSurfaceSize(const Size(1180, 720));
    await tester.pumpAndSettle();
    expect(find.byType(FileTreePanel), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
}
