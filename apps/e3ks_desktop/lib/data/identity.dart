/// الهوية البصرية: ألوان مسمّاة + خطوط + استثناءات.
///
/// ملف JSON يقرأه الإنسان ويشاركه مع زميله — لا قاعدة بيانات مبهمة.
///
/// **وفيه ثلاثة حقول لا يستغني عنها العمل بالدفعة:**
///
/// `version` ليصير أي تغيير لاحق في الشكل ترحيلًا لا كسرًا.
///
/// `role` لأن التوزيع بأقرب إضاءة تخمينٌ يعمل تحت عين المستخدم على ملف
/// واحد، ويُنتج في أربعين ملفًا أربعين توزيعًا لا يراجعها أحد.
///
/// `map` لأنه الوحيد الذي يجعل الملف الحادي والأربعين يخرج مطابقًا للأربعين
/// قبله: قاعدة صريحة «هذا اللون القديم يصير هذا»، لا ترجيحًا يُعاد حسابه.
///
/// وكلها اختيارية: ملفٌ قديم بلا أيٍّ منها يُقرأ ويعمل كما كان.
library;

import 'dart:convert';

import 'package:e3ks_engine/e3ks_engine.dart';

/// شكل ملف الهوية. يرتفع حين يتغيّر الشكل بما يحتاج ترحيلًا.
const int currentIdentityVersion = 1;

/// دور اللون **في الهوية**.
///
/// ليس `ColorRole` من المحرّك: ذاك يصف أين يظهر اللون في المستند (نصّ،
/// تعبئة، حدّ)، وهذا يصف ما يمثّله في الهوية. الخلط بينهما يجعل «لون نصّ
/// في جدول» و«لون النصّ الأساسي» شيئًا واحدًا، وهما ليسا كذلك.
enum IdentityRole { primary, secondary, accent, surface, text, other }

IdentityRole _roleFrom(Object? raw) {
  if (raw is! String) return IdentityRole.other;
  for (final role in IdentityRole.values) {
    if (role.name == raw) return role;
  }
  return IdentityRole.other;
}

final class NamedColor {
  const NamedColor({
    required this.name,
    required this.hex,
    this.role = IdentityRole.other,
  });

  final String name;
  final HexColor hex;
  final IdentityRole role;

  Map<String, Object?> toJson() => {
    'name': name,
    'hex': hex.value,
    // الدور المجهول لا يُكتب: حقلٌ بقيمة «غير معروف» ضجيج في ملف يُقرأ.
    if (role != IdentityRole.other) 'role': role.name,
  };

  static NamedColor? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final hex = HexColor.tryParse(raw['hex'] as String?);
    if (hex == null) return null;
    return NamedColor(
      name: (raw['name'] as String?) ?? hex.value,
      hex: hex,
      role: _roleFrom(raw['role']),
    );
  }
}

final class Identity {
  const Identity({
    required this.name,
    this.colors = const [],
    this.map = const {},
    this.latinFont,
    this.arabicFont,
    this.preserveFonts = const [],
    this.version = currentIdentityVersion,
  });

  final String name;
  final List<NamedColor> colors;

  /// قاعدة صريحة: من لون المصدر إلى بديله. تسبق أي ترجيح.
  final Map<HexColor, HexColor> map;

  final String? latinFont;
  final String? arabicFont;
  final List<String> preserveFonts;
  final int version;

  Map<String, Object?> toJson() => {
    'version': version,
    'name': name,
    'colors': [for (final c in colors) c.toJson()],
    if (map.isNotEmpty)
      'map': {for (final e in map.entries) e.key.value: e.value.value},
    'fonts': {'latin': latinFont, 'arabic': arabicFont},
    'preserveFonts': preserveFonts,
  };

  static Identity? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'] as String?;
    if (name == null || name.isEmpty) return null;
    final fonts = raw['fonts'];

    // ملفٌ بلا `version` من قبل هذا الحقل، وشكله هو الأول.
    final version = switch (raw['version']) {
      final int v when v > 0 => v,
      _ => 1,
    };

    final map = <HexColor, HexColor>{};
    if (raw['map'] case final Map<Object?, Object?> entries) {
      for (final entry in entries.entries) {
        final from = HexColor.tryParse(entry.key as String?);
        final to = HexColor.tryParse(entry.value as String?);
        if (from != null && to != null) map[from] = to;
      }
    }

    return Identity(
      name: name,
      version: version,
      colors: [
        for (final item in (raw['colors'] as List? ?? const []))
          ?NamedColor.fromJson(item),
      ],
      map: map,
      latinFont: fonts is Map ? fonts['latin'] as String? : null,
      arabicFont: fonts is Map ? fonts['arabic'] as String? : null,
      preserveFonts: [
        for (final item in (raw['preserveFonts'] as List? ?? const []))
          if (item is String) item,
      ],
    );
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}
