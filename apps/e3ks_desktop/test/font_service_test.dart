/// نظام خطوط المستندات: الحلّ، والجلب، والحفظ، والإبلاغ عند الفشل.
///
/// **لا اتصال شبكة في أي اختبار.** الجالب مُبدَّل بمزيّف، فالاختبار يقيس
/// منطقنا لا صحّة الإنترنت.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_desktop/data/font_cache.dart';
import 'package:e3ks_desktop/data/font_fetcher.dart';
import 'package:e3ks_desktop/data/font_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// توقيع TTF صالح — الخدمة تفحصه قبل الحفظ.
Uint8List fakeTtf() =>
    Uint8List.fromList([0x00, 0x01, 0x00, 0x00, ...List.filled(64, 0)]);

class _FakeFetcher implements FontFetcher {
  _FakeFetcher(this.outcome, {this.bytes});
  final FetchOutcome outcome;
  final Uint8List? bytes;
  int calls = 0;

  @override
  Future<FetchResult> fetch(String family) async {
    calls++;
    return (outcome: outcome, bytes: bytes);
  }
}

late Directory _dir;
FontCache freshCache() {
  _dir = Directory.systemTemp.createTempSync('e3ks_fonts_');
  return FontCache(_dir);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    if (_dir.existsSync()) _dir.deleteSync(recursive: true);
  });

  group('الحلّ', () {
    test('الخطّ المضمَّن لا يُجلَب', () async {
      final fetcher = _FakeFetcher(FetchOutcome.notFound);
      final service = FontService(freshCache(), fetcher: fetcher);

      await service.resolveAll(['IBM Plex Sans Arabic']);

      expect(service.statuses.single.origin, equals(FontOrigin.bundled));
      expect(fetcher.calls, isZero, reason: 'طلب شبكة بلا داعٍ');
      expect(service.missing, isEmpty);
    });

    test('الخطّ المجلوب يُحفَظ على القرص ويُحمَّل', () async {
      final fetcher = _FakeFetcher(FetchOutcome.fetched, bytes: fakeTtf());
      final cache = freshCache();
      final service = FontService(cache, fetcher: fetcher);

      await service.resolveAll(['Cairo']);

      expect(service.statuses.single.origin, equals(FontOrigin.fetched));
      expect(cache.has('Cairo'), isTrue, reason: 'لم يُحفَظ للمرّة القادمة');
      expect(cache.list().single.bytes, greaterThan(0));
    });

    test('المحفوظ لا يُجلَب مرّةً ثانية', () async {
      final cache = freshCache();
      await cache.write('Tajawal', fakeTtf());
      final fetcher = _FakeFetcher(FetchOutcome.fetched, bytes: fakeTtf());

      await FontService(cache, fetcher: fetcher).resolveAll(['Tajawal']);

      expect(fetcher.calls, isZero, reason: 'جلبناه ونحن نملكه');
    });

    test('كل خطّ يُحلّ مرّة واحدة مهما تكرّر', () async {
      final fetcher = _FakeFetcher(FetchOutcome.notFound);
      final service = FontService(freshCache(), fetcher: fetcher);

      await service.resolveAll(['Calibri', 'Calibri']);
      await service.resolveAll(['Calibri']);

      expect(fetcher.calls, equals(1));
    });
  });

  group('الإبلاغ عند التعذّر', () {
    test('خطّ غير موجود في المصدر يُعلَن ولا يُبتلع', () async {
      // خطوط Office التجارية ليست على Google Fonts. الصمت هنا يجعل
      // المعاينة كاذبة (`00` §5).
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      await service.resolveAll(['Calibri']);

      expect(service.missing.single.family, equals('Calibri'));
      expect(service.missing.single.origin, equals(FontOrigin.unavailable));
    });

    test('انقطاع الشبكة يُميَّز عن الخطّ المفقود', () async {
      // الرسالتان مختلفتان: «أعِد المحاولة» غير «لن يعمل أبدًا».
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.offline),
      );

      await service.resolveAll(['Cairo']);

      expect(service.missing.single.origin, equals(FontOrigin.offline));
    });

    test('إطفاء الجلب يمنع الطلب ويُعلَن سببًا', () async {
      final fetcher = _FakeFetcher(FetchOutcome.fetched, bytes: fakeTtf());
      final service = FontService(freshCache(), fetcher: fetcher)
        ..fetchEnabled = false;

      await service.resolveAll(['Cairo']);

      expect(fetcher.calls, isZero, reason: 'طلب شبكة رغم الإطفاء');
      expect(service.missing.single.origin, equals(FontOrigin.disabled));
    });

    test('إعادة التشغيل تُعيد تقييم ما تعذّر', () async {
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.fetched, bytes: fakeTtf()),
      )..fetchEnabled = false;
      await service.resolveAll(['Cairo']);
      expect(service.missing, hasLength(1));

      service.setFetchEnabled(true);
      await service.resolveAll(['Cairo']);

      expect(service.missing, isEmpty);
    });

    test('المتعذّر يتصدّر القائمة', () async {
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      await service.resolveAll(['Calibri', 'IBM Plex Sans Arabic']);

      expect(
        service.statuses.first.origin.isResolved,
        isFalse,
        reason: 'ما يهمّ المستخدم يجب أن يظهر أولًا',
      );
    });
  });

  group('قراءة ورقة أنماط Google', () {
    // خللٌ حقيقي: كان الشرط أن ينتهي الرابط بـ`.ttf`، فقال التطبيق «غير
    // متاح» عن أربعة خطوط من ستّة يستطيع جلبها. لا شبكة هنا — نصّ ثابت
    // منسوخ من ردّ الخدمة.
    test('الرابط المنتهي بـ.ttf يُقرأ', () {
      const css = """
@font-face {
  font-family: 'IBM Plex Sans';
  src: url(https://fonts.gstatic.com/s/ibmplexsans/v23/zYXGKVElMYY.ttf) format('truetype');
}""";
      expect(
        ttfUrlFromCss(css),
        equals('https://fonts.gstatic.com/s/ibmplexsans/v23/zYXGKVElMYY.ttf'),
      );
    });

    test('الرابط بلا امتداد يُقرأ أيضًا — وهذا هو الخلل الذي وقع', () {
      // ما تخدمه Google بدل خطوط Microsoft: مكافئ مقاسيًّا من `/l/font`.
      const css = """
@font-face {
  font-family: 'Calibri';
  src: url(https://fonts.gstatic.com/l/font?kit=J7afnpV-BGl&skey=a10&v=v15) format('truetype');
}""";
      expect(
        ttfUrlFromCss(css),
        equals(
          'https://fonts.gstatic.com/l/font?kit=J7afnpV-BGl&skey=a10&v=v15',
        ),
      );
    });

    test('صيغة غير truetype تُرفض — Flutter لا يقرأ woff2', () {
      const css =
          "src: url(https://fonts.gstatic.com/s/a/b.woff2) format('woff2');";
      expect(ttfUrlFromCss(css), isNull);
    });

    test('ردّ فارغ أو رسالة خطأ لا تُنتج رابطًا', () {
      expect(ttfUrlFromCss(''), isNull);
      expect(ttfUrlFromCss('Not Found'), isNull);
    });
  });

  group('لاحقة النمط داخل اسم العائلة', () {
    test('تُجرَّد حين يبقى بعدها اسم عائلة', () {
      // Word يكتب «IBM Plex Sans Light»، وGoogle تعرف «IBM Plex Sans».
      expect(
        familyWithoutStyleSuffix('IBM Plex Sans Light'),
        equals('IBM Plex Sans'),
      );
      expect(
        familyWithoutStyleSuffix('Noto Naskh Arabic SemiBold'),
        equals('Noto Naskh Arabic'),
      );
    });

    test('لا تُجرَّد حين تكون هي العائلة أو نصفها', () {
      // «Light» وحده عائلة، و«Arial Black» بلا Black عائلة أخرى.
      expect(familyWithoutStyleSuffix('Light'), isNull);
      expect(familyWithoutStyleSuffix('Arial Black'), isNull);
      expect(familyWithoutStyleSuffix('Cairo'), isNull);
    });
  });

  group('المخزن', () {
    test('يحصي المساحة ويحذف ما يُطلَب', () async {
      final cache = freshCache();
      await cache.write('Cairo', fakeTtf());
      await cache.write('Tajawal', fakeTtf());

      expect(cache.list(), hasLength(2));
      expect(cache.totalBytes, greaterThan(0));

      cache.delete(cache.list().first);
      expect(cache.list(), hasLength(1));

      cache.clear();
      expect(cache.list(), isEmpty);
      expect(cache.totalBytes, isZero);
    });

    test('اسم الملف آمن مهما كان اسم العائلة', () async {
      final cache = freshCache();
      await cache.write('Noto Sans / Arabic', fakeTtf());

      expect(cache.has('Noto Sans / Arabic'), isTrue);
      expect(cache.list().single.file.path, isNot(contains('/Arabic')));
    });

    test('لا يُخزَّن ما ليس خطًّا', () async {
      // بايتات ليست TTF ⇒ الجالب يرفضها قبل أن تصل المخزن.
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.failed),
      );

      await service.resolveAll(['Cairo']);

      expect(service.cache.has('Cairo'), isFalse);
      expect(service.missing.single.origin, equals(FontOrigin.unavailable));
    });
  });
}
