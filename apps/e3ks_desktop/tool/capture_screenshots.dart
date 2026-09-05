/// يلتقط لقطات الواجهة المستعمَلة في `README.md`.
///
/// ليس اختبارًا — يُشغَّل عند الحاجة وحده:
///
/// ```
/// flutter test tool/capture_screenshots.dart
/// ```
///
/// يرسم الواجهة الإنجليزية بخطّها المضمَّن على مستند العرض في
/// `docs/demo/`، ويكتب الصور في `docs/screenshots/`.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/mapping/colors_panel.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:e3ks_desktop/shared/widgets/swatch.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _demo = '../../docs/demo/brand-guidelines.docx';
const _outputDir = '../../docs/screenshots';
const _size = Size(1560, 980);

final _shot = GlobalKey();

/// الهوية الجديدة المطبَّقة في اللقطات: من الكحلي إلى الأخضر المزرقّ.
const _plan = {
  '#1F3864': '#0F3D3E',
  '#2E74B5': '#2A9D8F',
  '#C55A11': '#E76F51',
  '#F2F2F2': '#EAF4F2',
};

/// ‏`!` مضمون: القيم أعلاه مكتوبة بصيغة `#RRGGBB` صحيحة.
HexColor _hex(String value) => HexColor.tryParse(value)!;

/// جذر حزمة من `package_config.json` — أدقّ من تخمين مسار مخزن الحزم.
String _packageRoot(String name) {
  final config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map<String, Object?>;
  for (final entry in config['packages']! as List<Object?>) {
    final package = entry! as Map<String, Object?>;
    if (package['name'] != name) continue;
    final root = Uri.parse(package['rootUri']! as String);
    return root.hasScheme
        ? root.toFilePath()
        : Directory('.dart_tool').uri.resolveUri(root).toFilePath();
  }
  throw StateError(name);
}

void _addAll(FontLoader loader, Iterable<String> paths) {
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
}

/// بيئة الاختبار بلا خطوط: نحمّل خطّ الواجهة، وخطّ الأيقونات، وخطّ مستند
/// العرض — وإلا خرجت اللقطة مربّعات فارغة.
Future<void> _loadFonts() async {
  final faces = [
    for (final weight in ['Regular', 'SemiBold', 'Bold', 'ExtraLight'])
      'assets/fonts/IBMPlexSansArabic-$weight.ttf',
  ];

  final ui = FontLoader('IBM Plex Sans Arabic');
  _addAll(ui, faces);
  await ui.load();

  // خطّ المستند نفسه. على جهاز المستخدم يأتي من النظام أو من الجلب؛ هنا
  // نستعمل الوجوه المضمَّنة، وهي عائلة IBM Plex نفسها.
  final document = FontLoader('IBM Plex Sans');
  _addAll(document, faces);
  await document.load();

  final icons = FontLoader('packages/lucide_icons_flutter/Lucide');
  _addAll(icons, ['${_packageRoot('lucide_icons_flutter')}/assets/lucide.ttf']);
  await icons.load();
}

/// **الحدّ فوق `MaterialApp` لا داخله**: الحوارات تسكن في طبقة التراكب،
/// فحدٌّ داخل `home` يلتقط الشاشة بلا الحوار المفتوح فوقها.
Widget _harness(WorkspaceStore store) => RepaintBoundary(
  key: _shot,
  child: MaterialApp(
    theme: buildTheme(),
    locale: const Locale('en'),
    debugShowCheckedModeBanner: false,
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
        fonts: FontService(FontCache(Directory.systemTemp))
          ..fetchEnabled = false,
        settings: SettingsStore(
          File('${Directory.systemTemp.path}/e3ks_shots.json'),
          const Locale('en'),
        ),
      ),
    ),
  ),
);

Future<void> _write(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject(find.byKey(_shot)) as RenderRepaintBoundary;
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  image!.dispose();
  Directory(_outputDir).createSync(recursive: true);
  File('$_outputDir/$name').writeAsBytesSync(data!.buffer.asUint8List());
  stdout.writeln('  → $_outputDir/$name');
}

Future<WorkspaceStore> _open(WidgetTester tester) async {
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

void main() {
  setUpAll(_loadFonts);

  testWidgets('لقطات README', (tester) async {
    await tester.binding.setSurfaceSize(_size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = await _open(tester);
    expect(store.hasDocument, isTrue, reason: 'مستند العرض لم يُفتح');

    await tester.pumpWidget(_harness(store));
    await tester.pumpAndSettle();
    await _write(tester, '01-workspace.png');

    // منتقي البديل على لون الهوية الأساسي: سلَّم الدرجات والتباين.
    final swatches = find.descendant(
      of: find.byType(ColorsPanel),
      matching: find.byType(Swatch),
    );
    await tester.tap(swatches.at(3));
    await tester.pumpAndSettle();
    await _write(tester, '02-picker.png');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // الهوية الجديدة مطبَّقة، والمعاينة على «بعد».
    for (final entry in _plan.entries) {
      store.mapColor(_hex(entry.key), _hex(entry.value));
    }
    await tester.pumpAndSettle();
    await _write(tester, '03-after.png');
  });
}
