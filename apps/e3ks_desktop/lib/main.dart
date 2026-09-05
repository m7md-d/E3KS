// E3KS — اعكس. تطبيق سطح مكتب لعكس الهوية البصرية في المستندات.
// Copyright (C) 2026  m7md-d
//
// برنامج حرّ تحت رخصة جنو العمومية العامة، الإصدار الثالث أو أيّ إصدار
// لاحق. يُوزَّع بلا أيّ ضمان. النصّ الكامل في `LICENSE` بجذر المشروع.
import 'package:flutter/material.dart';

import 'app/about.dart';
import 'app/app.dart';
import 'data/font_cache.dart';
import 'data/font_service.dart';
import 'data/identity_store.dart';
import 'data/settings_store.dart';
import 'data/workspace_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledLicenses();
  final settings = await SettingsStore.open();
  final identities = await IdentityStore.open();
  final fonts = FontService(await FontCache.open());
  runApp(
    E3ksApp(
      store: WorkspaceStore(),
      identities: identities,
      settings: settings,
      fonts: fonts,
    ),
  );
}
