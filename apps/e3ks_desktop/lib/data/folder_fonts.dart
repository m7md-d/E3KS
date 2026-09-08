/// مجلد خطوطٍ يسمّيه المستخدم — مزوّدٌ من قرصه لا من الشبكة.
///
/// **الطريق الوحيد إلى خطٍّ مملوك يملكه هو.** ‏Segoe UI و Aptos وخطوط
/// العربية الويندوزية لا تخدمها قناة عامّة، ولا توأم مقاسيًّا لها — مقيسًا
/// بسؤال Google عن كل اسم. ومن عنده ملفّاتها بحقّه يريها للمعاينة بلا أن
/// ينصّبها على النظام.
///
/// **ولا يحكمه مفتاح الجلب.** «اجلب الخطوط الناقصة» يخصّ الطلب الخارجي،
/// وقرصُ المستخدم ليس طلبًا خارجيًا.
library;

import 'dart:io';
import 'dart:typed_data';

import 'font_fetcher.dart';

const FetchResult _none = (outcome: FetchOutcome.notFound, bytes: null);

/// امتدادات ملفّات الخطوط التي نقرؤها من المجلد.
const List<String> _extensions = ['.ttf', '.otf', '.ttc'];

final class FolderFontFetcher implements FontFetcher {
  FolderFontFetcher(this.folder);

  /// يُقرأ عند كل نداء: المستخدم يبدّل المجلد من الإعدادات بلا إعادة تشغيل.
  final String? Function() folder;

  /// اسم العائلة (بحروف صغيرة) ← مسار ملفّها.
  ///
  /// **يُبنى مرّةً لكل مجلد.** الاسم يُقرأ من داخل الملفّ لا من اسمه، وقراءة
  /// عشرات الملفّات لكل خطٍّ ناقص تُبطئ فتح كل مستند.
  Map<String, String>? _index;
  String? _indexed;

  /// آخر تعديلٍ للمجلد وقت الفهرسة — إضافةُ ملفٍّ فيه تغيّره، فيُعاد البناء
  /// بلا أن يُطلَب من المستخدم شيء.
  DateTime? _stamp;

  @override
  Future<FetchResult> fetch(String family) async {
    final path = folder();
    if (path == null || path.isEmpty) return _none;

    final index = _indexOf(path);
    final wanted = family.trim().toLowerCase();
    final match =
        index[wanted] ?? index[familyWithoutStyleSuffix(family)?.toLowerCase()];
    if (match == null) return _none;

    try {
      final bytes = Uint8List.fromList(File(match).readAsBytesSync());
      return (outcome: FetchOutcome.fetched, bytes: bytes);
    } on FileSystemException {
      // حُذف بعد الفهرسة. الفهرس يُبنى من جديد عند تبديل المجلد.
      return _none;
    }
  }

  Map<String, String> _indexOf(String path) {
    final directory = Directory(path);
    DateTime? stamp;
    try {
      stamp = directory.statSync().modified;
    } on FileSystemException {
      stamp = null;
    }
    if (_indexed == path && _stamp == stamp && _index != null) return _index!;

    final index = <String, String>{};
    if (directory.existsSync()) {
      for (final entry in directory.listSync(recursive: true)) {
        if (entry is! File) continue;
        final lower = entry.path.toLowerCase();
        if (!_extensions.any(lower.endsWith)) continue;
        try {
          final name = fontFamilyName(
            Uint8List.fromList(entry.readAsBytesSync()),
          );
          if (name != null) {
            index.putIfAbsent(name.toLowerCase(), () => entry.path);
          }
        } on FileSystemException {
          continue;
        }
      }
    }
    _index = index;
    _indexed = path;
    _stamp = stamp;
    return index;
  }

  /// يُنسي الفهرس.
  void forgetIndex() {
    _index = null;
    _indexed = null;
    _stamp = null;
  }
}
