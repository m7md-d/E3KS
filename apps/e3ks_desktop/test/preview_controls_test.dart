/// أدوات المعاينة: الترقيم المباشر، ومفتاح العلامات، ومنتقي اللون.
library;

import 'dart:io';

import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/features/preview/color_pick_layer.dart';
import 'package:e3ks_desktop/features/preview/document_paper.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _realPath =
    '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';

FontService offlineFonts() =>
    FontService(FontCache(Directory.systemTemp))..fetchEnabled = false;

Widget harness(WorkspaceStore store, Locale locale) => MaterialApp(
  theme: buildTheme(),
  locale: locale,
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
      fonts: offlineFonts(),
      settings: SettingsStore(
        File('${Directory.systemTemp.path}/e3ks_ctl.json'),
        locale,
      ),
    ),
  ),
);

Future<WorkspaceStore> openReal(WidgetTester tester) async {
  final store = WorkspaceStore();
  await tester.runAsync(
    () => store.open(
      _realPath,
      'manual.docx',
      Uint8List.fromList(File(_realPath).readAsBytesSync()),
    ),
  );
  return store;
}

void main() {
  testWidgets('حقل الصفحة يقبل الأرقام الهندية ويقفز', (tester) async {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    await tester.binding.setSurfaceSize(const Size(1700, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await openReal(tester);
    await tester.pumpWidget(harness(store, const Locale('ar')));
    await tester.pump();

    final field = find.byType(TextField);
    expect(field, findsOneWidget, reason: 'حقل الصفحة موجود');

    // ما تعرضه الواجهة هندي، فما يكتبه المستخدم هندي — ويجب أن يُقبَل.
    await tester.enterText(field, '١٢');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // والغربي يُقبل أيضًا: لا نُلزم المستخدم بلوحة مفاتيح بعينها.
    await tester.enterText(field, '5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // ومدخَل ليس عددًا لا يقفز ولا ينهار.
    await tester.enterText(field, 'صفحة');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('علامات التغيير مطفأة افتراضًا ويُشغّلها مفتاحها', (
    tester,
  ) async {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    await tester.binding.setSurfaceSize(const Size(1700, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await openReal(tester);
    await tester.pumpWidget(harness(store, const Locale('ar')));
    await tester.pump();

    // إطارٌ حول كل فقرة تغيّرت يصير بلا معنى حين يتغيّر لونٌ شائع.
    final busy = store.report!.contentColors.first;
    store.mapColor(busy.color, store.report!.contentColors.last.color);
    await tester.pump();

    final toggle = find.byIcon(LucideIcons.squareDashedMousePointer);
    expect(toggle, findsOneWidget, reason: 'مفتاح العلامات في الشريط');

    bool marked() => tester
        .widgetList<DocumentPaper>(find.byType(DocumentPaper))
        .any((paper) => paper.highlightChanged);

    // مطفأ ⇒ لا إطار حول كتلة. كان المفتاح يُخفي إطار الصفحة وحده ويترك كل
    // فقرة تغيّرت محاطة — وهو الضجيج نفسه الذي وُضع المفتاح لإسكاته.
    expect(marked(), isFalse, reason: 'العلامات مطفأة افتراضًا');

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(marked(), isTrue, reason: 'المفتاح يُشغّل إطارات الكتل');
    expect(tester.takeException(), isNull);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(marked(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('منتقي اللون يفتح طبقة الالتقاط ويُغلقها بـEsc', (tester) async {
    if (!File(_realPath).existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }
    await tester.binding.setSurfaceSize(const Size(1700, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await openReal(tester);
    await tester.pumpWidget(harness(store, const Locale('ar')));
    await tester.pump();

    expect(find.byType(ColorPickLayer), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.pipette));
    await tester.pump();
    expect(find.byType(ColorPickLayer), findsOneWidget, reason: 'وضع الالتقاط');

    // مهرب واضح: من دخل وضعًا يلتقط كل ضغطة يجب أن يستطيع الخروج منه.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(ColorPickLayer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('اللون البديل يردّ إلى مصدره', () async {
    if (!File(_realPath).existsSync()) return;
    final store = WorkspaceStore();
    await store.open(
      _realPath,
      'manual.docx',
      Uint8List.fromList(File(_realPath).readAsBytesSync()),
    );

    final source = store.report!.contentColors.first.color;
    final target = store.report!.contentColors.last.color;
    store.mapColor(source, target);

    // في عرض «بعد» تحمل الصفحة لون البديل، والقائمة مفهرسة بلون المصدر.
    // الضغط على البديل كان لا يفعل شيئًا؛ الآن يجد صفّه.
    store.focusColor(target);
    expect(store.focusedColor?.value, equals(source.value));
  });
}
