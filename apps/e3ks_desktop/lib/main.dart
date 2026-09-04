import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/font_cache.dart';
import 'data/font_service.dart';
import 'data/identity_store.dart';
import 'data/settings_store.dart';
import 'data/workspace_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
