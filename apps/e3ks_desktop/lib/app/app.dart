/// جذر التطبيق.
///
/// اتجاه الكتابة يتبع اللغة تلقائيًا: عربي RTL، إنجليزي LTR. لا فرض يدوي —
/// وهذا بالضبط ما يجعل إضافة لغة ثالثة مسألة ملفّ ARB لا مسألة كود.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/font_service.dart';
import '../data/identity_store.dart';
import '../data/settings_store.dart';
import '../data/workspace_store.dart';
import '../features/workspace/workspace_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

class E3ksApp extends StatelessWidget {
  const E3ksApp({
    super.key,
    required this.store,
    required this.identities,
    required this.settings,
    required this.fonts,
  });

  final WorkspaceStore store;
  final IdentityStore identities;
  final SettingsStore settings;
  final FontService fonts;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      onGenerateTitle: (context) => L.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: settings.locale,
      supportedLocales: L.supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ListenableBuilder(
        listenable: Listenable.merge([store, identities, fonts]),
        builder: (context, _) => WorkspaceScreen(
          store: store,
          identities: identities,
          settings: settings,
          fonts: fonts,
        ),
      ),
    ),
  );
}
