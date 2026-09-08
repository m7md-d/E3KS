/// جلب ملفّ خطٍّ من Google Fonts.
///
/// **يغادر الجهاز اسم الخطّ فقط** — لا محتوى المستند ولا اسمه. ومع ذلك هو
/// طلب شبكة، فيبقى قابلًا للإيقاف من الإعدادات، ويُعلَن للمستخدم حين يفشل.
///
/// بلا حزمة: `HttpClient` من نواة Dart. وبلا مفتاح: الخدمة عامة.
library;

import 'dart:io';
import 'dart:typed_data';

/// وكيل قديم عمدًا: Google تُرجع `woff2` للمتصفّحات الحديثة، و`ttf` لما
/// دونها. وFlutter لا يقرأ `woff2`.
const String _legacyAgent = 'Mozilla/4.0';

const Duration _timeout = Duration(seconds: 20); // e3ks:not-motion

enum FetchOutcome { fetched, notFound, offline, failed }

typedef FetchResult = ({FetchOutcome outcome, Uint8List? bytes});

/// واجهة الجلب. مفصولة عن تنفيذها كي يُبدَّل في الاختبار —
/// اختبارٌ يتصل بالإنترنت يقيس صحّة الشبكة لا صحّة كودنا.
abstract interface class FontFetcher {
  Future<FetchResult> fetch(String family);
}

final class GoogleFontFetcher implements FontFetcher {
  const GoogleFontFetcher();

  @override
  Future<FetchResult> fetch(String family) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      // Word يكتب اسم النمط داخل اسم العائلة («IBM Plex Sans Light»)، وGoogle
      // تعرف العائلة وحدها. نجرّب المكتوب أولًا ثم المجرَّد من لاحقة النمط.
      var url = await _resolveTtfUrl(client, family);
      final bare = familyWithoutStyleSuffix(family);
      if (url == null && bare != null) {
        url = await _resolveTtfUrl(client, bare);
      }
      if (url == null) return (outcome: FetchOutcome.notFound, bytes: null);

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200) {
        return (outcome: FetchOutcome.failed, bytes: null);
      }

      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      final bytes = Uint8List.fromList(chunks);
      // فحص بسيط: كل TTF/OTF يبدأ بتوقيع معروف.
      if (!_looksLikeFont(bytes)) {
        return (outcome: FetchOutcome.failed, bytes: null);
      }
      return (outcome: FetchOutcome.fetched, bytes: bytes);
    } on SocketException {
      return (outcome: FetchOutcome.offline, bytes: null);
    } on Object {
      return (outcome: FetchOutcome.failed, bytes: null);
    } finally {
      client.close(force: true);
    }
  }

  /// يسأل واجهة الأنماط عن رابط الملفّ، ويستخرجه من `src: url(...)`.
  Future<String?> _resolveTtfUrl(HttpClient client, String family) async {
    final encoded = Uri.encodeComponent(family.trim());
    final uri = Uri.parse(
      'https://fonts.googleapis.com/css2?family=$encoded:wght@400',
    );

    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, _legacyAgent);
    final response = await request.close().timeout(_timeout);

    // 400 من هذه الواجهة تعني «لا عائلة بهذا الاسم».
    if (response.statusCode != 200) return null;

    final body = await response
        .transform(const SystemEncoding().decoder)
        .join();

    return ttfUrlFromCss(body);
  }

  /// لاحقات **الأنماط** التي يلحقها Word باسم العائلة. تُجرَّد دائمًا:
  /// «Calibri Light» عائلتها Calibri، و«Light» وحدها ليست لاحقةً لشيء.
  static const List<String> styleSuffixes = [
    'Extra Light',
    'ExtraLight',
    'SemiBold',
    'Semi Bold',
    'DemiBold',
    'Demi Bold',
    'ExtraBold',
    'Extra Bold',
    'UltraLight',
    'Ultra Light',
    'Thin',
    'Light',
    'Regular',
    'Medium',
    'Bold',
    'Heavy',
    'Italic',
    'Oblique',
  ];

  /// لاحقاتٌ **تصنع عائلةً مستقلّة** حين تلتصق باسمٍ من كلمة واحدة:
  /// «Arial Black» و«Arial Narrow» غير Arial، و«Arial» بلا اللاحقة خطٌّ آخر.
  /// فلا تُجرَّد إلا إن بقي بعدها اسمٌ من كلمتين («IBM Plex Sans Condensed»).
  static const List<String> familySuffixes = [
    'Condensed',
    'Narrow',
    'Display',
    'Text',
    'Caption',
    'Black',
  ];

  bool _looksLikeFont(Uint8List bytes) {
    if (bytes.length < 4) return false;
    final tag = bytes.sublist(0, 4);
    const ttf = [0x00, 0x01, 0x00, 0x00];
    const otto = [0x4F, 0x54, 0x54, 0x4F]; // 'OTTO'
    const true_ = [0x74, 0x72, 0x75, 0x65]; // 'true'
    for (final signature in [ttf, otto, true_]) {
      var ok = true;
      for (var i = 0; i < 4; i++) {
        if (tag[i] != signature[i]) ok = false;
      }
      if (ok) return true;
    }
    return false;
  }
}

/// رابط ملفّ TrueType من ورقة أنماط Google Fonts.
///
/// **لا يُشترَط أن ينتهي الرابط بـ`.ttf`.** الخطوط المكافئة مقاسيًّا التي
/// تخدمها Google بدل خطوط Microsoft (Calibri و Cambria و MS Gothic و
/// Courier …) تأتي من `/l/font?kit=…` بلا امتداد أصلًا. اشتراط الامتداد كان
/// يجعل التطبيق يقول «غير متاح» عن أربعة خطوط من ستّة **يستطيع جلبها فعلًا**،
/// وهذا أسوأ من العجز: عجزٌ يدّعي معرفة سببه.
///
/// المعيار الصحيح ما تعلنه الورقة عن الملفّ: `format('truetype')`.
String? ttfUrlFromCss(String css) => RegExp(
  r"url\((https?://[^)]+)\)\s*format\('truetype'\)",
).firstMatch(css)?.group(1);

/// الاسم بلا لاحقة النمط، أو `null` إن لم تكن فيه لاحقة.
///
/// Word يكتب النمط داخل اسم العائلة («Calibri Light»)، وGoogle تعرف العائلة
/// وحدها. وهذه محاولة **ثانية** بعد فشل الاسم كما كُتب، لا استبدال له.
///
/// **واشتراط بقاء كلمتين كان يقطع الطريق على أشهرها.** ‏«Calibri Light» يبقى
/// منها «Calibri» كلمةً واحدة، فكانت تُردّ — و Google تخدم «Calibri» ولا
/// تخدم «Calibri Light» (مقيسًا: 200 مقابل 400). فصار الشرط على اللاحقة لا
/// على عدد الكلمات: لاحقةُ النمط تُجرَّد دائمًا، ولاحقةٌ تصنع عائلةً مستقلّة
/// («Arial Black») لا تُجرَّد إلا إن بقي بعدها اسمٌ من كلمتين.
String? familyWithoutStyleSuffix(String family) {
  final trimmed = family.trim();
  for (final suffix in GoogleFontFetcher.styleSuffixes) {
    final bare = _strip(trimmed, suffix);
    if (bare != null) return bare;
  }
  for (final suffix in GoogleFontFetcher.familySuffixes) {
    final bare = _strip(trimmed, suffix);
    if (bare != null && bare.contains(' ')) return bare;
  }
  return null;
}

String? _strip(String family, String suffix) {
  if (!family.toLowerCase().endsWith(' ${suffix.toLowerCase()}')) return null;
  final bare = family.substring(0, family.length - suffix.length - 1).trim();
  return bare.isEmpty ? null : bare;
}

/// هل يعلن الخطّ نفسه أنه تحت رخصة SIL Open Font License؟
///
/// **يحرس ما نشحنه، لا ما نجلبه.** شحن خطٍّ داخل حزمتنا إلى كل مستخدم توزيعٌ
/// يحتاج رخصةً تجيزه، و OFL وحدها تجيزه هنا. أمّا جلب خطّ ويب إلى قرص من
/// طلبه فهو ما يفعله كل متصفّح مع كل صفحة، ولا شأن لنا به.
///
/// يقرأ الاسمين 13 (نصّ الرخصة) و14 (رابطها) من جدول `name` في OpenType،
/// ويستعمله اختبارٌ يمرّ على كل ملفّ في `assets/fonts`.
bool isOpenFontLicensed(Uint8List bytes) {
  final name = _nameTable(bytes, const {13, 14});
  if (name == null) return false;
  final text = (name[13] ?? '').toLowerCase();
  final url = (name[14] ?? '').toLowerCase();
  return text.contains('sil open font license') ||
      text.contains('openfontlicense') ||
      url.contains('scripts.sil.org/ofl') ||
      url.contains('openfontlicense.org');
}

/// اسم العائلة كما يعلنه الخطّ عن نفسه، أو `null` إن تعذّرت قراءته.
///
/// يلزمنا حين **يرفع المستخدم ملفّ خطّ من قرصه**: اسم الملفّ ليس اسم العائلة
/// («Cairo-Regular.ttf» عائلتها «Cairo»)، وتسجيلها باسم الملفّ يجعل المستند
/// الذي يطلب «Cairo» لا يجدها.
///
/// يفضّل الاسم 16 (العائلة الطباعية) على 1، فالثاني يدمج النمط في الاسم حين
/// تتجاوز العائلةُ أربعةَ أنماط («Inter Light» بدل «Inter»).
String? fontFamilyName(Uint8List bytes) {
  final name = _nameTable(bytes, const {1, 16});
  final family = name?[16] ?? name?[1];
  final trimmed = family?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// مُدخَلات جدول `name` المطلوبة، أو `null` إن تعذّرت القراءة.
///
/// جدول `name` في OpenType: ترويسة، ثم سجلّ لكل اسم، ثم منطقة تخزين النصوص.
Map<int, String>? _nameTable(Uint8List bytes, Set<int> wanted) {
  final data = ByteData.sublistView(bytes);
  int u16(int at) => data.getUint16(at);
  int u32(int at) => data.getUint32(at);

  try {
    final tables = u16(4);
    var nameOffset = -1;
    for (var i = 0; i < tables; i++) {
      final entry = 12 + 16 * i;
      final tag = String.fromCharCodes(bytes, entry, entry + 4);
      if (tag == 'name') {
        nameOffset = u32(entry + 8);
        break;
      }
    }
    if (nameOffset < 0) return null;

    final count = u16(nameOffset + 2);
    final storage = nameOffset + u16(nameOffset + 4);
    final out = <int, String>{};
    for (var i = 0; i < count; i++) {
      final record = nameOffset + 6 + 12 * i;
      final platform = u16(record);
      final nameId = u16(record + 6);
      if (!wanted.contains(nameId)) continue;
      final length = u16(record + 8);
      final at = storage + u16(record + 10);
      if (at + length > bytes.length) return null;
      final raw = bytes.sublist(at, at + length);
      // المنصّة 3 (Windows) تكتب UTF-16BE، وما عداها بايتًا للمحرف.
      final value = platform == 3
          ? String.fromCharCodes([
              for (var j = 0; j + 1 < raw.length; j += 2)
                (raw[j] << 8) | raw[j + 1],
            ])
          : String.fromCharCodes(raw);
      out.putIfAbsent(nameId, () => value);
    }
    return out;
  } on RangeError {
    return null;
  }
}
