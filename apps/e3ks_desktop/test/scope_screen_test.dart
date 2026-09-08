/// العامّ والخاصّ على الشاشة — `ADR 0005` §٢، المرحلة ٣.
///
/// **النموذج مُختبَرٌ في `working_set_test.dart`، وهذا يختبر وصوله إلى اليد**:
/// مخزَنٌ يعرف الطبقتين وواجهةٌ لا تكتب فيهما إلا الخاصّة آلةٌ بلا مقابض،
/// وكل اختبارات النموذج تمرّ عليها خضراء.
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
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _demo = '../../docs/demo/brand-guidelines.docx';

/// `!` مضمون: القيمة أدناه بصيغة `#RRGGBB` صحيحة.
final _target = HexColor.tryParse('#00635D')!;

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
              File('${Directory.systemTemp.path}/e3ks_scope.json'),
              const Locale('ar'),
            ),
          ),
        ),
      ),
    );

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

  /// زرّ خيارات الملفّ في صفّه من الشجرة — مفتاح الصفّ موضعُ ملفّه.
  Finder actionsIn(int index) => find.descendant(
    of: find.byKey(ValueKey(index)),
    matching: find.byTooltip('خيارات الملفّ'),
  );

  /// أوّل لونٍ في تقرير الملفّ النشط — الصفّ الأعلى في اللوحة.
  HexColor firstColor(WorkspaceStore store) {
    final report = store.report;
    // فُتح المستند وفُحص قبل النداء، فالتقرير حاضر ولا يخلو من لون.
    return report!.contentColors.first.color;
  }

  testWidgets('القاعدة في مجموعة تُكتب عامّة، والمربّع يحصرها', skip: !ready, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await open(tester, 2);
    await _pump(tester, store);
    await tester.pumpAndSettle();

    // **ما تكتبه اللوحة هو ما يكتبه المستخدم**: نفس النطاق الذي يمرّره
    // `_edit` بعد المنتقي.
    final color = firstColor(store);
    store.mapColor(color, _target, store.scopeForColor(color));
    await tester.pumpAndSettle();

    expect(
      store.planFor(0).colors[color],
      equals(_target),
      reason: 'الافتراض في المجموعة عامّ',
    );
    expect(store.planFor(1).colors[color], equals(_target));

    final box = find.text('خاصّ بهذا الملفّ');
    expect(box, findsOneWidget, reason: 'لا مربّع على القاعدة');

    await tester.tap(box);
    await tester.pumpAndSettle();

    expect(store.planFor(store.activeIndex).colors[color], equals(_target));
    final other = store.activeIndex == 0 ? 1 : 0;
    expect(
      store.planFor(other).colors,
      isNot(contains(color)),
      reason: 'الحصر لم يبلغ غيره',
    );

    // **وعند أضيق نافذة مسموحة** (`03`): المربّع سطرٌ زائد في صفٍّ ضيّق،
    // والتجاوز لا يراه المحلّل.
    await tester.binding.setSurfaceSize(const Size(1180, 720));
    await tester.pumpAndSettle();
    expect(find.text('خاصّ بهذا الملفّ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ملفٌّ واحد بلا مربّع طبقة', skip: !ready, (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await open(tester, 1);
    await _pump(tester, store);
    await tester.pumpAndSettle();

    final color = firstColor(store);
    store.mapColor(color, _target, store.scopeForColor(color));
    await tester.pumpAndSettle();

    // سؤالٌ بلا جواب: ليس في المجموعة ملفٌّ آخر يعمّ عليه شيء.
    expect(find.text('خاصّ بهذا الملفّ'), findsNothing);
  });

  testWidgets('المقفل يقول قفله فوق لوحاته', skip: !ready, (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await open(tester, 2);
    await _pump(tester, store);
    await tester.pumpAndSettle();

    expect(
      find.text('هذا الملفّ مقفل: الخطة العامّة لا تسري عليه.'),
      findsNothing,
    );

    store.setLocked(store.activeIndex, true);
    await tester.pumpAndSettle();

    expect(
      find.text('هذا الملفّ مقفل: الخطة العامّة لا تسري عليه.'),
      findsOneWidget,
      reason: 'قفلٌ صامت يجعل التعديل العامّ يبدو عاطلًا',
    );
    expect(store.defaultScope, equals(EditScope.file));
  });

  testWidgets('المنتقي لا يعرض هويات الملفات المفتوحة', skip: !ready, (
    tester,
  ) async {
    // **خللٌ وُلد منه هذا الاختبار:** كل ملفّ مفتوح كان يضيف صفَّ ألوانٍ
    // مستخرَجًا في حينه، فمجلدٌ من عشرة ملفات يملأ النافذة بعشرة صفوف
    // ويدفع زرّ الاعتماد خارجها. والمصدر الوحيد اليوم الهويات المحفوظة.
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await open(tester, 3);
    await _pump(tester, store);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('اختر اللون البديل').first);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget, reason: 'لم يُفتح المنتقي');
    for (var i = 0; i < 3; i++) {
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('ملف$i.docx'),
        ),
        findsNothing,
        reason: 'هوية ملفٍّ مفتوح عادت إلى المنتقي',
      );
    }
  });

  testWidgets('قائمة الملفّ في الشجرة تضبط علامات المستخدم', skip: !ready, (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await open(tester, 2);
    await _pump(tester, store);
    await tester.pumpAndSettle();

    final button = actionsIn(store.activeIndex);
    expect(button, findsOneWidget, reason: 'لا باب إلى علامات الملفّ');

    await tester.tap(button);
    await tester.pumpAndSettle();
    // **`warnIfMissed` مطفأ عن قصد**: الضغطة يتلقّاها عنصر القائمة الملتفّ
    // حول النصّ، فيقول المحذّر إن النصّ نفسه ليس هدف الاختبار — وهو بنية
    // `PopupMenuItem` لا خلل في الاختبار.
    await tester.tap(find.text('تمت مراجعته').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(store.files[store.activeIndex].reviewed, isTrue);

    await tester.tap(actionsIn(store.activeIndex));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('مقفل عن الخطة العامّة').last,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(store.files[store.activeIndex].locked, isTrue);
    expect(
      find.text('هذا الملفّ مقفل: الخطة العامّة لا تسري عليه.'),
      findsOneWidget,
    );
  });

  testWidgets('قائمة صفٍّ غير محدَّد تعمل، وعلى ملفّه هو', skip: !ready, (
    tester,
  ) async {
    // **خللٌ وُلد منه هذا الاختبار:** الزرّ كان يظهر عند التصويب ويُنزَع عند
    // انتهائه — وفتحُ القائمة يُنهي التصويب. فيُنزَع الزرّ من الشجرة، ثم
    // **تُسقط `PopupMenuButton` الاختيار صامتةً** لأن زرّها غير مركَّب:
    // تُفتح القائمة، ويُضغط الخيار، ولا يحدث شيء.
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await open(tester, 2);
    await _pump(tester, store);
    await tester.pumpAndSettle();

    final other = store.activeIndex == 0 ? 1 : 0;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(actionsIn(other)));
    await tester.pumpAndSettle();

    await tester.tap(actionsIn(other));
    await tester.pumpAndSettle();
    // والمؤشّر يغادر الصفّ إلى القائمة، كما يفعل المستخدم.
    await mouse.moveTo(tester.getCenter(find.text('تمت مراجعته').last));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تمت مراجعته').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(store.files[other].reviewed, isTrue, reason: 'سقط الاختيار');
    expect(
      store.files[store.activeIndex].reviewed,
      isFalse,
      reason: 'وقع على المحدَّد لا على صاحب القائمة',
    );
  });
}
