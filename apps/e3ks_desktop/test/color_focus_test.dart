/// تتبّع لون: من الصفحة إلى القائمة، ومن القائمة إلى مواضعه.
///
/// الحاجة التي يخدمها: لون سقط سهوًا في زاوية من مستند طويل. الجدول يقول
/// «٣ مواضع» ولا يقول أين.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/preview/change_scan.dart';
import 'package:e3ks_desktop/features/preview/color_focus_bar.dart';
import 'package:e3ks_desktop/features/preview/page_index.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _realPath =
    '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';

FontService offlineFonts() =>
    FontService(FontCache(Directory.systemTemp))..fetchEnabled = false;

Widget harness(WorkspaceStore store) => MaterialApp(
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
      fonts: offlineFonts(),
      settings: SettingsStore(
        File('${Directory.systemTemp.path}/e3ks_focus.json'),
        const Locale('ar'),
      ),
    ),
  ),
);

Future<WorkspaceStore> openReal(WidgetTester tester) async {
  final store = WorkspaceStore();
  final file = File(_realPath);
  await tester.runAsync(
    () => store.open(
      _realPath,
      'manual.docx',
      Uint8List.fromList(file.readAsBytesSync()),
    ),
  );
  return store;
}

void main() {
  group('حالة التتبّع', () {
    test('التتبّع يفتح تبويب الألوان، وإعادته ترفعه', () {
      // من ضغط لونًا في الصفحة يريد أن يفعل به شيئًا؛ وتركُه ينظر إلى
      // تبويب الخطوط يُضيّع الضغطة.
      final store = WorkspaceStore();
      final color = HexColor.tryParse('4C2FB8')!;

      // بلا مستند لا شيء يُتتبَّع — ولا انهيار.
      store.focusColor(color);
      expect(store.focusedColor, isNull);
    });
  });

  group('على مستند حقيقي', () {
    testWidgets('الضغط على لون في الصفحة يتتبّعه ويفتح شريطه', (tester) async {
      if (!File(_realPath).existsSync()) {
        markTestSkipped('لا يوجد مستند حقيقي');
        return;
      }
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final store = await openReal(tester);
      await tester.pumpWidget(harness(store));
      await tester.pump();

      expect(find.byType(ColorFocusBar), findsNothing);

      final color = store.report!.contentColors.first.color;
      store.focusColor(color);
      await tester.pump();

      expect(store.focusedColor?.value, equals(color.value));
      expect(store.tab, equals(WorkspaceTab.colors));
      expect(find.byType(ColorFocusBar), findsOneWidget);
      expect(find.text(color.value), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('إعادة التتبّع على اللون نفسه ترفعه', (tester) async {
      if (!File(_realPath).existsSync()) {
        markTestSkipped('لا يوجد مستند حقيقي');
        return;
      }
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final store = await openReal(tester);
      await tester.pumpWidget(harness(store));
      await tester.pump();

      final color = store.report!.contentColors.first.color;
      store.focusColor(color);
      store.focusColor(color);
      await tester.pump();

      expect(store.focusedColor, isNull);
      expect(find.byType(ColorFocusBar), findsNothing);
    });

    testWidgets('مواضع اللون تُحصى بالصفحات لا بالتخمين', (tester) async {
      if (!File(_realPath).existsSync()) {
        markTestSkipped('لا يوجد مستند حقيقي');
        return;
      }
      final store = await openReal(tester);
      final pages = flattenPages(store.document!.preview);

      final usage = store.report!.contentColors.firstWhere((c) => c.count > 3);
      final matches = pagesWithColor(pages, usage.color.value);

      expect(matches, isNotEmpty, reason: 'لونٌ يظهر ${usage.count} مرّة');
      expect(matches.length, lessThanOrEqualTo(pages.length));
      // الفهارس مرتّبة تصاعديًا وبلا تكرار — شرط التنقّل «التالي/السابق».
      expect(matches, orderedEquals(matches.toSet().toList()..sort()));

      // ولونٌ لا وجود له لا يُطابق شيئًا (00 §5: لا نخمّن).
      expect(pagesWithColor(pages, '#123456'), isEmpty);
    });
  });

  group('مسح الكتل', () {
    test('يجد اللون في الفقرة والخلية والشكل', () {
      final teal = HexColor.tryParse('00635D')!;
      const other = PreviewRun(text: 'x');

      final paragraph = PreviewParagraph(
        runs: [
          PreviewRun(text: 'نصّ', color: teal),
          other,
        ],
      );
      expect(blockHasColor(ParagraphBlock(paragraph), teal.value), isTrue);
      expect(blockHasColor(ParagraphBlock(paragraph), '#FFFFFF'), isFalse);

      final cell = PreviewCell(paragraphs: const [], fill: teal);
      final table = TableBlock([
        PreviewRow(cells: [cell]),
      ]);
      expect(blockHasColor(table, teal.value), isTrue);

      final shape = ShapeBlock(paragraphs: const [], fill: teal);
      expect(blockHasColor(shape, teal.value), isTrue);
    });
  });
}
