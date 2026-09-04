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

const Duration _timeout = Duration(seconds: 20);

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
      final url = await _resolveTtfUrl(client, family);
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
    final match = RegExp(
      r'src:\s*url\((https://[^)]+\.ttf)\)',
    ).firstMatch(body);
    return match?.group(1);
  }

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
