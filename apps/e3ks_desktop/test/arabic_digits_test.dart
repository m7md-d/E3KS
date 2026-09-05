/// الأرقام الهندية تُقرأ كما تُعرَض.
library;

import 'package:e3ks_desktop/shared/arabic_digits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('يحوّل العربية-الهندية والفارسية الممتدّة', () {
    // من يقرأ «صفحة ١٢» يكتب «١٢» — ورفضُ ما عرضناه عليه عيبٌ فينا.
    expect(toWesternDigits('١٢٣'), equals('123'));
    expect(toWesternDigits('۱۲۳'), equals('123'));
    expect(toWesternDigits('٠٩'), equals('09'));
  });

  test('يترك ما ليس رقمًا كما هو', () {
    expect(toWesternDigits('صفحة ١٢'), equals('صفحة 12'));
    expect(toWesternDigits('12'), equals('12'));
    expect(toWesternDigits(''), isEmpty);
  });

  test('القراءة تقبل الصيغتين وتتجاهل الفراغ', () {
    expect(parseFlexibleInt('١٢'), equals(12));
    expect(parseFlexibleInt(' ۳۷ '), equals(37));
    expect(parseFlexibleInt('37'), equals(37));
  });

  test('لا تخمين: ما ليس عددًا يُرفض', () {
    // نصٌّ فيه رقم وحرف مدخَلٌ خاطئ، وقبوله يقفز بالمستخدم إلى صفحة لم يقصدها.
    expect(parseFlexibleInt('١٢أ'), isNull);
    expect(parseFlexibleInt('صفحة'), isNull);
    expect(parseFlexibleInt(''), isNull);
    expect(parseFlexibleInt('1.5'), isNull);
  });
}
