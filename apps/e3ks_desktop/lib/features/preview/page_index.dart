/// فهرس مسطَّح للصفحات، وتحديد المتأثّر منها.
///
/// الفهرس المسطَّح هو ما يسمح بالعرض المُحجَّم (virtualized): القائمة تعرف
/// عدد الصفحات دون بناء أيّها، فلا يُرسم إلا ما يراه المستخدم.
library;

import 'package:e3ks_engine/e3ks_engine.dart';

import 'change_scan.dart';

/// صفحة في موضعها من المستند كلّه.
typedef FlatPage = ({
  int index,
  PreviewSectionKind kind,
  int numberInSection,
  PreviewPage page,
  bool firstOfSection,
});

List<FlatPage> flattenPages(DocumentPreview preview) {
  final result = <FlatPage>[];
  for (final section in preview.sections) {
    for (var i = 0; i < section.pages.length; i++) {
      result.add((
        index: result.length,
        kind: section.kind,
        numberInSection: section.pages[i].number,
        page: section.pages[i],
        firstOfSection: i == 0,
      ));
    }
  }
  return result;
}

/// فهارس الصفحات التي تحوي تغييرًا — وحدة التنقّل في المعاينة.
///
/// التنقّل بالصفحة لا بالفقرة: هو ما يفهمه المستخدم («صفحة ١٢»)، وهو أيضًا
/// ما يجعل القفز دقيقًا مع العرض المُحجَّم.
List<int> changedPages(
  List<FlatPage> pages, {
  required Set<String> colors,
  required Set<String> fonts,
}) {
  if (colors.isEmpty && fonts.isEmpty) return const [];
  return [
    for (final entry in pages)
      if (entry.page.blocks.any(
        (b) => blockChanged(b, colors: colors, fonts: fonts),
      ))
        entry.index,
  ];
}

/// فهارس الصفحات التي يظهر فيها [value] — وحدة التنقّل عند تتبّع لون.
///
/// بالصفحة لا بالفقرة: هو ما يفهمه المستخدم («صفحة ١٢»)، وهو ما يجعل القفز
/// دقيقًا مع العرض المُحجَّم.
List<int> pagesWithColor(List<FlatPage> pages, String value) => [
  for (final entry in pages)
    if (entry.page.blocks.any((b) => blockHasColor(b, value))) entry.index,
];
