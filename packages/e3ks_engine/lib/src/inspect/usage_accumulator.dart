/// جامعا استعمالات الألوان والخطوط أثناء الفحص.
///
/// **مشتركان بين الصيغ:** ما يختلف بين Word وPowerPoint هو *أين* يسكن اللون،
/// لا *كيف* يُحصى. تكرارهما لكل صيغة يعني انحرافًا في العدّ لا يلاحظه أحد.
library;

import 'color_usage.dart';
import 'font_usage.dart';
import 'hex_color.dart';
import 'part_class.dart';
import 'text_mark.dart';

/// أقصى عدد عيّنات نصّية لكل لون. ثلاث تكفي لفهم الدور، والمزيد ضجيج.
const int maxColorSamples = 3;
const int colorSampleLength = 60;

/// موضع الفحص الحالي: أي جزء وأي تصنيف.
final class ScanContext {
  const ScanContext(this.partName, this.partClass);
  final String partName;
  final PartClass partClass;
}

final class ColorAccumulator {
  int count = 0;
  final Map<ColorRole, int> byRole = {};
  final Map<String, int> byPart = {};
  final Set<PartClass> partClasses = {};
  final List<String> samples = [];
  bool themeLinked = false;

  void record(
    ScanContext context,
    ColorRole role, {
    required bool themed,
    String? sample,
  }) {
    count++;
    byRole[role] = (byRole[role] ?? 0) + 1;
    byPart[context.partName] = (byPart[context.partName] ?? 0) + 1;
    partClasses.add(context.partClass);
    if (themed) themeLinked = true;
    addSample(sample);
  }

  /// **تُضاف بعد التسجيل** لأن نصّ العيّنة يأتي بعد اللون في تدفّق XML:
  /// اللون يسكن `rPr` وسابقٌ لنصّ الـ`run`. الحدّ والتفرّد كما هما.
  void addSample(String? sample) {
    if (sample == null) return;
    if (samples.length >= maxColorSamples) return;
    if (samples.contains(sample)) return;
    samples.add(sample);
  }

  ColorUsage build(HexColor color) => ColorUsage(
    color: color,
    count: count,
    byRole: Map.unmodifiable(byRole),
    byPart: Map.unmodifiable(byPart),
    partClasses: Set.unmodifiable(partClasses),
    themeLinked: themeLinked,
    samples: List.unmodifiable(samples),
  );
}

final class FontAccumulator {
  int count = 0;
  final Map<FontSlot, int> bySlot = {};
  final Map<String, int> byPart = {};
  final Set<PartClass> partClasses = {};
  bool themeLinked = false;

  void record(ScanContext context, FontSlot slot, {required bool themed}) {
    count++;
    bySlot[slot] = (bySlot[slot] ?? 0) + 1;
    byPart[context.partName] = (byPart[context.partName] ?? 0) + 1;
    partClasses.add(context.partClass);
    if (themed) themeLinked = true;
  }

  FontUsage build(String name) => FontUsage(
    name: name,
    count: count,
    bySlot: Map.unmodifiable(bySlot),
    byPart: Map.unmodifiable(byPart),
    partClasses: Set.unmodifiable(partClasses),
    themeLinked: themeLinked,
  );
}

final class MarkAccumulator {
  int count = 0;
  final Map<String, int> byPart = {};
  final Set<PartClass> partClasses = {};
  final List<String> samples = [];

  void record(ScanContext context, {String? sample}) {
    count++;
    byPart[context.partName] = (byPart[context.partName] ?? 0) + 1;
    partClasses.add(context.partClass);
    addSample(sample);
  }

  /// كنظيرتها في [ColorAccumulator]: العيّنة تُلحَق حين يُعرَف نصّها.
  void addSample(String? sample) {
    if (sample == null) return;
    if (samples.length >= maxColorSamples) return;
    if (samples.contains(sample)) return;
    samples.add(sample);
  }

  MarkUsage build(TextMark mark) => MarkUsage(
    mark: mark,
    count: count,
    byPart: Map.unmodifiable(byPart),
    partClasses: Set.unmodifiable(partClasses),
    samples: List.unmodifiable(samples),
  );
}

/// يبني قائمتَي التقرير مرتَّبتين تنازليًا بعدد الاستعمال.
List<ColorUsage> buildColors(Map<HexColor, ColorAccumulator> colors) =>
    [for (final e in colors.entries) e.value.build(e.key)]
      ..sort((a, b) => b.count.compareTo(a.count));

List<FontUsage> buildFonts(Map<String, FontAccumulator> fonts) =>
    [for (final e in fonts.entries) e.value.build(e.key)]
      ..sort((a, b) => b.count.compareTo(a.count));

List<MarkUsage> buildMarks(Map<TextMark, MarkAccumulator> marks) =>
    [for (final e in marks.entries) e.value.build(e.key)]
      ..sort((a, b) => b.count.compareTo(a.count));
