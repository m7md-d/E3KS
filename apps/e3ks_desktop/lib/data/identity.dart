/// الهوية البصرية: ألوان مسمّاة + خطوط + استثناءات.
///
/// ملف JSON يقرأه الإنسان ويشاركه مع زميله — لا قاعدة بيانات مبهمة.
library;

import 'dart:convert';

import 'package:e3ks_engine/e3ks_engine.dart';

final class NamedColor {
  const NamedColor({required this.name, required this.hex});
  final String name;
  final HexColor hex;

  Map<String, Object?> toJson() => {'name': name, 'hex': hex.value};

  static NamedColor? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final hex = HexColor.tryParse(raw['hex'] as String?);
    if (hex == null) return null;
    return NamedColor(name: (raw['name'] as String?) ?? hex.value, hex: hex);
  }
}

final class Identity {
  const Identity({
    required this.name,
    this.colors = const [],
    this.latinFont,
    this.arabicFont,
    this.preserveFonts = const [],
  });

  final String name;
  final List<NamedColor> colors;
  final String? latinFont;
  final String? arabicFont;
  final List<String> preserveFonts;

  Map<String, Object?> toJson() => {
    'name': name,
    'colors': [for (final c in colors) c.toJson()],
    'fonts': {'latin': latinFont, 'arabic': arabicFont},
    'preserveFonts': preserveFonts,
  };

  static Identity? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name'] as String?;
    if (name == null || name.isEmpty) return null;
    final fonts = raw['fonts'];
    return Identity(
      name: name,
      colors: [
        for (final item in (raw['colors'] as List? ?? const []))
          ?NamedColor.fromJson(item),
      ],
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
