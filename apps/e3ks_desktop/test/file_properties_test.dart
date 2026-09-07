/// خصائص الملفّ: ما يُقرَّر به لا ما يزيّن.
///
/// **الحارس على المعنى لا على الوجود**: شاشةٌ تعرض أرقامًا صحيحة الشكل
/// خاطئة المعنى تمرّ على اختبارٍ يفحص أن النصّ ظهر. فالمقاس هنا أن
/// «ألوان لا تمسّها الخطة» تنقص واحدًا كلّما بُدِّل لون.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:e3ks_desktop/shared/widgets/swatch.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _demo = '../../docs/demo/brand-guidelines.docx';

/// `!` مضمون: القيمة أدناه بصيغة `#RRGGBB` صحيحة.
final _target = HexColor.tryParse('#00635D')!;

void main() {
  final ready = File(_demo).existsSync();
  final bytes = ready
      ? Uint8List.fromList(File(_demo).readAsBytesSync())
      : Uint8List(0);

  Future<void> pump(WidgetTester tester, WorkspaceStore store) =>
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
                File('${Directory.systemTemp.path}/e3ks_props.json'),
                const Locale('ar'),
              ),
            ),
          ),
        ),
      );

  Finder inDialog(Finder of) =>
      find.descendant(of: find.byType(Dialog), matching: of);

  testWidgets('الخصائص تقول ما يُقرَّر به', skip: !ready, (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = WorkspaceStore();
    await tester.runAsync(
      () => store.open('/عمل/دليل.docx', 'دليل.docx', bytes),
    );
    await tester.runAsync(
      () => store.open('/عمل/ثانٍ.docx', 'ثانٍ.docx', bytes),
    );
    await pump(tester, store);
    await tester.pumpAndSettle();

    final report = store.report;
    // فُتح المستند وفُحص، فالتقرير حاضر ولا يخلو من لون.
    final content = report!.contentColors;
    store.mapColor(content.first.color, _target, EditScope.file);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey(store.activeIndex)),
        matching: find.byTooltip('خيارات الملفّ'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('خصائص').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(inDialog(find.text('ثانٍ.docx')), findsOneWidget, reason: 'بلا اسم');
    expect(inDialog(find.text('Word')), findsOneWidget, reason: 'بلا صيغة');
    expect(inDialog(find.text('/عمل/ثانٍ.docx')), findsOneWidget);
    // العدد يُعرَض ومعه «+» ما دامت بقيّة الصفحات في الطريق، فالحارس على
    // وجود السطر وعلى أن العدد حقيقي لا صفرًا.
    expect(inDialog(find.text('الصفحات')), findsOneWidget, reason: 'بلا صفحات');
    expect(store.document!.preview.pageCount, greaterThan(0));

    // **المعنى**: لونٌ واحد بُدِّل، فالباقي بلا قاعدة — والعيّنات بعددها.
    expect(inDialog(find.text('ألوان لا تمسّها الخطة')), findsOneWidget);
    final leftovers = inDialog(find.byType(Swatch));
    expect(
      leftovers.evaluate().length,
      equals(content.length - 1),
      reason: 'المبدَّل ما زال معدودًا في المتروك',
    );
  });

  testWidgets('بلا خطّة: لا شيء يُبدَّل، والكلّ متروك', skip: !ready, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = WorkspaceStore();
    await tester.runAsync(
      () => store.open('/عمل/دليل.docx', 'دليل.docx', bytes),
    );
    await pump(tester, store);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('خيارات الملفّ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خصائص').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      inDialog(find.text('لا شيء')),
      findsOneWidget,
      reason: 'ادّعى تبديلًا',
    );
    final report = store.report;
    // فُتح وفُحص قبل الفتح، فالتقرير حاضر.
    expect(
      inDialog(find.byType(Swatch)).evaluate().length,
      equals(report!.contentColors.length.clamp(0, 12)),
    );
  });
}
