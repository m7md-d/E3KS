/// العلامات على النصّ في الواجهة: جدولها، ورفعها، وتتبّع مواضعها.
///
/// **الحاجة التي تخدمها:** ملفّ يصل المستخدم وفيه تحديد لا يرفعه قلم Word،
/// لأنه `w:shd` داخل `w:rPr` لا `w:highlight`. اللوحة تُظهر الاثنين وترفعهما.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/mapping/marks_panel.dart';
import 'package:e3ks_desktop/features/preview/focus_bar.dart';
import 'package:e3ks_desktop/features/preview/page_index.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const String _demo = '../../docs/demo/brand-guidelines.docx';

const TextMark _yellow = TextMark(MarkKind.highlight, 'yellow');
final TextMark _grayShade = TextMark.shading(HexColor.tryParse('#D9D9D9')!);

/// متنٌ معلَّم يحلّ محلّ متن مستند العرض.
///
/// **يُبنى من مستند حقيقي لا من عدم**: بقيّة الأجزاء — الأنماط والعلاقات
/// وأنواع المحتوى — تبقى كما كتبها Word، فما نختبره هو قراءتنا لا صنعتنا.
const String _markedBody = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
<w:p><w:r><w:rPr><w:highlight w:val="yellow"/></w:rPr><w:t>marked yellow</w:t></w:r></w:p>
<w:p><w:r><w:rPr><w:shd w:val="clear" w:color="auto" w:fill="D9D9D9"/></w:rPr><w:t>pasted shading</w:t></w:r></w:p>
<w:p><w:r><w:t>plain paragraph</w:t></w:r></w:p>
</w:body>
</w:document>''';

Uint8List markedDocx() {
  final opened = DocumentPackage.open(
    Uint8List.fromList(File(_demo).readAsBytesSync()),
  );
  if (opened case Failed(:final issues)) fail('فتح: ${issues.join("، ")}');
  final package = (opened as Ok<DocumentPackage>).value;
  package.putText('word/document.xml', _markedBody);

  final built = package.build();
  if (built case Failed(:final issues)) fail('بناء: ${issues.join("، ")}');
  return (built as Ok<Uint8List>).value;
}

Future<WorkspaceStore> openMarked(WidgetTester tester) async {
  final store = WorkspaceStore();
  await tester.runAsync(() => store.open(_demo, 'marked.docx', markedDocx()));
  return store;
}

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
      fonts: FontService(FontCache(Directory.systemTemp))..fetchEnabled = false,
      settings: SettingsStore(
        File('${Directory.systemTemp.path}/e3ks_marks.json'),
        const Locale('ar'),
      ),
    ),
  ),
);

/// كل خلفيات المقاطع المرسومة في الشجرة — منها نعرف ما تراه العين.
Set<Color> paintedBackgrounds(WidgetTester tester) {
  final found = <Color>{};
  void walk(InlineSpan span) {
    if (span is TextSpan) {
      final background = span.style?.backgroundColor;
      if (background != null) found.add(background);
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child);
      }
    }
  }

  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final span = text.textSpan;
    if (span != null) walk(span);
  }
  return found;
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('الحالة', () {
    testWidgets('الرفع يدخل الخطة ويُحصى تغييرًا', (tester) async {
      final store = await openMarked(tester);
      expect(store.report!.marks, hasLength(2));
      expect(store.hasChanges, isFalse);

      store.liftMark(_yellow, true);
      expect(store.plan.removeMarks, equals({_yellow}));
      expect(store.plan.removes(_yellow), isTrue);
      expect(store.changeCount, equals(1));

      store.liftMark(_yellow, false);
      expect(store.plan.removeMarks, isEmpty);
      expect(store.hasChanges, isFalse);
    });

    testWidgets('«امسح الكل» يرفع كل علامة، والتراجع يعيدها', (tester) async {
      final store = await openMarked(tester);

      store.liftAllMarks(true);
      expect(store.liftedMarks, hasLength(2));
      expect(store.liftedMarks, contains(_grayShade));

      store.liftAllMarks(false);
      expect(store.liftedMarks, isEmpty);
    });

    testWidgets('التصفير يعيد العلامات كما يعيد الألوان', (tester) async {
      final store = await openMarked(tester);
      store.liftAllMarks(true);
      store.resetChanges();
      expect(store.liftedMarks, isEmpty);
      expect(store.hasChanges, isFalse);
    });

    testWidgets('متتبَّعٌ واحد في كل مرّة: العلامة ترفع اللون', (tester) async {
      // شريطا تتبّع فوق الورقة، وتمييزان متنافسان على المقطع نفسه — لا.
      final store = await openMarked(tester);
      final color = store.report!.contentColors.first.color;

      store.focusColor(color);
      expect(store.focusedColor, isNotNull);
      expect(store.tab, equals(WorkspaceTab.colors));

      store.focusMark(_yellow);
      expect(store.focusedMark, equals(_yellow));
      expect(store.focusedColor, isNull);
      expect(store.tab, equals(WorkspaceTab.marks));

      store.focusColor(color);
      expect(store.focusedMark, isNull);
    });

    testWidgets('إعادة التتبّع على العلامة نفسها ترفعه', (tester) async {
      final store = await openMarked(tester);
      store.focusMark(_yellow);
      store.focusMark(_yellow);
      expect(store.focusedMark, isNull);
    });
  });

  group('اللوحة', () {
    testWidgets('الجدول يعرض علامتَي المستند بعدديهما', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final store = await openMarked(tester);
      store.selectTab(WorkspaceTab.marks);
      await tester.pumpWidget(harness(store));
      await tester.pumpAndSettle();

      expect(find.byType(MarksPanel), findsOneWidget);
      // القلم بمفتاح المواصفة، والتظليل بسداسيّه — وهما ما يُكتبان في خطة
      // سطر الأوامر أيضًا.
      expect(find.text('yellow'), findsWidgets);
      expect(find.text('#D9D9D9'), findsWidgets);
    });

    testWidgets('ضغط «امسح» يرفع العلامة ويظهر في عدّاد التغييرات', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final store = await openMarked(tester);
      store.selectTab(WorkspaceTab.marks);
      await tester.pumpWidget(harness(store));
      await tester.pumpAndSettle();

      final t = L.of(tester.element(find.byType(MarksPanel)));
      await tester.tap(find.text(t.liftMark).first);
      await tester.pumpAndSettle();

      expect(store.liftedMarks, hasLength(1));
      expect(store.hasChanges, isTrue);
      expect(find.text(t.markLifted), findsWidgets);
    });

    testWidgets('الضغط على عيّنة العلامة يفتح شريط تتبّعها', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final store = await openMarked(tester);
      store.selectTab(WorkspaceTab.marks);
      await tester.pumpWidget(harness(store));
      await tester.pumpAndSettle();

      expect(find.byType(MarkFocusBar), findsNothing);

      store.focusMark(_yellow);
      await tester.pumpAndSettle();

      expect(find.byType(MarkFocusBar), findsOneWidget);
      expect(find.byType(ColorFocusBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('المعاينة', () {
    testWidgets('العلامة المرفوعة تُحصى تغييرًا في «قبل» وحدها', (
      tester,
    ) async {
      // شارة الشريط تقول «٣ تغييرات»، فمتصفّح التغييرات لا يقول «لا شيء».
      // وفي «بعد» لا أثر لها أصلًا، فلا إطار ولا قفزة — والموضعان يتفقان
      // لأن الدالّة واحدة.
      final store = await openMarked(tester);
      store.liftAllMarks(true);

      expect(
        changedPages(
          flattenPages(store.document!.preview),
          colors: const {},
          fonts: const {},
          marks: store.liftedMarks,
        ),
        isNotEmpty,
      );
      expect(
        changedPages(
          flattenPages(store.previewAfter!),
          colors: const {},
          fonts: const {},
          marks: store.liftedMarks,
        ),
        isEmpty,
      );
    });

    testWidgets('القلم يُرسَم بلونه على الورقة', (tester) async {
      // **بلا رسمه لا معنى للرفع:** المستخدم لا يرى ما يرفعه، ولا يرى أثره.
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final store = await openMarked(tester);
      await tester.pumpWidget(harness(store));
      await tester.pumpAndSettle();

      expect(
        paintedBackgrounds(tester),
        contains(const Color(0xFFFFFF00)),
        reason: 'أصفر القلم لم يُرسم',
      );
      expect(paintedBackgrounds(tester), contains(const Color(0xFFD9D9D9)));
    });

    testWidgets('رفع العلامة يُذهب أثرها من معاينة «بعد»', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final store = await openMarked(tester);
      await tester.pumpWidget(harness(store));
      await tester.pumpAndSettle();

      store.liftAllMarks(true);
      await tester.pumpAndSettle();

      expect(store.showAfter, isTrue);
      final painted = paintedBackgrounds(tester);
      expect(painted, isNot(contains(const Color(0xFFFFFF00))));
      expect(painted, isNot(contains(const Color(0xFFD9D9D9))));
    });
  });
}
