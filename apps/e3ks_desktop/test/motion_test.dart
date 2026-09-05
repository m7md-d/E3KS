/// الحركة: مرجع واحد، ومرّةً واحدة، ولا شيء يبقى معلَّقًا.
library;

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/features/splash/splash_view.dart';
import 'package:e3ks_desktop/shared/widgets/app_dialog.dart';
import 'package:e3ks_desktop/shared/widgets/entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// شفافية الطفل كما تُرسَم فعلًا.
double opacityOf(WidgetTester tester, String label) => tester
    .widgetList<FadeTransition>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(FadeTransition),
      ),
    )
    .fold<double>(1, (value, t) => value * t.opacity.value);

void main() {
  group('الدخول', () {
    testWidgets('يبدأ خفيًّا وينتهي ظاهرًا', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Entrance(child: Text('لوحة'))),
        ),
      );

      expect(opacityOf(tester, 'لوحة'), lessThan(0.1));
      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'لوحة'), equals(1));
    });

    testWidgets('الترتيب يؤخّر البداية ولا يُلغيها', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Entrance(child: Text('أول')),
                Entrance(order: 3, child: Text('آخر')),
              ],
            ),
          ),
        ),
      );

      // بعد زمن الدخول وحده: الأول انتهى، والآخر ما زال في طريقه.
      await tester.pump(Motion.entrance);
      expect(opacityOf(tester, 'أول'), equals(1));
      expect(opacityOf(tester, 'آخر'), lessThan(1));

      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'آخر'), equals(1));
    });

    testWidgets('لا تُعاد الحركة مع إعادة البناء', (tester) async {
      // الفخّ: هذه الودجة تعيش داخل `ListenableBuilder` يُعاد بناؤه مع كل
      // تغيّر حالة. حركةٌ تُعاد تعني ارتجاج الواجهة كلّما بدّل المستخدم لونًا.
      final tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (_, value, _) =>
                  Entrance(child: Text('لوحة $value', key: const Key('p'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'لوحة 0'), equals(1));

      tick.value = 1;
      await tester.pump();
      expect(
        opacityOf(tester, 'لوحة 1'),
        equals(1),
        reason: 'أُعيدت الحركة عند إعادة البناء',
      );
    });

    testWidgets('الإطفاء يُظهر فورًا بلا حركة', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Entrance(enabled: false, child: Text('لوحة'))),
        ),
      );
      expect(opacityOf(tester, 'لوحة'), equals(1));
      expect(
        find.descendant(
          of: find.byType(Entrance),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
        reason: 'الإطفاء يعني ألّا تُبنى الحركة أصلًا',
      );
    });
  });

  testWidgets('شاشة الدخول تعرض العلامة على أرضية التطبيق', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashView(name: 'E3KS')));
    await tester.pumpAndSettle();
    expect(find.text('E3KS'), findsNWidgets(2), reason: 'الاسم وانعكاسه');
    expect(tester.takeException(), isNull);
  });

  testWidgets('الحوار يفتح ويُغلق بحركتنا وينتهي', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppDialog<void>(
                context,
                (_) => const Dialog(child: SizedBox(height: 80)),
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح'));
    await tester.pump();
    // الحوار موجود من أول إطار، وحركته تبدأ من مقاس قريب لا من قفزة.
    expect(find.byType(Dialog), findsOneWidget);
    final scale = tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.byType(Dialog),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, greaterThanOrEqualTo(0.98));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
