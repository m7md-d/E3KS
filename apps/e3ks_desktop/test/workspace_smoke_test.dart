/// اختبار دخان للواجهة: يحمّل مستندًا حقيقيًا ويرسم كل اللوحات.
///
/// `flutter analyze` لا يكشف تجاوز التخطيط (overflow) ولا استثناءات الرسم؛
/// هذا الاختبار يكشفها لأنه يبني الشجرة فعلًا.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _realPath =
    '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';

/// خدمة خطوط بلا شبكة: الاختبارات لا تتصل بالإنترنت أبدًا.
FontService offlineFonts() =>
    FontService(FontCache(Directory.systemTemp))..fetchEnabled = false;

SettingsStore fakeSettings([String code = 'ar']) => SettingsStore(
  File('${Directory.systemTemp.path}/e3ks_test_settings.json'),
  Locale(code),
);

/// الاتجاه يأتي من اللغة، لا يُفرَض — كما في التطبيق الحقيقي.
Widget wrap(Widget child, {String locale = 'ar'}) => MaterialApp(
  theme: buildTheme(),
  locale: Locale(locale),
  supportedLocales: L.supportedLocales,
  localizationsDelegates: const [
    L.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  testWidgets('الواجهة الكاملة تظهر قبل فتح أي ملف', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = WorkspaceStore();
    final identities = IdentityStore(Directory.systemTemp);
    await tester.pumpWidget(
      wrap(
        WorkspaceScreen(
          store: store,
          identities: identities,
          settings: fakeSettings(),
          fonts: offlineFonts(),
        ),
      ),
    );
    // النصوص من ملف الترجمة لا منسوخةً هنا: نصٌّ منسوخ يُسقط الاختبار كلّما
    // أُعيدت صياغة الواجهة، فيبدو خللًا وهو تحرير.
    final t = await L.delegate.load(const Locale('ar'));

    // لا شاشة فتح منفصلة: الشريط الجانبي واللوحات ظاهرة، والإسقاط في المعاينة.
    expect(find.text(t.dropHere), findsOneWidget);
    expect(find.text(t.tabColors), findsWidgets);
    expect(find.text(t.tabFonts), findsWidgets);
    expect(find.text(t.documentFacts), findsOneWidget);
    expect(find.text(t.emptyColors), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('مساحة العمل ترسم مستندًا حقيقيًا بكل لوحاتها', (tester) async {
    final file = File(_realPath);
    if (!file.existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي في $_realPath');
      return;
    }

    // مقاس نافذة واقعي — التطبيق سطح مكتب، والتخطيط مصمَّم لمساحة.
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = WorkspaceStore();
    final identities = IdentityStore(Directory.systemTemp);

    // `testWidgets` يعمل بزمن مُصطنع، و`Isolate.run` داخل المحرّك يحتاج زمنًا
    // حقيقيًا كي يكتمل — لذلك عبر `runAsync`.
    await tester.runAsync(
      () => store.open(
        _realPath,
        'manual.docx',
        Uint8List.fromList(file.readAsBytesSync()),
      ),
    );
    expect(store.hasDocument, isTrue, reason: 'فشل تحميل المستند');
    expect(store.report!.contentColors, isNotEmpty);

    await tester.pumpWidget(
      wrap(
        ListenableBuilder(
          listenable: store,
          builder: (_, _) => WorkspaceScreen(
            store: store,
            identities: identities,
            settings: fakeSettings(),
            fonts: offlineFonts(),
          ),
        ),
      ),
    );
    await tester.pump();

    // لوحة الألوان تعرض الهوية ولا تُغرق المستخدم بالموروث.
    final t = await L.delegate.load(const Locale('ar'));
    expect(find.text(t.identityColors), findsOneWidget);
    expect(find.text('#4C2FB8'), findsOneWidget);

    // تبديل لون يُحدِّث العدّاد والمعاينة.
    final purple = store.report!.contentColors.firstWhere(
      (c) => c.color.value == '#4C2FB8',
    );
    final teal = store.report!.contentColors.first.color;
    store.mapColor(purple.color, teal);
    await tester.pump();
    expect(store.changeCount, equals(1));
    expect(store.previewAfter, isNotNull);

    // أدوات المراجعة في المعاينة: مبدّل بزرَّين، وتكبير، وترقيم، وتنقّل.
    expect(find.text(t.before), findsOneWidget);
    expect(find.text(t.after), findsOneWidget);
    // نصّ المستند نفسه فيه «100%» — نتحقّق من أزرار التكبير لا من النسبة.
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    expect(find.byIcon(LucideIcons.minus), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsWidgets);
    expect(find.byIcon(LucideIcons.listOrdered), findsOneWidget);

    // المعاينة تعرض ترقيم الفقرات كي يُحيل المستخدم إليها وهو يراجع.
    expect(find.text('1'), findsWidgets);

    // بقيّة اللوحات ترسم أيضًا.
    for (final tab in WorkspaceTab.values) {
      store.selectTab(tab);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'استثناء في ${tab.name}');
    }

    // التكيّف عبر كل العروض من الحدّ الأدنى (المفروض في MainFlutterWindow)
    // إلى شاشة كبيرة. أكثر ما ينكسر عمليًا هو أضيق نافذة.
    for (final width in [1180.0, 1280.0, 1340.0, 1600.0, 2200.0]) {
      await tester.binding.setSurfaceSize(Size(width, 760));
      for (final tab in WorkspaceTab.values) {
        store.selectTab(tab);
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'انكسر التخطيط عند $width — ${tab.name}',
        );
      }
    }
    store.selectTab(WorkspaceTab.colors);
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    await tester.pump();
  });

  testWidgets('المعاينة تحسب التغييرات وتتيح التنقّل بينها', (tester) async {
    final file = File(_realPath);
    if (!file.existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي في $_realPath');
      return;
    }
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = WorkspaceStore();
    await tester.runAsync(
      () => store.open(
        _realPath,
        'manual.docx',
        Uint8List.fromList(file.readAsBytesSync()),
      ),
    );

    await tester.pumpWidget(
      wrap(
        ListenableBuilder(
          listenable: store,
          builder: (_, _) => WorkspaceScreen(
            store: store,
            identities: IdentityStore(Directory.systemTemp),
            fonts: offlineFonts(),
            settings: fakeSettings(),
          ),
        ),
      ),
    );
    await tester.pump();
    final t = await L.delegate.load(const Locale('ar'));
    expect(find.text(t.noChangesYet), findsOneWidget);

    // لون كثير الاستعمال ⇒ عدّاد تغييرات كبير وتنقّل مفعَّل.
    final busy = store.report!.contentColors.firstWhere(
      (c) => c.color.value == '#4C2FB8',
    );
    store.mapColor(busy.color, store.report!.contentColors.last.color);
    await tester.pump();

    expect(find.text(t.noChangesYet), findsNothing);
    // نصّ المستند نفسه يحوي "/" — نطابق صيغة العدّاد وحدها.
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^\d+ / \d+$').hasMatch(w.data ?? ''),
      ),
      findsOneWidget,
      reason: 'يجب أن يظهر عدّاد "س / ص" للتنقّل بين التغييرات',
    );

    // زرّ «التالي» يعمل ولا يرمي.
    await tester.tap(find.byIcon(LucideIcons.chevronDown).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('الواجهة تعمل بالإنجليزية واتجاهها يتبع اللغة', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrap(
        WorkspaceScreen(
          store: WorkspaceStore(),
          identities: IdentityStore(Directory.systemTemp),
          fonts: offlineFonts(),
          settings: fakeSettings('en'),
        ),
        locale: 'en',
      ),
    );

    final en = await L.delegate.load(const Locale('en'));
    final ar = await L.delegate.load(const Locale('ar'));
    expect(find.text(en.dropHere), findsOneWidget);
    expect(find.text(en.tabColors), findsWidgets);
    expect(find.text(en.documentFacts), findsOneWidget);
    expect(find.text(ar.dropHere), findsNothing);

    // الاتجاه يأتي من اللغة تلقائيًا، لا يُفرَض في الكود.
    expect(
      Directionality.of(tester.element(find.text(en.tabColors).first)),
      equals(TextDirection.ltr),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('تبديل اللغة يعيد رسم الواجهة كاملة', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final settings = fakeSettings();
    final store = WorkspaceStore();
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: settings,
        builder: (_, _) => wrap(
          WorkspaceScreen(
            store: store,
            identities: IdentityStore(Directory.systemTemp),
            fonts: offlineFonts(),
            settings: settings,
          ),
          locale: settings.locale.languageCode,
        ),
      ),
    );
    final ar = await L.delegate.load(const Locale('ar'));
    final en = await L.delegate.load(const Locale('en'));
    expect(find.text(ar.dropHere), findsOneWidget);

    await tester.runAsync(() => settings.setLocale(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text(en.dropHere), findsOneWidget);
    expect(find.text(ar.dropHere), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
