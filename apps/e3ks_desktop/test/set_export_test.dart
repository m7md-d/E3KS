/// تصدير المجموعة: كل ملفٍّ بخطّته، والبنية محفوظة — `ADR 0005` §٨.
///
/// **هذا ما يفصل المجموعة عن الدفعة القديمة**: تلك تمرّر خطّةً واحدة على
/// أربعين ملفًا، وهذه تكتب لكلٍّ خطّته الفعّالة. وخللٌ هنا يُخرج ملفًّا
/// بخطّة غيره، ولا شيء على الشاشة يقول ذلك.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/set_exporter.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/features/export/export_set_sheet.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _demo = '../../docs/demo/brand-guidelines.docx';

/// `!` مضمون: القيمة أدناه بصيغة `#RRGGBB` صحيحة.
final _target = HexColor.tryParse('#00635D')!;

void main() {
  final ready = File(_demo).existsSync();
  final bytes = ready
      ? Uint8List.fromList(File(_demo).readAsBytesSync())
      : Uint8List(0);

  late Directory work;

  setUp(() {
    if (!ready) return;
    work = Directory.systemTemp.createTempSync('e3ks_set_');
  });

  tearDown(() {
    if (ready && work.existsSync()) work.deleteSync(recursive: true);
  });

  /// يكتب المستند في [relative] تحت مجلد العمل، ويُرجع مساره.
  String seed(String relative) {
    final file = File('${work.path}/$relative');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return file.path;
  }

  group('التصدير', skip: ready ? null : 'لا يوجد مستند العرض', () {
    test('البنية محفوظة، ولكل ملفٍّ خطّته هو', () async {
      final root = '${work.path}/مصدر';
      final first = seed('مصدر/أول.docx');
      final second = seed('مصدر/فرع/ثانٍ.docx');

      final store = WorkspaceStore()..addDirectory(root);
      await store.open(first, 'أول.docx', bytes);
      await store.open(second, 'ثانٍ.docx', bytes);

      final report = store.report;
      // فُتح المستند وفُحص، فالتقرير حاضر ولا يخلو من لون.
      final color = report!.contentColors.first.color;

      // قاعدةٌ عامّة، والثاني مقفلٌ عنها.
      store.mapColor(color, _target, EditScope.general);
      store.setLocked(1, true);

      final out = Directory('${work.path}/مخرَج')..createSync();
      final outcome = await exportSet(
        jobs: store.exportJobs(),
        outDirectory: out.path,
      );

      expect(outcome.mishaps, isEmpty);
      expect(outcome.report.written, hasLength(2));
      expect(
        File('${out.path}/أول.docx').existsSync(),
        isTrue,
        reason: 'الملفّ الأول لم يُكتب',
      );
      expect(
        File('${out.path}/فرع/ثانٍ.docx').existsSync(),
        isTrue,
        reason: 'البنية لم تُحفَظ',
      );

      final written = outcome.report.written;
      final open = written.firstWhere((e) => e.name == 'أول.docx');
      final locked = written.firstWhere((e) => e.name == 'ثانٍ.docx');
      expect(
        open.report!.colorReplacements,
        contains(color),
        reason: 'القاعدة العامّة لم تبلغ الملفّ',
      );
      expect(
        locked.report!.colorReplacements,
        isEmpty,
        reason: 'القاعدة العامّة بلغت المقفل',
      );
    });

    test('مسارٌ تكرّر يُميَّز برقم ولا يُكتب فوق جاره', () async {
      // ملفّان باسمٍ واحد من جذرين: بلا تمييز يكتب أحدهما فوق الآخر صامتًا.
      final a = seed('أ/تقرير.docx');
      final b = seed('ب/تقرير.docx');

      final store = WorkspaceStore()
        ..addDirectory('${work.path}/أ')
        ..addDirectory('${work.path}/ب');
      await store.open(a, 'تقرير.docx', bytes);
      await store.open(b, 'تقرير.docx', bytes);

      final jobs = store.exportJobs();
      expect(jobs.map((j) => j.relative).toSet(), hasLength(2));
      expect(jobs[1].relative, equals('تقرير (2).docx'));

      final out = Directory('${work.path}/مخرَج')..createSync();
      await exportSet(jobs: jobs, outDirectory: out.path);
      expect(File('${out.path}/تقرير.docx').existsSync(), isTrue);
      expect(File('${out.path}/تقرير (2).docx').existsSync(), isTrue);
    });

    test('ملفٌّ تعذّرت قراءته يُقال ولا يُوقف البقيّة', () async {
      // **الحوار القديم كان يرمي من داخل العزلة**، فتموت الدفعة كلّها عند
      // أول ملفٍّ تعذّر. وأربعون فيها واحد تالف تعني تسعة وثلاثين مخرَجًا.
      final first = seed('مصدر/أول.docx');
      final second = seed('مصدر/ثانٍ.docx');
      final store = WorkspaceStore()..addDirectory('${work.path}/مصدر');
      await store.open(first, 'أول.docx', bytes);
      await store.open(second, 'ثانٍ.docx', bytes);

      final jobs = store.exportJobs();
      File(second).deleteSync();

      final out = Directory('${work.path}/مخرَج')..createSync();
      final outcome = await exportSet(jobs: jobs, outDirectory: out.path);

      expect(outcome.report.written, hasLength(1), reason: 'سقطت البقيّة معه');
      expect(outcome.mishaps, hasLength(1));
      expect(outcome.mishaps.first.name, equals('ثانٍ.docx'));
      expect(
        outcome.mishaps.first.reason,
        isNotEmpty,
        reason: 'سببٌ صامت (`00` §5)',
      );
    });

    test('التقدّم بالعدد، ومن الصفر إلى الكلّ', () async {
      seed('مصدر/أول.docx');
      final store = WorkspaceStore()..addDirectory('${work.path}/مصدر');
      await store.open('${work.path}/مصدر/أول.docx', 'أول.docx', bytes);

      final seen = <int>[];
      final out = Directory('${work.path}/مخرَج')..createSync();
      await exportSet(
        jobs: store.exportJobs(),
        outDirectory: out.path,
        onProgress: (done, total) {
          expect(total, equals(1));
          seen.add(done);
        },
      );
      expect(seen, equals([0, 1]));
    });
  });

  testWidgets('لا كتابة قبل مراجعة', skip: !ready, (tester) async {
    // **مخالفة `03` تُغلق هنا**: «لا زرّ ينفّذ عملية غير قابلة للتراجع دون
    // معاينة قبلها». الشاشة تسمّي كل ملفّ وموضعه، ولا تكتب حتى تُختار وجهة.
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final first = seed('مصدر/أول.docx');
    final second = seed('مصدر/فرع/ثانٍ.docx');
    final store = WorkspaceStore()..addDirectory('${work.path}/مصدر');
    await tester.runAsync(() => store.open(first, 'أول.docx', bytes));
    await tester.runAsync(() => store.open(second, 'ثانٍ.docx', bytes));

    final report = store.report;
    // فُتح المستند وفُحص، فالتقرير حاضر ولا يخلو من لون.
    store.mapColor(report!.contentColors.first.color, _target);

    await tester.pumpWidget(
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
              File('${Directory.systemTemp.path}/e3ks_export.json'),
              const Locale('ar'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('صدّر المستند'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المجموعة كلّها').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('تصدير المجموعة'), findsOneWidget);
    // كل ملفّ بموضعه من المخرَج، لا بعدده وحده.
    expect(find.text('أول.docx'), findsWidgets);
    expect(
      find.text('فرع/ثانٍ.docx'),
      findsOneWidget,
      reason: 'البنية لا تُعرَض',
    );

    final run = find.widgetWithText(FilledButton, 'صدّر');
    expect(run, findsOneWidget);
    expect(
      tester.widget<FilledButton>(run).onPressed,
      isNull,
      reason: 'يكتب بلا وجهة مختارة',
    );

    // ولا ملفّ كُتب: الشاشة عُرضت ولم يُنفَّذ شيء.
    expect(Directory('${work.path}/مخرَج').existsSync(), isFalse);
  });

  test('حوار مجلد المخرَج يسمح بصنع مجلد', () {
    // **الخلل الذي وُلد منه الاختبار:** `NSOpenPanel` يخفي زرّ «مجلد جديد»
    // افتراضًا، فكان المستخدم يُطالَب بمجلد مخرَج بلا وسيلة لصنعه. والراية
    // تعبر إلى AppKit ولا يبلغها اختبار ودجة — الصندوق الرملي مثلها
    // (`03`) — فالحارس على المصدر: أن تبقى مكتوبة.
    final source = File(
      'lib/features/export/export_set_sheet.dart',
    ).readAsStringSync();
    final pick = source.substring(
      source.indexOf('Future<void> _chooseDestination'),
    );
    expect(
      pick.substring(0, pick.indexOf('  }')),
      contains('canCreateDirectories: true'),
    );
  });

  test('الساقط لا يترك مؤقّتًا وراءه', () async {
    if (!ready) return;
    seed('مصدر/سليم.docx');
    File('${work.path}/مصدر/تالف.docx').writeAsBytesSync([1, 2, 3]);

    final store = WorkspaceStore()..addDirectory('${work.path}/مصدر');
    await store.open('${work.path}/مصدر/سليم.docx', 'سليم.docx', bytes);
    final out = Directory('${work.path}/مخرَج')..createSync();
    await exportSet(
      jobs: [
        ...store.exportJobs(),
        (
          source: '${work.path}/مصدر/تالف.docx',
          relative: 'تالف.docx',
          name: 'تالف.docx',
          plan: const StylePlan(),
        ),
      ],
      outDirectory: out.path,
    );

    expect(File('${out.path}/تالف.docx').existsSync(), isFalse);
    expect(
      out.listSync(recursive: true).where((e) => e.path.endsWith('.part')),
      isEmpty,
      reason: 'مؤقّتٌ بقي بعد السقوط',
    );
  }, skip: !ready);

  testWidgets('شاشة التصدير تُفتح عند أضيق نافذة بلا تجاوز', skip: !ready, (
    tester,
  ) async {
    // أضيق نافذة مسموحة، وهي أكثر ما ينكسر عمليًّا (`03`).
    await tester.binding.setSurfaceSize(const Size(1180, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = WorkspaceStore()..addDirectory('${work.path}/مصدر');
    await tester.runAsync(
      () => store.open(seed('مصدر/أول.docx'), 'أول.docx', bytes),
    );
    await tester.runAsync(
      () => store.open(seed('مصدر/ثانٍ.docx'), 'ثانٍ.docx', bytes),
    );

    late BuildContext ctx;
    await tester.pumpWidget(
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
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    showSetExport(ctx, store);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
