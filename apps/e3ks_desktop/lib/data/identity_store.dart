/// تخزين الهويات كملفات JSON في مجلد المستخدم.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_directory.dart';
import 'identity.dart';

class IdentityStore extends ChangeNotifier {
  IdentityStore(this._directory);

  final Directory _directory;
  final List<Identity> _items = [];

  List<Identity> get items => List.unmodifiable(_items);

  static Future<IdentityStore> open() async {
    final store = IdentityStore(appDataSubdirectory('identities'));
    await store.reload();
    return store;
  }

  Future<void> reload() async {
    _items.clear();
    for (final entity in _directory.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final identity = Identity.fromJson(
          jsonDecode(await entity.readAsString()),
        );
        if (identity != null) _items.add(identity);
      } on Object {
        // ملف تالف لا يمنع تحميل البقية.
        continue;
      }
    }
    _items.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> save(Identity identity) async {
    await File(
      '${_directory.path}/${_slug(identity.name)}.json',
    ).writeAsString(identity.encode());
    await reload();
  }

  Future<void> delete(Identity identity) async {
    final file = File('${_directory.path}/${_slug(identity.name)}.json');
    if (file.existsSync()) file.deleteSync();
    await reload();
  }

  /// اسم ملف آمن من اسم عربي أو إنجليزي.
  String _slug(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'identity' : cleaned;
  }
}
