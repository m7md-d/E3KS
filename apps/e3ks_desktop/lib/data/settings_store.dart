/// تفضيلات المستخدم — حاليًا اللغة فقط.
///
/// ملف JSON صغير بجوار الهويات. لا حزمة تخزين: الحاجة سطران.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app_directory.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._file, this._locale);

  final File _file;
  Locale _locale;

  Locale get locale => _locale;

  static const List<Locale> supported = [Locale('ar'), Locale('en')];

  static Future<SettingsStore> open() async {
    final file = File('${appDataRoot().path}/settings.json');
    var locale = _systemDefault();
    if (file.existsSync()) {
      try {
        final data = jsonDecode(await file.readAsString());
        final code = data is Map ? data['locale'] as String? : null;
        if (code != null && supported.any((l) => l.languageCode == code)) {
          locale = Locale(code);
        }
      } on Object {
        // ملف تالف لا يمنع التشغيل — نعود إلى لغة النظام.
      }
    }
    return SettingsStore(file, locale);
  }

  /// أول تشغيل: نتبع لغة النظام إن كانت مدعومة، وإلّا العربية.
  static Locale _systemDefault() {
    final system = Platform.localeName.split(RegExp('[_-]')).first;
    return supported.any((l) => l.languageCode == system)
        ? Locale(system)
        : const Locale('ar');
  }

  Future<void> setLocale(Locale value) async {
    if (value == _locale) return;
    _locale = value;
    notifyListeners();
    await _file.writeAsString(jsonEncode({'locale': value.languageCode}));
  }
}
