/// قياس كلفة رسم المعاينة.
///
/// الشكوى كانت «التطبيق ثقيل». العلاج كان العرض المُحجَّم: القائمة تبني
/// الصفحات المرئية فقط. هذا الاختبار يثبّت المكسب ويمنع الانحدار إليه.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/preview/document_paper.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _realPath =
    '../../../_lab/الحرس/SCyWF_Assessment_Operations_Manual_Stage0_PreExam_MainExam.docx';

/// خدمة خطوط بلا شبكة: الاختبارات لا تتصل بالإنترنت أبدًا.
FontService offlineFonts() =>
    FontService(FontCache(Directory.systemTemp))..fetchEnabled = false;

void main() {
  testWidgets('لا تُبنى إلا الصفحات المرئية', (tester) async {
    final file = File(_realPath);
    if (!file.existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
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

    final total = store.document!.preview.pageCount;
    expect(total, greaterThan(25), reason: 'المستند مقسَّم إلى صفحات فعلًا');

    final started = DateTime.now();
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
            fonts: offlineFonts(),
            settings: SettingsStore(
              File('${Directory.systemTemp.path}/e3ks_perf.json'),
              const Locale('ar'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final elapsed = DateTime.now().difference(started);

    final built = tester.widgetList(find.byType(DocumentPaper)).length;
    expect(
      built,
      lessThan(8),
      reason: 'بُنيت $built صفحة من $total — العرض المُحجَّم معطّل',
    );
    expect(
      elapsed.inMilliseconds,
      lessThan(2500),
      reason: 'أول رسمة استغرقت ${elapsed.inMilliseconds}ms',
    );
    expect(tester.takeException(), isNull);
  });

  test('الصفحة تُعرَض قبل الفحص، واللوحات تلحق', () async {
    // **الخلل الذي وُلد منه الاختبار:** الفحص كان يسبق أوّل رسمة ويكلّف
    // ٣٢٥ms لمئة صفحة، وأوّلُ صفحات المعاينة ٤١ — فكان المستخدم ينتظر
    // حصيلةً لا ينظر إليها بعد ليرى صفحةً ينظر إليها الآن.
    final file = File(_realPath);
    if (!file.existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }

    final store = WorkspaceStore();
    final reports = <bool>[];
    store.addListener(() {
      if (store.hasDocument) reports.add(store.report != null);
    });

    await store.open(
      _realPath,
      'manual.docx',
      Uint8List.fromList(file.readAsBytesSync()),
    );

    expect(reports, isNotEmpty, reason: 'لم يُعرَض المستند قطّ');
    expect(
      reports.first,
      isFalse,
      reason: 'وصل الفحص مع أوّل عرض: ما زال على المسار الحرج',
    );
    expect(reports.last, isTrue, reason: 'لم تصل حصيلة الفحص قطّ');
    expect(store.inspecting, isFalse);
  });

  test('المعاينة تصل على دفعتين: أوّل الصفحات ثم تمامها', () async {
    // **الخلل الذي وُلد منه الاختبار:** كانت المعاينة تُستخرَج كاملةً قبل
    // أن يُعرَض شيء، فينتظر المستخدم آخر المستند ليرى أوّله — ٦٠٩ms لمئة
    // صفحة و٢٫٣ ثانية لثمانمئة، مقابل ٤١ و١٧٣ لأوّل صفحاتها.
    final file = File(_realPath);
    if (!file.existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
      return;
    }

    final store = WorkspaceStore();
    final seen = <int>[];
    store.addListener(() {
      final preview = store.document?.preview;
      if (preview != null) seen.add(preview.pageCount);
    });

    await store.open(
      _realPath,
      'manual.docx',
      Uint8List.fromList(file.readAsBytesSync()),
    );

    expect(seen, isNotEmpty, reason: 'لم يُعرَض المستند قطّ');
    expect(
      seen.first,
      lessThan(seen.last),
      reason: 'وصلت المعاينة دفعةً واحدة: ${seen.join("، ")}',
    );
    expect(seen.first, greaterThan(0), reason: 'الدفعة الأولى بلا صفحات');
    expect(store.previewPartial, isFalse, reason: 'بقيت المعاينة ناقصة');
  });

  testWidgets('تبديل لون لا يعيد بناء المستند كلّه', (tester) async {
    final file = File(_realPath);
    if (!file.existsSync()) {
      markTestSkipped('لا يوجد مستند حقيقي');
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
            fonts: offlineFonts(),
            settings: SettingsStore(
              File('${Directory.systemTemp.path}/e3ks_perf.json'),
              const Locale('ar'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final busy = store.report!.contentColors.firstWhere(
      (c) => c.color.value == '#4C2FB8',
    );
    final started = DateTime.now();
    store.mapColor(busy.color, store.report!.contentColors.last.color);
    await tester.pump();
    final elapsed = DateTime.now().difference(started);

    expect(
      elapsed.inMilliseconds,
      lessThan(1200),
      reason: 'تبديل لون استغرق ${elapsed.inMilliseconds}ms',
    );
    expect(tester.widgetList(find.byType(DocumentPaper)).length, lessThan(8));
    expect(tester.takeException(), isNull);
  });
}
