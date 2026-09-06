/// الشريط العلوي يتبع ما يحجزه النظام، ويتخلّى عنه حين يتخلّى النظام.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/window_frame.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// المسافة المطبَّقة على الشريط من كل حافّة (`03`).
const double _inset = 12;

/// المخازن تُبنى مرّةً: إعادة بنائها مع كل إطار تُنشئ شجرةً جديدة فتضيع
/// حالة الحركة، ولا يبقى ما يُقاس.
final WorkspaceStore _store = WorkspaceStore();
final IdentityStore _identities = IdentityStore(Directory.systemTemp);
final SettingsStore _settings = SettingsStore(
  File('${Directory.systemTemp.path}/e3ks_frame_test.json'),
  const Locale('ar'),
);
final FontService _fonts = FontService(FontCache(Directory.systemTemp))
  ..fetchEnabled = false;

/// مستند العرض المشحون مع المستودع — موجود دائمًا، فلا اختبار يُتخطّى.
const String _demo = '../../docs/demo/brand-guidelines.docx';

Future<WorkspaceStore> openDemo(WidgetTester tester) async {
  final store = WorkspaceStore();
  await tester.runAsync(
    () => store.open(
      _demo,
      'brand-guidelines.docx',
      Uint8List.fromList(File(_demo).readAsBytesSync()),
    ),
  );
  return store;
}

Widget harness(WindowFrame frame, {WorkspaceStore? store}) => MaterialApp(
  theme: buildTheme(),
  locale: const Locale('ar'),
  supportedLocales: L.supportedLocales,
  localizationsDelegates: const [
    L.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: WorkspaceScreen(
    store: store ?? _store,
    identities: _identities,
    settings: _settings,
    fonts: _fonts,
    frame: frame,
  ),
);

/// حشوة الشريط العلوي: الحاوية الوحيدة التي تحمل المسافة من أعلى ومن أسفل.
EdgeInsets topBarPadding(WidgetTester tester) {
  final containers = tester.widgetList<Container>(find.byType(Container));
  for (final box in containers) {
    final padding = box.padding;
    if (padding is EdgeInsets &&
        padding.top == _inset &&
        padding.bottom == _inset) {
      return padding;
    }
  }
  fail('لم يُعثر على الشريط العلوي');
}

void main() {
  // النافذة أوسع من الحدّ الأدنى المفروض على المنصّات الثلاث (1180×720).
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('الحجز يمينًا يزيد حشوة اليمين وحدها', (tester) async {
    // نظام بلغة عربية ينقل أزرار النافذة إلى اليمين.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness((titlebarHeight: 28, reserveLeft: 0, reserveRight: 78)),
    );

    final padding = topBarPadding(tester);
    expect(padding.right, equals(_inset + 78));
    expect(padding.left, equals(_inset));
  });

  testWidgets('ملء الشاشة يُسقط الحجز فلا يبقى فراغ بلا شاغل', (tester) async {
    // **الخلل الذي يعالجه هذا الاختبار:** أزرار النظام تختفي في ملء الشاشة،
    // وكان الشريط يبقى محتفظًا بحجزها لأن القياس كان يُقرأ مرّةً عند
    // الإقلاع. الآن يدفع النظام قياسًا جديدًا، والشريط يتبعه.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(flatWindowFrame));

    final padding = topBarPadding(tester);
    expect(padding.left, equals(_inset));
    expect(padding.right, equals(_inset));
  });

  testWidgets('المسافة واحدة من كل حافّة حين لا حجز', (tester) async {
    // فرقٌ بين الرأسية والأفقية يُرى ولو لم يُقَس (`03`).
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(flatWindowFrame));

    final padding = topBarPadding(tester);
    expect(padding.left, equals(padding.top));
    expect(padding.right, equals(padding.bottom));
  });

  testWidgets('تغيّر الحجز ينتقل بحركة لا بقفزة', (tester) async {
    // الحجز يسقط حين يُخفي النظام أزراره عند ملء الشاشة. القفزة تجعل الشريط
    // يبدو منكسرًا في اللحظة التي يستقرّ فيها كل شيء آخر.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness((titlebarHeight: 28, reserveLeft: 0, reserveRight: 78)),
    );
    expect(topBarPadding(tester).right, equals(_inset + 78));

    await tester.pumpWidget(harness(flatWindowFrame));
    await tester.pump(Motion.slow ~/ 2);

    final mid = topBarPadding(tester).right;
    expect(mid, greaterThan(_inset), reason: 'قفز إلى النهاية بلا حركة');
    expect(mid, lessThan(_inset + 78), reason: 'لم يتحرّك أصلًا');

    await tester.pumpAndSettle();
    expect(topBarPadding(tester).right, equals(_inset));
  });

  testWidgets('طرف الشريط يلتصق بحافّته مهما اتّسعت النافذة', (tester) async {
    // **خلل حقيقي:** كان في الصفّ مرنان — `Flexible` لاسم الملف و`Spacer`
    // بعده — و`RenderFlex` يقسم الفضاء الحرّ بين المرنَين بالتساوي. الاسم
    // يأخذ حاجته وحدها، ونصيبه الباقي يسقط **في آخر الصفّ**: الطرف الأيمن
    // ينزاح عن حافّته بمقدارٍ يتّسع باتّساع النافذة. بلغ ٣٢٣ بكسل في لقطات
    // README حتى بدا كأنه حجزٌ لأزرار نظامٍ غائبة.
    //
    // ولذلك يُقاس على عرضين: الفراغ الثابت مع اتّساع النافذة هو الدليل.
    // والواجهة هنا عربية، فطرف الأفعال يسارًا وآخر الصفّ عنده.
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = await openDemo(tester);
    expect(store.hasDocument, isTrue, reason: 'مستند العرض لم يُفتح');

    for (final width in [1400.0, 1600.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(harness(flatWindowFrame, store: store));
      await tester.pumpAndSettle();

      final button = tester.getRect(find.byType(FilledButton).first);
      expect(button.top, equals(_inset), reason: 'ليس زرّ الشريط');
      expect(
        button.left,
        equals(_inset),
        reason: 'طرف الأفعال منزاح عن حافّته عند عرض $width',
      );
    }
  });

  testWidgets('نصّ أزرار الشريط لا يُقصّ عند حدوده', (tester) async {
    // **خلل حقيقي:** `RenderParagraph` يقصّ عند حدود صندوقه متى فاض النصّ
    // عن قيوده ولو بجزء من بكسل، والقصّ يأخذ معه ذيل الحرف النازل — راء
    // «اختر» كانت تخرج مبتورة في هذا الزرّ وحده. ولم يظهر في زرٍّ معزول:
    // الشريط الحقيقي بصفّه الضيّق وكثافته المضغوطة هو ما يبلغ الحدّ.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(flatWindowFrame));

    // النصّ نفسه في منطقة الإسقاط أيضًا، والمقصود زرّ الشريط وحده.
    final label = tester.widget<Text>(
      find
          .descendant(
            of: find.byType(FilledButton),
            matching: find.text(
              L.of(tester.element(find.byType(WorkspaceScreen))).chooseFile,
            ),
          )
          .first,
    );
    expect(
      label.overflow,
      equals(TextOverflow.visible),
      reason: 'القصّ يبتر ذيل الراء',
    );
  });
}
