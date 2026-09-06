/// إطار النافذة المخصّص: يُقاس ولا يُفترَض، ويُعاد قياسه حين يتغيّر.
library;

import 'package:e3ks_desktop/data/window_frame.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel('e3ks/window');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  test('بلا قناة: لا حجز ولا انهيار', () async {
    // منصّة بلا إطار مخصّص، أو بيئة اختبار.
    expect(await readWindowFrame(), equals(flatWindowFrame));
  });

  test('الأزرار يسارًا: الحجز يسارًا', () async {
    messenger.setMockMethodCallHandler(_channel, (call) async {
      expect(call.method, equals('metrics'));
      return <String, double>{
        'titlebarHeight': 28,
        'reserveLeft': 78,
        'reserveRight': 0,
      };
    });

    final frame = await readWindowFrame();
    expect(frame.titlebarHeight, equals(28));
    expect(frame.reserveLeft, equals(78));
    expect(frame.reserveRight, equals(0));
  });

  test('الأزرار يمينًا: الحجز يمينًا', () async {
    // نظام بلغة عربية ينقل أزرار النافذة إلى اليمين. من يحجز يسارًا دائمًا
    // يصطدم بها هناك.
    messenger.setMockMethodCallHandler(_channel, (call) async {
      return <String, double>{
        'titlebarHeight': 28,
        'reserveLeft': 0,
        'reserveRight': 78,
      };
    });

    final frame = await readWindowFrame();
    expect(frame.reserveLeft, equals(0));
    expect(frame.reserveRight, equals(78));
  });

  test('ردّ ناقص لا يُسقط الإقلاع', () async {
    messenger.setMockMethodCallHandler(
      _channel,
      (call) async => <String, double>{'titlebarHeight': 28},
    );

    final frame = await readWindowFrame();
    expect(frame.titlebarHeight, equals(28));
    expect(frame.reserveLeft, equals(0));
  });

  group('المتابعة الحيّة', () {
    /// يحاكي دفعةً من الجهة الأصلية.
    Future<void> push(Map<String, double> metrics) =>
        messenger.handlePlatformMessage(
          _channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('metrics', metrics),
          ),
          (_) {},
        );

    test('تبدأ بالقياس الأول', () async {
      messenger.setMockMethodCallHandler(
        _channel,
        (call) async => <String, double>{
          'titlebarHeight': 28,
          'reserveLeft': 78,
          'reserveRight': 0,
        },
      );

      final watch = WindowFrameWatch();
      await watch.start();

      expect(watch.value.reserveLeft, equals(78));
      watch.dispose();
    });

    test('ملء الشاشة يُسقط الحجز ويُخطر المستمعين', () async {
      // أزرار النظام تختفي في ملء الشاشة، والحجز الباقي فراغٌ بلا شاغل.
      messenger.setMockMethodCallHandler(
        _channel,
        (call) async => <String, double>{
          'titlebarHeight': 28,
          'reserveLeft': 78,
          'reserveRight': 0,
        },
      );
      final watch = WindowFrameWatch();
      await watch.start();
      var notified = 0;
      watch.addListener(() => notified++);

      await push({'titlebarHeight': 0, 'reserveLeft': 0, 'reserveRight': 0});

      expect(watch.value, equals(flatWindowFrame));
      expect(notified, equals(1), reason: 'تغيّر بلا إخطار لا يُعاد رسمه');
      watch.dispose();
    });

    test('الخروج من ملء الشاشة يعيد الحجز', () async {
      messenger.setMockMethodCallHandler(_channel, (call) async => null);
      final watch = WindowFrameWatch();
      await watch.start();
      expect(watch.value, equals(flatWindowFrame));

      await push({'titlebarHeight': 28, 'reserveLeft': 0, 'reserveRight': 78});

      expect(watch.value.reserveRight, equals(78));
      watch.dispose();
    });

    test('بلا قناة تبدأ بلا حجز ولا تنهار', () async {
      final watch = WindowFrameWatch();
      await watch.start();

      expect(watch.value, equals(flatWindowFrame));
      watch.dispose();
    });
  });
}
