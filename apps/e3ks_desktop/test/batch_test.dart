/// الدفعة: العثور على المستندات، وتشغيلها، وحوارها.
library;

import 'dart:io';

import 'package:e3ks_desktop/app/theme.dart';
import 'package:e3ks_desktop/data/batch_runner.dart';
import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:e3ks_desktop/data/identity_store.dart';
import 'package:e3ks_desktop/data/settings_store.dart';
import 'package:e3ks_desktop/data/workspace_store.dart';
import 'package:e3ks_desktop/features/workspace/workspace_screen.dart';
import 'package:e3ks_desktop/l10n/app_localizations.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _demo = '../../docs/demo/brand-guidelines.docx';

/// `!` مضمون: القيم أدناه بصيغة `#RRGGBB` صحيحة.
HexColor hex(String value) => HexColor.tryParse(value)!;

Directory _tempTree() {
  final root = Directory.systemTemp.createTempSync('e3ks_batch_');
  Directory('${root.path}/عروض').createSync();
  File('${root.path}/أول.docx').writeAsStringSync('x');
  File('${root.path}/عروض/ثانٍ.pptx').writeAsStringSync('x');
  // ما يجب أن يُتخطّى: قفل Word، ومخفيّ، وغير مدعوم.
  File(
    r'${root.path}/~$أول.docx'.replaceAll(r'${root.path}', root.path),
  ).writeAsStringSync('x');
  File('${root.path}/.مخفي.docx').writeAsStringSync('x');
  File('${root.path}/ملاحظات.txt').writeAsStringSync('x');
  return root;
}

void main() {
  test('البحث يجد المدعوم وحده، ويحفظ المسار النسبي', () {
    final root = _tempTree();
    addTearDown(() => root.deleteSync(recursive: true));

    final found = findDocuments(root);
    expect(
      found.map((f) => f.relative),
      equals(['أول.docx', 'عروض/ثانٍ.pptx']),
    );
    expect(found.first.path, startsWith(root.absolute.path));
  });

  test(
    'التشغيل يكتب المخرَجات بالبنية نفسها، والساقط لا يوقف البقيّة',
    () async {
      final demo = File(_demo);
      if (!demo.existsSync()) {
        markTestSkipped('لا يوجد مستند العرض');
        return;
      }

      final source = Directory.systemTemp.createTempSync('e3ks_batch_in_');
      final out = Directory.systemTemp.createTempSync('e3ks_batch_out_');
      addTearDown(() {
        source.deleteSync(recursive: true);
        out.deleteSync(recursive: true);
      });

      Directory('${source.path}/قسم').createSync();
      demo.copySync('${source.path}/قسم/دليل.docx');
      File('${source.path}/تالف.docx').writeAsBytesSync([1, 2, 3]);

      final report = await runBatch(
        files: findDocuments(source),
        outDirectory: out.path,
        plan: StylePlan(colors: {hex('#1F3864'): hex('#0F3D3E')}),
      );

      expect(report.written.map((e) => e.name), equals(['قسم/دليل.docx']));
      expect(report.failed.map((e) => e.name), equals(['تالف.docx']));
      expect(File('${out.path}/قسم/دليل.docx').existsSync(), isTrue);
      // الساقط لا يُكتب، ولا يبقى ملفّ مؤقّت وراءه.
      expect(File('${out.path}/تالف.docx').existsSync(), isFalse);
      expect(
        out.listSync(recursive: true).where((e) => e.path.endsWith('.part')),
        isEmpty,
      );
    },
  );

  testWidgets('حوار الدفعة يفتح عند أضيق نافذة بلا تجاوز', (tester) async {
    // أضيق نافذة مسموحة، وهي أكثر ما ينكسر عمليًّا (`03`).
    await tester.binding.setSurfaceSize(const Size(1180, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = WorkspaceStore();
    await tester.pumpWidget(
      MaterialApp(
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
          store: store,
          identities: IdentityStore(Directory.systemTemp),
          fonts: FontService(FontCache(Directory.systemTemp))
            ..fetchEnabled = false,
          settings: SettingsStore(
            File('${Directory.systemTemp.path}/e3ks_batch_ui.json'),
            const Locale('ar'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(LucideIcons.folders));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
