/// مجلّد بيانات التطبيق: مسار لكل منصّة.
///
/// كان مكتوبًا بصيغة macOS وحدها في ثلاثة مواضع، فيصنع على لينكس وويندوز
/// مجلّدًا غريبًا في بيت المستخدم.
library;

import 'dart:io';

import 'package:e3ks_desktop/data/app_directory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('الجذر مطلق ويحمل اسم التطبيق', () {
    final root = appDataDirectory();
    expect(root.isAbsolute, isTrue);
    expect(root.path, endsWith('E3KS'));
  });

  test('المسار يتبع عرف المنصّة', () {
    final path = appDataDirectory().path;
    if (Platform.isMacOS) {
      expect(path, contains('Library/Application Support'));
      return;
    }
    expect(
      path,
      isNot(contains('Library/Application Support')),
      reason: 'مسار macOS لا يُفرض على غيرها',
    );
    if (Platform.isWindows) return;

    final xdg = Platform.environment['XDG_DATA_HOME'];
    expect(
      xdg == null || xdg.isEmpty
          ? path.contains('.local/share')
          : path.startsWith(xdg),
      isTrue,
      reason: path,
    );
  });
}
