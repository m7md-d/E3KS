/// المشترك بين الصيغ في قراءة الخطوط المضمَّنة.
///
/// كل صيغة تعلن خطوطها بطريقتها — Word في `fontTable.xml` مشوَّشةً، و
/// PowerPoint في `presentation.xml` كما هي — والمشترك بينهما اثنان: تتبّع
/// العلاقة إلى جزئها، والحكم على البايتات بتوقيعها.
library;

import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../package/document_package.dart';

/// معرّف العلاقة ← اسم الجزء الكامل، لعلاقات جزءٍ داخل [baseDir].
Map<String, String> relationshipTargets(
  DocumentPackage package,
  String relsPart,
  String baseDir,
) {
  final text = package.textOf(relsPart);
  if (text == null) return const {};

  final XmlDocument rels;
  try {
    rels = XmlDocument.parse(text);
  } on XmlException {
    return const {};
  }

  final targets = <String, String>{};
  for (final rel in rels.rootElement.childElements) {
    final id = rel.getAttribute('Id');
    final target = rel.getAttribute('Target');
    if (id == null || target == null) continue;
    targets[id] = target.startsWith('/')
        ? target.substring(1)
        : '$baseDir/${target.replaceAll('../', '')}';
  }
  return targets;
}

/// بايتات صالحة للتحميل، أو `null`.
///
/// **الترتيب يُتحقَّق منه بالنتيجة لا بالنيّة.** خوارزمية Word تخالف (XOR)
/// أوّل ٣٢ بايتًا بمفتاحٍ من `w:fontKey`، وترتيب بايتات المفتاح موضع خلافٍ
/// بين التطبيقات — فنجرّب المقلوب ثم الأصل، ونقبل ما أخرج توقيع خطّ. وما
/// ليس مشوَّشًا أصلًا — كما تكتبه PowerPoint — يمرّ كما هو.
///
/// **وما لا يُفكّ يُترك.** تسجيلُ بايتاتٍ فاسدة خطًّا يرسم المستند مربّعات،
/// والسقوط إلى المسار المعتاد يرسمه بأقرب ما نملك ويقول ذلك.
Uint8List? readableFontBytes(Uint8List data, String? fontKey) {
  if (looksLikeFont(data)) return data;
  if (fontKey == null || data.length < 32) return null;

  final raw = _keyBytes(fontKey);
  if (raw == null) return null;

  for (final key in [raw.reversed.toList(), raw]) {
    final candidate = Uint8List.fromList(data);
    for (var i = 0; i < 32; i++) {
      candidate[i] ^= key[i % 16];
    }
    if (looksLikeFont(candidate)) return candidate;
  }
  return null;
}

List<int>? _keyBytes(String fontKey) {
  final hex = fontKey.replaceAll(RegExp(r'[{}\-]'), '');
  if (hex.length != 32) return null;
  final bytes = <int>[];
  for (var i = 0; i < 32; i += 2) {
    final value = int.tryParse(hex.substring(i, i + 2), radix: 16);
    if (value == null) return null;
    bytes.add(value);
  }
  return bytes;
}

/// توقيعات ملفّات الخطوط المعروفة.
bool looksLikeFont(Uint8List bytes) {
  if (bytes.length < 4) return false;
  final tag = bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3];
  return tag == 0x00010000 || // TrueType
      tag == 0x4F54544F || // 'OTTO'
      tag == 0x74727565 || // 'true'
      tag == 0x74746366; // 'ttcf'
}
