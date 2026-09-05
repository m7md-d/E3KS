/// ملف الهوية: شكله، وقراءته القديم، وأسبقية القاعدة الصريحة.
library;

import 'dart:convert';

import 'package:e3ks_desktop/data/identity.dart';
import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// `!` مضمون: القيم أدناه بصيغة `#RRGGBB` صحيحة.
HexColor hex(String value) => HexColor.tryParse(value)!;

void main() {
  test('ملف قديم بلا version ولا map ولا role يُقرأ ويعمل', () {
    // الشكل الذي كتبه التطبيق قبل هذه الحقول. كسره يعني هويات مستخدمين
    // تختفي عند الترقية.
    final old = jsonDecode('''
      {
        "name": "طويق",
        "colors": [{"name": "الأساسي", "hex": "#00635D"}],
        "fonts": {"latin": "IBM Plex Sans", "arabic": "IBM Plex Sans Arabic"},
        "preserveFonts": ["Courier"]
      }
    ''');

    final identity = Identity.fromJson(old)!;
    expect(identity.version, equals(1));
    expect(identity.map, isEmpty);
    expect(identity.colors.single.role, equals(IdentityRole.other));
    expect(identity.latinFont, equals('IBM Plex Sans'));
    expect(identity.preserveFonts, equals(['Courier']));
  });

  test('الشكل الجديد يذهب ويعود كما هو', () {
    final identity = Identity(
      name: 'نورثويند',
      colors: [
        NamedColor(
          name: 'الأساسي',
          hex: hex('#0F3D3E'),
          role: IdentityRole.primary,
        ),
        NamedColor(name: 'مكمّل', hex: hex('#E76F51')),
      ],
      map: {hex('#3333B2'): hex('#0F3D3E')},
      latinFont: 'IBM Plex Sans',
      preserveFonts: const ['Consolas'],
    );

    final back = Identity.fromJson(jsonDecode(identity.encode()))!;
    expect(back.version, equals(currentIdentityVersion));
    expect(back.name, equals(identity.name));
    expect(back.colors.first.role, equals(IdentityRole.primary));
    expect(back.colors.last.role, equals(IdentityRole.other));
    expect(back.map[hex('#3333B2')], equals(hex('#0F3D3E')));
    expect(back.latinFont, equals('IBM Plex Sans'));
    expect(back.preserveFonts, equals(['Consolas']));
  });

  test('الحقول الفارغة لا تُكتب، والدور المجهول لا يُكتب', () {
    // الملف يُقرأ بالعين ويُشارَك: حقلٌ بقيمة «لا شيء» ضجيج.
    final encoded = Identity(
      name: 'بلا خريطة',
      colors: [NamedColor(name: 'لون', hex: hex('#123456'))],
    ).encode();

    expect(encoded, isNot(contains('"map"')));
    expect(encoded, isNot(contains('"role"')));
    expect(encoded, contains('"version": 1'));
  });

  test('قيمة تالفة في الخريطة تُتخطّى ولا تُسقط الملف', () {
    final identity = Identity.fromJson(
      jsonDecode('''
        {
          "name": "فيها تلف",
          "map": {"#3333B2": "#0F3D3E", "غير لون": "#000000", "#FF0000": "؟"}
        }
      '''),
    )!;

    expect(identity.map.length, equals(1));
    expect(identity.map[hex('#3333B2')], equals(hex('#0F3D3E')));
  });
}
