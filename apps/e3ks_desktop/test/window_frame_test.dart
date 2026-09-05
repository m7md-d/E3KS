/// إطار النافذة المخصّص: يُقاس ولا يُفترَض.
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
}
