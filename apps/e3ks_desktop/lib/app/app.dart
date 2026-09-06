/// جذر التطبيق: الدخول، ثم مساحة العمل.
///
/// اتجاه الكتابة يتبع اللغة تلقائيًا: عربي RTL، إنجليزي LTR. لا فرض يدوي —
/// وهذا بالضبط ما يجعل إضافة لغة ثالثة مسألة ملفّ ARB لا مسألة كود.
///
/// **التهيئة تجري والشاشة معروضة، لا قبلها.** فتح الإعدادات والهويات ومخزن
/// الخطوط يقرأ من القرص؛ لو انتظرناه قبل `runApp` لبقيت النافذة بيضاء
/// فارغة بلا تفسير. شاشة الدخول تشغل تلك اللحظة وتفسّرها.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/font_cache.dart';
import '../data/font_service.dart';
import '../data/identity_store.dart';
import '../data/settings_store.dart';
import '../data/window_frame.dart';
import '../data/workspace_store.dart';
import '../features/splash/splash_view.dart';
import '../features/workspace/workspace_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// اسم التطبيق كعلامة: يظهر قبل تحميل الترجمة، ولا يُترجَم أصلًا.
const String _wordmark = 'E3KS'; // e3ks:not-ui

/// ما تحتاجه الواجهة، جاهزًا.
typedef AppServices = ({
  SettingsStore settings,
  IdentityStore identities,
  FontService fonts,
  WindowFrameWatch frame,
});

Future<AppServices> openServices() async => (
  settings: await SettingsStore.open(),
  identities: await IdentityStore.open(),
  fonts: FontService(await FontCache.open()),
  // ويبقى مصغيًا: ملء الشاشة يُخفي أزرار النظام، فيسقط حجزها معها.
  frame: await _openFrame(),
);

/// يقرأ القياس الأول قبل أوّل رسمة: بدء الحجز صفرًا ثم قفزه بعد لحظة
/// يُري المستخدم شريطًا ينزلق تحته المحتوى بلا سبب ظاهر.
Future<WindowFrameWatch> _openFrame() async {
  final watch = WindowFrameWatch();
  await watch.start();
  return watch;
}

class E3ksApp extends StatefulWidget {
  const E3ksApp({super.key, this.services});

  /// خدمات جاهزة — للاختبارات. `null` يعني «افتحها بنفسك واعرض شاشة الدخول».
  final AppServices? services;

  @override
  State<E3ksApp> createState() => _E3ksAppState();
}

class _E3ksAppState extends State<E3ksApp> {
  final WorkspaceStore _store = WorkspaceStore();
  AppServices? _services;

  @override
  void initState() {
    super.initState();
    _services = widget.services;
    if (_services == null) _boot();
  }

  Future<void> _boot() async {
    // **حدٌّ أدنى لزمن العرض.** التهيئة قد تنتهي في عشرين جزءًا من الثانية،
    // وشعارٌ يومض ويختفي أسوأ من ألّا يظهر.
    //
    // نبدأ الفتح **قبل** الانتظار، فيجريان معًا وننتظر الأبطأ منهما لا
    // مجموعهما. عكس الترتيب يجعل كل تشغيل أطول بلا فائدة.
    final opening = openServices();
    await Future<void>.delayed(Motion.entrance);
    final opened = await opening;
    if (!mounted) return;
    setState(() => _services = opened);
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (services == null) {
      return const _Shell(child: SplashView(name: _wordmark));
    }

    return ListenableBuilder(
      listenable: services.settings,
      builder: (context, _) => _Shell(
        locale: services.settings.locale,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            _store,
            services.identities,
            services.fonts,
            services.frame,
          ]),
          builder: (context, _) => WorkspaceScreen(
            store: _store,
            identities: services.identities,
            settings: services.settings,
            fonts: services.fonts,
            frame: services.frame.value,
          ),
        ),
      ),
    );
  }
}

/// غلاف واحد للحالتين، فيبقى `MaterialApp` واحدًا ويصير الانتقال بينهما
/// تلاشيًا لا قطعًا.
class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.locale});

  final Widget child;
  final Locale? locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => L.of(context).appName,
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: locale,
    supportedLocales: L.supportedLocales,
    localizationsDelegates: const [
      L.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AnimatedSwitcher(
      duration: Motion.slow,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      child: child,
    ),
  );
}
