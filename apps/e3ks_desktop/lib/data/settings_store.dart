/// تفضيلات المستخدم: اللغة، ومجلد الخطوط الذي يسمّيه.
///
/// ملف JSON صغير بجوار الهويات. لا حزمة تخزين: الحاجة سطران.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app_directory.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._file, this._locale, {String? fontFolder})
    : _fontFolder = fontFolder;

  final File _file;
  Locale _locale;
  String? _fontFolder;

  Locale get locale => _locale;

  /// مجلد خطوطٍ على قرص المستخدم، تُقرأ منه العائلات التي لا تخدمها القنوات
  /// العامّة. `null` إن لم يختر شيئًا.
  String? get fontFolder => _fontFolder;

  static const List<Locale> supported = [Locale('ar'), Locale('en')];

  static Future<SettingsStore> open() async {
    final file = File('${appDataRoot().path}/settings.json');
    var locale = _systemDefault();
    String? folder;
    if (file.existsSync()) {
      try {
        final data = jsonDecode(await file.readAsString());
        final code = data is Map ? data['locale'] as String? : null;
        if (code != null && supported.any((l) => l.languageCode == code)) {
          locale = Locale(code);
        }
        folder = data is Map ? data['fontFolder'] as String? : null;
      } on Object {
        // ملف تالف لا يمنع التشغيل — نعود إلى لغة النظام.
      }
    }
    return SettingsStore(file, locale, fontFolder: folder);
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
    await _save();
  }

  /// يبدّل مجلد الخطوط، أو يرفعه بـ`null`.
  Future<void> setFontFolder(String? path) async {
    final value = (path == null || path.isEmpty) ? null : path;
    if (value == _fontFolder) return;
    _fontFolder = value;
    notifyListeners();
    await _save();
  }

  /// **الملف يُكتب كاملًا في كل مرّة.** كتابة مفتاحٍ واحد تمسح ما سواه، وهو
  /// ما كان يُسقط اللغة كلّما تغيّر غيرها.
  Future<void> _save() => _file.writeAsString(
    jsonEncode({
      'locale': _locale.languageCode,
      if (_fontFolder != null) 'fontFolder': _fontFolder,
    }),
  );
}
