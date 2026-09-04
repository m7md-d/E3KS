/// الورقة تُرسم بمقاس الصفحة لا بمقاس محتواها.
///
/// الشكوى كانت: «يعرض الصفحات بأحجام متفاوتة». هذا الاختبار يقيس المقاس
/// المرسوم فعلًا ويقارنه بما صرّح به المستند.
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
        File('${Directory.systemTemp.path}/e3ks_size.json'),
        const Locale('ar'),
      ),
    ),
  ),
);

void main() {
  testWidgets('كل ورقة بعرض صفحتها وارتفاعها لا بمقاس محتواها', (tester) async {
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

    await tester.pumpWidget(harness(store));
    await tester.pump();

    // العرض المُحجَّم يبني المرئي وحده، فنمرّر المستند كلّه لنقيس عيّنة
    // معتبرة لا صفحةً واحدة.
    final widths = <double>{};
    final overflow = <int, bool>{};
    final ratio = <int, double>{};

    void measureVisible() {
      for (final paper in tester.widgetList<DocumentPaper>(
        find.byType(DocumentPaper),
      )) {
        final size = tester.getSize(find.byWidget(paper));
        final scale = paper.zoom * Metrics.pxPerPoint;
        final expectedWidth = paper.page.geometry.widthPt * scale;
        final expectedHeight = paper.page.geometry.heightPt * scale;

        expect(
          size.width,
          closeTo(expectedWidth, 0.5),
          reason: 'العرض يجب أن يكون عرض الصفحة',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(expectedHeight - 0.5),
          reason: 'الورقة لا تقصر عن صفحتها أبدًا',
        );

        widths.add(size.width);
        overflow[paper.startNumber] = size.height > expectedHeight + 1;
        ratio[paper.startNumber] = size.height / expectedHeight;
      }
    }

    measureVisible();

    // أقرب Scrollable فوق الورقة هو قائمة الصفحات نفسها.
    final list = tester.state<ScrollableState>(
      find
          .ancestor(
            of: find.byType(DocumentPaper).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );

    for (
      var offset = 900.0;
      offset < list.position.maxScrollExtent && overflow.length < 25;
      offset += 900
    ) {
      list.position.jumpTo(offset);
      await tester.pump();
      measureVisible();
    }

    expect(overflow.length, greaterThan(15), reason: 'العيّنة صغيرة جدًّا');
    expect(widths, hasLength(1), reason: 'صفحات المستند الواحد بعرض واحد');

    // نحن لا نحسب انكسار السطر كما يحسبه Word، فقد تفيض صفحة عن ورقتها.
    // نمدّها ولا نقصّها — إخفاء محتوى في أداة معاينة كذب.
    //
    // **لا يُشدَّد هذا الحدّ:** بيئة الاختبار ترسم بخطّ بديل مقاساته ليست
    // مقاسات الخطّ الحقيقي، فالتفاف السطر هنا ليس التفافه عند المستخدم.
    // الحدّ حارس ضدّ انهيار التخطيط، لا مقياس أمانة.
    final worst = ratio.values.reduce((a, b) => a > b ? a : b);
    expect(
      worst,
      lessThan(3.0),
      reason: 'أطول صفحة بلغت ${worst.toStringAsFixed(2)} ضعف ورقتها',
    );

    final overflowing = overflow.values.where((v) => v).length;
    expect(
      overflowing,
      lessThan(overflow.length),
      reason: 'فاضت كل الصفحات — التخطيط أطول من الورق بكثير',
    );
  });
}
