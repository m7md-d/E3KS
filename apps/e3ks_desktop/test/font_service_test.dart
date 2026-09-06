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
import 'package:e3ks_desktop/data/font_substitutes.dart';

/// توقيع TTF صالح — الخدمة تفحصه قبل الحفظ.
Uint8List fakeTtf() =>
    Uint8List.fromList([0x00, 0x01, 0x00, 0x00, ...List.filled(64, 0)]);

/// خطّ مصطنع يحمل نصّ رخصة في جدول `name` (الاسم 13).
Uint8List ttfWithLicense(String license) => ttfWithName(13, license);

/// خطّ مصطنع يحمل اسمًا واحدًا في جدول `name`.
///
/// نبنيه بايتًا ببايت بدل شحن ملفّ اختبار: البنية هي المقصودة بالفحص.
Uint8List ttfWithName(int nameId, String value) {
  final text = <int>[];
  for (final unit in value.codeUnits) {
    text
      ..add(unit >> 8)
      ..add(unit & 0xFF); // UTF-16BE كما تكتبه منصّة Windows
  }
  const nameStart = 28; // 12 ترويسة + 16 سجلّ جدول واحد
  const storage = 6 + 12; // ترويسة الجدول + سجلّ واحد
  final name = <int>[
    0, 0, // format
    0, 1, // count
    0, storage,
    0, 3, 0, 1, 0, 0, // المنصّة 3، الترميز 1، اللغة 0
    (nameId >> 8) & 0xFF, nameId & 0xFF,
    (text.length >> 8) & 0xFF, text.length & 0xFF,
    0, 0, // الإزاحة داخل التخزين
    ...text,
  ];
  return Uint8List.fromList([
    0x00, 0x01, 0x00, 0x00, // توقيع TrueType
    0, 1, // عدد الجداول
    0, 0, 0, 0, 0, 0,
    ...'name'.codeUnits,
    0, 0, 0, 0, // checksum
    0, 0, 0, nameStart,
    0, 0, 0, name.length,
    ...name,
  ]);
}

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

      await service.resolveAll(['Amiri']);

      expect(service.statuses.single.origin, equals(FontOrigin.fetched));
      expect(cache.has('Amiri'), isTrue, reason: 'لم يُحفَظ للمرّة القادمة');
      expect(cache.list().single.bytes, greaterThan(0));
    });

    test('المحفوظ لا يُجلَب مرّةً ثانية', () async {
      final cache = freshCache();
      await cache.write('Lateef', fakeTtf());
      final fetcher = _FakeFetcher(FetchOutcome.fetched, bytes: fakeTtf());

      await FontService(cache, fetcher: fetcher).resolveAll(['Lateef']);

      expect(fetcher.calls, isZero, reason: 'جلبناه ونحن نملكه');
    });

    test('كل خطّ يُحلّ مرّة واحدة مهما تكرّر', () async {
      final fetcher = _FakeFetcher(FetchOutcome.notFound);
      final service = FontService(freshCache(), fetcher: fetcher);

      await service.resolveAll(['Amiri', 'Amiri']);
      await service.resolveAll(['Amiri']);

      expect(fetcher.calls, equals(1));
    });
  });

  group('الإبلاغ عند التعذّر', () {
    test('خطّ غير موجود في المصدر يُعلَن ولا يُبتلع', () async {
      // خطٌّ لا تعرفه الخدمة. الصمت هنا يجعل المعاينة كاذبة (`00` §5).
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      await service.resolveAll(['Amiri']);

      expect(service.missing.single.family, equals('Amiri'));
      expect(service.missing.single.origin, equals(FontOrigin.unavailable));
    });

    test('انقطاع الشبكة يُميَّز عن الخطّ المفقود', () async {
      // الرسالتان مختلفتان: «أعِد المحاولة» غير «لن يعمل أبدًا».
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.offline),
      );

      await service.resolveAll(['Amiri']);

      expect(service.missing.single.origin, equals(FontOrigin.offline));
    });

    test('إطفاء الجلب يمنع الطلب ويُعلَن سببًا', () async {
      final fetcher = _FakeFetcher(FetchOutcome.fetched, bytes: fakeTtf());
      final service = FontService(freshCache(), fetcher: fetcher)
        ..fetchEnabled = false;

      await service.resolveAll(['Amiri']);

      expect(fetcher.calls, isZero, reason: 'طلب شبكة رغم الإطفاء');
      expect(service.missing.single.origin, equals(FontOrigin.disabled));
    });

    test('إعادة التشغيل تُعيد تقييم ما تعذّر', () async {
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.fetched, bytes: fakeTtf()),
      )..fetchEnabled = false;
      await service.resolveAll(['Amiri']);
      expect(service.missing, hasLength(1));

      service.setFetchEnabled(true);
      await service.resolveAll(['Amiri']);

      expect(service.missing, isEmpty);
    });

    test('المتعذّر يتصدّر القائمة', () async {
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      await service.resolveAll(['Amiri', 'IBM Plex Sans Arabic']);

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

      await service.resolveAll(['Amiri']);

      expect(service.cache.has('Amiri'), isFalse);
      expect(service.missing.single.origin, equals(FontOrigin.unavailable));
    });
  });

  group('رخصة ما نشحنه', () {
    // الحدّ هنا **التوزيع لا الجلب**: شحن خطّ داخل حزمتنا إلى كل مستخدم
    // يحتاج رخصةً تجيزه. أمّا ما يجلبه المستخدم إلى قرصه فشأنه.

    test('نصّ OFL يُقبل', () {
      expect(
        isOpenFontLicensed(
          ttfWithLicense(
            'This Font Software is licensed under the SIL Open Font '
            'License, Version 1.1.',
          ),
        ),
        isTrue,
      );
    });

    test('نصّ يمنع النسخ يُرفض', () {
      expect(
        isOpenFontLicensed(
          ttfWithLicense(
            'This font has been licensed to Google Inc. and is the valuable '
            'property of Monotype Imaging. You may not redistribute, copy, '
            'convert, modify or reverse engineer this font.',
          ),
        ),
        isFalse,
      );
    });

    test('خطّ لا تُقرأ رخصته يُرفض', () {
      // لا جدول أسماء ⇒ لا نعرف ما نحفظ. الشكّ يُرفَض لا يُحفَظ.
      expect(isOpenFontLicensed(fakeTtf()), isFalse);
    });

    test('كل خطّ مشحون فعلًا تحت OFL', () async {
      // الحارس الأهمّ: يقرأ البايتات التي ستُشحَن، لا قائمةً نكتبها عنها.
      final files = Directory(
        'assets/fonts',
      ).listSync().where((e) => e.path.endsWith('.ttf')).toList();
      expect(files, isNotEmpty, reason: 'لا خطوط مشحونة');

      for (final file in files) {
        final bytes = await File(file.path).readAsBytes();
        expect(
          isOpenFontLicensed(bytes),
          isTrue,
          reason: '${file.path.split('/').last} مشحون ورخصته ليست OFL',
        );
      }
    });
  });

  group('البديل ملاذٌ أخير', () {
    test('خطّ لم نجده وله بديل يُرسَم به ويُعلَن', () async {
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      await service.resolveAll(['Calibri']);

      final status = service.statuses.single;
      expect(status.origin, equals(FontOrigin.substituted));
      expect(
        status.origin.isResolved,
        isTrue,
        reason: 'التخطيط سليم، فليس عجزًا',
      );
      expect(previewFamily('Calibri'), equals('Carlito'));
    });

    test('خطّ لم نجده ولا بديل له يبقى عجزًا معلَنًا', () async {
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      await service.resolveAll(['Amiri']);

      expect(service.missing.single.origin, equals(FontOrigin.unavailable));
      expect(previewFamily('Amiri'), equals('Amiri'));
    });

    test('المضمَّن يُرسَم باسمه لا ببديل', () {
      // البديل لما لم نجده. Cairo مشحونة، فلا معنى لإحلال شيء محلّها.
      expect(previewFamily('Cairo'), equals('Cairo'));
    });

    test('انقطاع الشبكة يبقى مميَّزًا حين لا بديل', () async {
      // «أعِد المحاولة» غير «لن نجده أبدًا» — والبديل لا يبتلع الفرق.
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.offline),
      );

      await service.resolveAll(['Amiri']);

      expect(service.missing.single.origin, equals(FontOrigin.offline));
    });
  });

  group('خطّ يضيفه المستخدم من قرصه', () {
    test('الاسم يُقرأ من داخل الملفّ لا من اسمه', () async {
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      final family = await service.addFromFile(ttfWithName(1, 'Frutiger'));

      expect(family, equals('Frutiger'));
      expect(service.cache.has('Frutiger'), isTrue);
    });

    test('العائلة الطباعية تسبق الاسم المدموج بنمطه', () async {
      // Word يكتب «Inter Light» عائلةً، والاسم 16 يقول «Inter».
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      expect(
        await service.addFromFile(ttfWithName(16, 'Frutiger')),
        equals('Frutiger'),
      );
    });

    test('ملفّ ليس خطًّا يُرفض ولا يُحفَظ', () async {
      final service = FontService(
        freshCache(),
        fetcher: _FakeFetcher(FetchOutcome.notFound),
      );

      expect(await service.addFromFile(fakeTtf()), isNull);
      expect(service.cache.list(), isEmpty);
    });
  });
}
