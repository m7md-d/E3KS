/// شجرة الملفات: جذورٌ لا جذر — `ADR 0005` §٥.
library;

import 'package:e3ks_desktop/data/file_tree.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _names(List<TreeNode> nodes) => [
  for (final node in nodes)
    if (node is FolderNode) '${node.name}/' else node.name,
];

TreeEntry at(String path, int index) => (path: path, index: index);

void main() {
  test('المجلد جذرٌ باسمه، وتحته بنيته', () {
    final tree = buildFileTree(
      [at('/عمل/دليل/أول.docx', 0), at('/عمل/دليل/فرع/ثانٍ.docx', 1)],
      {'/عمل/دليل'},
      loose: 'ملفات',
    );

    expect(tree, hasLength(1));
    expect(tree.single.name, equals('دليل'));
    expect(_names(tree.single.children), equals(['فرع/', 'أول.docx']));
  });

  test('الملفات المفردة في جذرٍ واحد بلا بنية', () {
    // **لا تُعرَض سلسلة `/Users/…` فوق كل ملفّ**: تملأ العمود بما لا يميّز.
    final tree = buildFileTree(
      [at('/a/b/c/تقرير.docx', 0), at('/x/y/عرض.pptx', 1)],
      const {},
      loose: 'ملفات مضافة',
    );

    expect(tree, hasLength(1));
    expect(tree.single.name, equals('ملفات مضافة'));
    expect(tree.single.directory, isNull);
    expect(_names(tree.single.children), equals(['تقرير.docx', 'عرض.pptx']));
  });

  test('ما يقع تحت جذرٍ مفتوح يُكشَف في موضعه ولا يُكرَّر', () {
    final tree = buildFileTree(
      [
        at('/عمل/أول.docx', 0),
        at('/عمل/فرع/ثانٍ.docx', 1), // أُفلت بعد فتح المجلد
      ],
      {'/عمل'},
      loose: 'ملفات',
    );

    expect(tree, hasLength(1), reason: 'ظهر جذرٌ ثانٍ للملفّ المُفلَت');
    final folder = tree.single.children.first as FolderNode;
    expect(folder.name, equals('فرع'));
    expect((folder.children.single as FileNode).index, equals(1));
  });

  test('المجلد الأعمق يأخذ ملفّاته لا جدُّه', () {
    final tree = buildFileTree(
      [at('/عمل/دليل/ملف.docx', 0)],
      {'/عمل', '/عمل/دليل'},
      loose: 'ملفات',
    );

    final owner = tree.firstWhere((r) => r.children.isNotEmpty);
    expect(owner.name, equals('دليل'));
    expect(_names(owner.children), equals(['ملف.docx']));
  });

  test('المجلد الخالي من المدعوم لا يظهر', () {
    final tree = buildFileTree(const [], {'/فارغ'}, loose: 'ملفات');
    expect(tree, isEmpty);
  });

  test('المجلدات قبل الملفات', () {
    final tree = buildFileTree(
      [at('/ج/ألف.docx', 0), at('/ج/باء/ملف.docx', 1)],
      {'/ج'},
      loose: 'ملفات',
    );

    expect(_names(tree.single.children), equals(['باء/', 'ألف.docx']));
  });

  test('الترتيب على اسمٍ مطبَّع لا على نقاط الترميز', () {
    // «أحمد» بهمزة و«اسم» بلا همزة: الخام يضع المهموزة أوّلًا دائمًا
    // (0x0623 قبل 0x0627)، والمطبَّع يرتّبهما كما يقرؤهما الإنسان.
    final tree = buildFileTree(
      [at('/ج/بدر.docx', 0), at('/ج/أحمد.docx', 1), at('/ج/اسم.docx', 2)],
      {'/ج'},
      loose: 'ملفات',
    );

    expect(
      _names(tree.single.children),
      equals(['أحمد.docx', 'اسم.docx', 'بدر.docx']),
    );
  });

  test('التطويل والتشكيل لا يغيّران الموضع', () {
    expect(normalizeName('مُحَمَّـد'), equals(normalizeName('محمد')));
    expect(normalizeName('إبراهيم'), equals(normalizeName('ابراهيم')));
    expect(normalizeName('مصطفى'), equals(normalizeName('مصطفي')));
  });

  test('جذورٌ متعدّدة تظهر معًا، والمفردة آخرًا', () {
    final tree = buildFileTree(
      [
        at('/أ/واحد.docx', 0),
        at('/ب/اثنان.docx', 1),
        at('/بعيد/ثلاثة.docx', 2),
      ],
      {'/أ', '/ب'},
      loose: 'ملفات مضافة',
    );

    expect(tree.map((r) => r.name), containsAll(['أ', 'ب', 'ملفات مضافة']));
    expect(tree.last.name, equals('ملفات مضافة'));
  });
}
