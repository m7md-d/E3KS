/// شاشة الرخص: ترويستنا، وقائمة واحدة لا لوحتان، ولا تداخل عند أضيق نافذة.
///
/// شاشة Material كانت تبني «قائمة وتفصيل» فتتزاحم لوحتاها على سطح المكتب،
/// وتحمل ترويستها هي. هذا الاختبار يمنع العودة إلى ذلك.
library;

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/features/settings/licenses_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Locale locale) => MaterialApp(
  theme: buildTheme(),
  locale: locale,
  supportedLocales: L.supportedLocales,
  localizationsDelegates: const [
    L.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: const LicensesScreen(),
);

void main() {
  setUp(() {
    LicenseRegistry.reset();
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(
        ['IBM Plex Sans Arabic'],
        'SIL OPEN FONT LICENSE Version 1.1\n\n'
            'PREAMBLE: The goals of the Open Font License (OFL) are to '
            'stimulate worldwide development of collaborative font projects.',
      );
      yield const LicenseEntryWithLineBreaks(['archive'], 'BSD license text.');
    });
  });

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    final tag = locale.languageCode;

    testWidgets('لا تداخل ولا تجاوز عند أضيق نافذة — $tag', (tester) async {
      // ‏1180×720 هي أضيق نافذة مسموحة، مفروضة في MainFlutterWindow.
      await tester.binding.setSurfaceSize(const Size(1180, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(harness(locale));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('IBM Plex Sans Arabic'), findsOneWidget);
      expect(find.text('archive'), findsOneWidget);
    });

    testWidgets('الفتح يُظهر النصّ، وواحد فقط مفتوح — $tag', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1180, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(harness(locale));
      await tester.pumpAndSettle();

      expect(find.textContaining('OPEN FONT LICENSE'), findsNothing);

      await tester.tap(find.text('IBM Plex Sans Arabic'));
      await tester.pumpAndSettle();
      expect(find.textContaining('OPEN FONT LICENSE'), findsOneWidget);

      // فتح غيرها يُغلق الأولى: قائمةٌ كلّها مفتوحة تفقد كونها قائمة.
      await tester.tap(find.text('archive'));
      await tester.pumpAndSettle();
      expect(find.textContaining('OPEN FONT LICENSE'), findsNothing);
      expect(find.textContaining('BSD license'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ترويستنا لا ترويسة إطار العمل', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1180, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(harness(const Locale('ar')));
    await tester.pumpAndSettle();

    // علامة طرف ثالث في شاشةٍ تعرض حقوقنا.
    expect(find.textContaining('Powered by'), findsNothing);
    expect(find.text('رخص المكوّنات'), findsOneWidget);
  });

  testWidgets('الحركة كلّها تنتهي — لا حركة معلَّقة', (tester) async {
    // ‏`pumpAndSettle` يفشل إن بقيت حركة تعمل، فهذا يحرس من حركة لا تنتهي.
    await tester.binding.setSurfaceSize(const Size(1180, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(harness(const Locale('en')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('archive'));
    await tester.pump();
    await tester.pump(Motion.normal);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
