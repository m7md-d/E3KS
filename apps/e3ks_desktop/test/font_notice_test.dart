/// إشعار الخطوط المتعذّرة: يظهر، ويُخفى بطلب المستخدم، ويعود لخطٍّ جديد.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_fetcher.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/features/preview/font_notice.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// جالبٌ لا يجد شيئًا: نريد حالة العجز لا حالة الشبكة.
class _Missing implements FontFetcher {
  const _Missing();

  @override
  Future<FetchResult> fetch(String family) async =>
      (outcome: FetchOutcome.notFound, bytes: null);
}

Widget harness(FontService fonts) => MaterialApp(
  theme: buildTheme(),
  locale: const Locale('ar'),
  supportedLocales: L.supportedLocales,
  localizationsDelegates: const [
    L.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: ListenableBuilder(
      listenable: fonts,
      builder: (_, _) => FontNotice(service: fonts, onDetails: () {}),
    ),
  ),
);

void main() {
  late Directory dir;
  late FontService fonts;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('e3ks_notice');
    fonts = FontService(FontCache(dir), fetcher: const _Missing());
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  // «Amiri» و«Lateef» خارج ما نشحنه وبلا بديل مضمَّن، فيبلغان حالة العجز
  // فعلًا. اسمٌ له بديل يُحلّ ولا يصل إلى الإشعار أصلًا.

  testWidgets('الخطّ المتعذّر يُعلَن', (tester) async {
    await fonts.resolveAll(['Amiri']);
    await tester.pumpWidget(harness(fonts));

    expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
  });

  testWidgets('زرّ الإخفاء يُزيل الإشعار', (tester) async {
    // إشعارٌ لا سبيل إلى إغلاقه يقتطع من المعاينة بعد أن أدّى غرضه.
    await fonts.resolveAll(['Amiri']);
    await tester.pumpWidget(harness(fonts));

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
  });

  testWidgets('خطّ آخر يتعذّر بعد الإخفاء يُعلَن من جديد', (tester) async {
    // الإخفاء بأسماء الخطوط لا بمفتاح شامل: مستندٌ تالٍ ينقصه خطٌّ آخر
    // يستحقّ إشعاره.
    await fonts.resolveAll(['Amiri']);
    await tester.pumpWidget(harness(fonts));
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    await fonts.resolveAll(['Lateef']);
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
  });

  testWidgets('خطّ يضيفه المستخدم يرفع تعذّره', (tester) async {
    // أقصر طريق إلى معاينة صادقة حين لا يكون الخطّ على الشبكة أصلًا.
    await fonts.resolveAll(['Frutiger']);
    expect(fonts.missing, hasLength(1));

    final added = await fonts.addFromFile(_ttfNamed('Frutiger'));

    expect(added, equals('Frutiger'));
    expect(fonts.missing, isEmpty);
  });
}

/// خطّ مصطنع يعلن عائلته في جدول `name` (الاسم 1).
Uint8List _ttfNamed(String family) {
  final text = <int>[];
  for (final unit in family.codeUnits) {
    text
      ..add(unit >> 8)
      ..add(unit & 0xFF); // UTF-16BE كما تكتبه منصّة Windows
  }
  const nameStart = 28; // 12 ترويسة + 16 سجلّ جدول واحد
  const storage = 6 + 12; // ترويسة الجدول + سجلّ واحد
  final name = <int>[
    0, 0,
    0, 1,
    0, storage,
    0, 3, 0, 1, 0, 0,
    0, 1, // nameID: اسم العائلة
    (text.length >> 8) & 0xFF, text.length & 0xFF,
    0, 0,
    ...text,
  ];
  return Uint8List.fromList([
    0x00,
    0x01,
    0x00,
    0x00,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    ...'name'.codeUnits,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    nameStart,
    0,
    0,
    0,
    name.length,
    ...name,
  ]);
}
