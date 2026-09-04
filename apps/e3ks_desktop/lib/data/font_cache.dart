/// مخزن الخطوط المجلوبة على قرص المستخدم.
///
/// ملفّات في مجلد واحد بجوار الهويات والإعدادات، لا قاعدة بيانات: المستخدم
/// يستطيع فتح المجلد ورؤية ما لديه وحذفه بنفسه إن أراد. الشفافية أهمّ من
/// الأناقة حين يتعلّق الأمر بمساحة قرصه.
library;

import 'dart:io';
import 'dart:typed_data';

/// خطّ محفوظ محليًا.
final class CachedFont {
  const CachedFont({
    required this.family,
    required this.file,
    required this.bytes,
    required this.fetchedAt,
  });

  final String family;
  final File file;

  /// حجم الملف — يُعرَض للمستخدم كي يراقب استهلاك قرصه.
  final int bytes;

  final DateTime fetchedAt;
}

final class FontCache {
  FontCache(this.directory);

  final Directory directory;

  static Future<FontCache> open() async {
    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final directory = Directory('$home/Library/Application Support/E3KS/fonts');
    if (!directory.existsSync()) directory.createSync(recursive: true);
    return FontCache(directory);
  }

  /// اسم ملف آمن من اسم عائلة قد يحوي مسافات أو محارف نظام.
  /// النطاق بهروب Unicode لا بمحارف حرفية: أوضح، ولا يلتبس بنصّ معروض.
  String _slug(String family) => family.trim().replaceAll(
    RegExp('[^A-Za-z0-9\\u0600-\\u06FF\\u0750-\\u077F]+'),
    '_',
  );

  File fileFor(String family) => File('${directory.path}/${_slug(family)}.ttf');

  bool has(String family) => fileFor(family).existsSync();

  Uint8List? read(String family) {
    final file = fileFor(family);
    return file.existsSync() ? file.readAsBytesSync() : null;
  }

  Future<void> write(String family, List<int> bytes) async {
    // كتابة ذرّية: مؤقّت ثم إعادة تسمية — نفس مبدأ المخرجات (`00` §١/٣).
    final target = fileFor(family);
    final temp = File('${target.path}.part')..writeAsBytesSync(bytes);
    temp.renameSync(target.path);
  }

  List<CachedFont> list() {
    final items = <CachedFont>[];
    for (final entity in directory.listSync()) {
      if (entity is! File || !entity.path.endsWith('.ttf')) continue;
      final stat = entity.statSync();
      items.add(
        CachedFont(
          family: entity.path.split('/').last.replaceAll('.ttf', ''),
          file: entity,
          bytes: stat.size,
          fetchedAt: stat.modified,
        ),
      );
    }
    items.sort((a, b) => b.bytes.compareTo(a.bytes));
    return items;
  }

  int get totalBytes => list().fold(0, (sum, f) => sum + f.bytes);

  void delete(CachedFont font) {
    if (font.file.existsSync()) font.file.deleteSync();
  }

  void clear() {
    for (final font in list()) {
      delete(font);
    }
  }
}
