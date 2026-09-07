/// حالة مساحة العمل: المستند المفتوح، وخطة التبديل، والمعاينة الناتجة.
///
/// `ChangeNotifier` من نواة Flutter — بلا حزمة إدارة حالة. التطبيق يحمل
/// مستندًا واحدًا وخطة واحدة، وإضافة إطار عمل هنا دَيْن بلا مقابل.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/foundation.dart';

import 'document_loader.dart';
import 'file_tree.dart';
import 'identity.dart';
import 'style_edits.dart';

enum WorkspaceTab { colors, fonts, marks, identities }

/// أين يُكتب التعديل: قاعدةً تسري على المجموعة، أم استثناءً لهذا الملفّ.
///
/// **والافتراض يقرّره السياق لا المخزَن** (`ADR 0005` §٢): من فتح مجلدًا
/// فالشائع عنده ما يسري على ملفاته كلّها، ومن فتح ملفًّا واحدًا فلا معنى
/// للعموم عنده.
enum EditScope { general, file }

/// مستند مفتوح ومعه خطّته. كل تبويب يحمل خطّته الخاصّة، فلا تتسرّب
/// تعديلات ملفٍ إلى آخر.
class OpenTab {
  OpenTab(this.document);

  /// **يُستبدَل مرّةً واحدة**: يُفتح بأوّل صفحات المعاينة ثم يحلّ محلّها
  /// المستندُ كاملًا حين يجهز. ما عداه ثابت.
  LoadedDocument document;

  /// ما زالت بقيّة الصفحات قيد الاستخراج.
  bool previewPartial = true;

  /// الفحص جارٍ ولم تصل حصيلته بعد.
  bool inspecting = true;

  /// ما قرّره المستخدم لهذا الملفّ وحده. يفوز على العامّ دائمًا.
  final StyleEdits own = StyleEdits();

  /// **مقفلٌ عن العامّ.** لا تسري عليه القواعد العامّة، ويبقى على ما قرّره
  /// له صاحبه. **ويُصدَّر مع البقيّة**: القفل يستثني من التعديل لا من الكتابة.
  bool locked = false;

  /// راجعه المستخدم. **قرارٌ منه لا ملاحظةٌ من الفحص**، والعائلتان لا
  /// تختلطان في العرض (`ADR 0005` §٤).
  bool reviewed = false;

  /// ملاحظة يكتبها المستخدم على الملفّ.
  String? note;

  DocumentPreview? cachedPreview;
  int cachedPlanHash = -1;

  /// اللون المتتبَّع في هذا الملف. لكل تبويب تتبّعه، فلا يقفز التركيز عند
  /// التنقّل بين الملفات.
  HexColor? focused;

  /// العلامة المتتبَّعة. **واحدٌ يُتتبَّع في كل مرّة**: لونٌ وعلامة معًا
  /// يعنيان شريطَي تتبّع فوق الورقة، وتمييزين متنافسين على المقطع نفسه.
  TextMark? focusedMark;

  /// الخطة الفعّالة: العامّة ثم الخاصّة فوقها، ما لم يكن الملفّ مقفلًا.
  StylePlan planWith(StyleEdits general) =>
      resolvePlan(locked ? null : general, own);
}

class WorkspaceStore extends ChangeNotifier {
  final List<OpenTab> _tabs = [];

  /// القواعد التي تسري على كل ملفات المجموعة، إلا المقفل منها.
  final StyleEdits _general = StyleEdits();

  /// المجلدات التي فُتحت. تصير جذورًا في الشجرة، ويُنسب إليها ما تحتها.
  final Set<String> _directories = {};

  int _active = -1;
  LoadFailure? _failure;
  bool _busy = false;

  WorkspaceTab _tab = WorkspaceTab.colors;
  bool _onlyChanged = true;
  bool _showAfter = true;

  List<OpenTab> get tabs => List.unmodifiable(_tabs);
  int get activeIndex => _active;
  OpenTab? get current =>
      _active >= 0 && _active < _tabs.length ? _tabs[_active] : null;

  LoadedDocument? get document => current?.document;
  LoadFailure? get failure => _failure;
  bool get busy => _busy;

  /// المستند معروض وبقيّة صفحاته في الطريق — تعرضه الواجهة إشعارًا هادئًا.
  bool get previewPartial => current?.previewPartial ?? false;

  /// الصفحة معروضة والفحص جارٍ — اللوحات تقول ذلك ولا تبقى بيضاء.
  bool get inspecting => current?.inspecting ?? false;
  bool get hasDocument => current != null;
  InspectionReport? get report => current?.document.report;

  /// ألوان المستندات الأخرى المفتوحة — أساس «خذ الهوية من ملف ثانٍ».
  List<ColorUsage> otherDocumentColors() {
    final result = <ColorUsage>[];
    for (var i = 0; i < _tabs.length; i++) {
      if (i == _active) continue;
      final report = _tabs[i].document.report;
      if (report != null) result.addAll(report.contentColors);
    }
    return result;
  }

  /// الملفات الأخرى المفتوحة، بأسمائها — مصدر الهويات الجاهزة.
  List<({int index, String fileName})> otherDocuments() => [
    for (var i = 0; i < _tabs.length; i++)
      if (i != _active) (index: i, fileName: _tabs[i].document.fileName),
  ];

  /// شجرة المجموعة. [loose] اسم حاضنة الملفات المفردة، من ملفّ الترجمة.
  List<TreeRoot> fileTree(String loose) => buildFileTree(
    [
      for (var i = 0; i < _tabs.length; i++)
        (path: _tabs[i].document.path, index: i),
    ],
    _directories,
    loose: loose,
  );

  /// يسجّل مجلدًا فُتح، فيصير جذرًا تُنسب إليه ملفاته.
  void addDirectory(String path) {
    if (!_directories.add(path)) return;
    notifyListeners();
  }

  LoadedDocument? documentAt(int index) =>
      index >= 0 && index < _tabs.length ? _tabs[index].document : null;

  /// اللون المتتبَّع: يُبرَز في المعاينة، ويُتنقَّل بين مواضعه، ويُمرَّر
  /// إليه في قائمة الألوان.
  ///
  /// **هذا هو الجسر بين اللوحتين.** كان المستخدم يرى لونًا في الصفحة ثم
  /// يبحث عنه في قائمة من ثلاثين لونًا بالرقم السداسي. الآن يضغط عليه.
  HexColor? get focusedColor => current?.focused;

  /// يتتبّع لونًا، أو يرفع التتبّع عنه إن كان متتبَّعًا.
  ///
  /// ويفتح تبويب الألوان: من ضغط لونًا في الصفحة يريد أن يفعل به شيئًا،
  /// وتركُه ينظر إلى تبويب الخطوط يُضيّع الضغطة.
  void focusColor(HexColor? color) {
    final tab = current;
    if (tab == null) return;
    final resolved = color == null ? null : _sourceOf(tab, color);
    tab.focused = (resolved == null || resolved == tab.focused)
        ? null
        : resolved;
    if (tab.focused != null) {
      tab.focusedMark = null;
      _tab = WorkspaceTab.colors;
    }
    notifyListeners();
  }

  /// العلامة المتتبَّعة، بنفس بروتوكول اللون: تُبرَز في الصفحة، ويُتنقَّل
  /// بين مواضعها، ويُمرَّر إليها في قائمة العلامات.
  TextMark? get focusedMark => current?.focusedMark;

  void focusMark(TextMark? mark) {
    final tab = current;
    if (tab == null) return;
    tab.focusedMark = (mark == null || mark == tab.focusedMark) ? null : mark;
    if (tab.focusedMark != null) {
      tab.focused = null;
      _tab = WorkspaceTab.marks;
    }
    notifyListeners();
  }

  /// يردّ اللون إلى أصله في المستند.
  ///
  /// **خللٌ حقيقي كان هنا:** في عرض «بعد» تحمل الصفحة ألوان البدائل، وقائمة
  /// الألوان مفهرسة بألوان **المصدر**. فالضغط على لون بديل كان يطلب تتبّع
  /// لونٍ لا صفَّ له، فلا يحدث شيء. نردّه إلى مصدره فيجد صفّه.
  HexColor? _sourceOf(OpenTab tab, HexColor color) {
    final resolved = tab.planWith(_general).colors;
    if (resolved.containsKey(color)) return color;
    for (final entry in resolved.entries) {
      if (entry.value == color) return entry.key;
    }
    return color;
  }

  WorkspaceTab get tab => _tab;
  bool get onlyChanged => _onlyChanged;
  bool get showAfter => _showAfter;

  /// **ما يُعرَض للمستخدم هو الخطة الفعّالة**، لا إحدى طبقتيها: هو يرى ملفَّه
  /// كما سيخرج، والطبقتان تفصيلٌ في كيفية بنائها.
  Map<HexColor, HexColor> get colorMap => Map.unmodifiable(plan.colors);
  Set<TextMark> get liftedMarks => Set.unmodifiable(plan.removeMarks);
  String? get latinFont => plan.fonts?.latin;
  String? get arabicFont => plan.fonts?.arabic;
  Set<String> get preserveFonts => Set.unmodifiable(plan.preserveFonts);

  /// هل هذه القاعدة عامّة أم استثناءٌ لهذا الملفّ؟ تعرضه الواجهة على
  /// القاعدة نفسها لحظة كتابتها.
  bool isFileSpecific(HexColor from) =>
      current?.own.colors.containsKey(from) ?? false;

  /// الملفّ مقفلٌ عن الخطة العامّة.
  bool get locked => current?.locked ?? false;
  bool get reviewed => current?.reviewed ?? false;
  String? get note => current?.note;

  /// عدد التغييرات في المستند النشط — يظهر في الشريط العلوي.
  int get changeCount =>
      plan.colors.length +
      plan.removeMarks.length +
      (plan.fonts?.latin != null ? 1 : 0) +
      (plan.fonts?.arabic != null ? 1 : 0);

  bool get hasChanges => changeCount > 0;

  StylePlan get plan => current?.planWith(_general) ?? const StylePlan();

  StylePlan planFor(int index) => index >= 0 && index < _tabs.length
      ? _tabs[index].planWith(_general)
      : const StylePlan();

  /// عدد تغييرات ملفٍّ بعينه — يظهر على تبويبه وفي شجرة الملفات.
  int changeCountAt(int index) {
    final resolved = planFor(index);
    return resolved.colors.length +
        resolved.removeMarks.length +
        (resolved.fonts?.latin != null ? 1 : 0) +
        (resolved.fonts?.arabic != null ? 1 : 0);
  }

  /// المعاينة بعد تطبيق الخطة، محسوبة عند الحاجة ومحفوظة لكل تبويب.
  DocumentPreview? get previewAfter {
    final tab = current;
    if (tab == null) return null;
    final hash = _planHash;
    if (tab.cachedPreview != null && tab.cachedPlanHash == hash) {
      return tab.cachedPreview;
    }
    tab.cachedPreview = restylePreview(
      tab.document.preview,
      tab.planWith(_general),
    );
    tab.cachedPlanHash = hash;
    return tab.cachedPreview;
  }

  int get _planHash {
    final tab = current;
    if (tab == null) return -1;
    // **البصمة على الخطة الفعّالة**: تغيّرُ العامّة يمسّ هذا الملفّ كتغيّر
    // خاصّته، وحصرُها في الخاصّة يُبقي معاينةً محفوظة لا تعرف أنها بطلت.
    final resolved = tab.planWith(_general);
    return Object.hashAll([
      for (final entry in resolved.colors.entries) entry.key.value,
      for (final entry in resolved.colors.entries) entry.value.value,
      for (final mark in resolved.removeMarks) mark.toString(),
      resolved.fonts?.latin,
      resolved.fonts?.arabic,
      resolved.preserveFonts.length,
      tab.locked,
    ]);
  }

  Future<void> open(String path, String fileName, Uint8List bytes) async {
    _busy = true;
    _failure = null;
    notifyListeners();

    final result = await loadDocument(path, fileName, bytes);
    _busy = false;
    if (result.failure != null) {
      _failure = result.failure;
      notifyListeners();
      return;
    }

    // الملف نفسه مفتوح؟ ننتقل إليه بدل تكرار تبويبه.
    final existing = _tabs.indexWhere((t) => t.document.path == path);
    if (existing >= 0) {
      _active = existing;
      notifyListeners();
      return;
    }

    final tab = OpenTab(result.document!);
    _tabs.add(tab);
    _active = _tabs.length - 1;
    notifyListeners();

    // **الصفحة معروضة الآن؛ الباقي يلحق بترتيب ما يُرى.** اللوحات أوّلًا
    // لأن المستخدم ينظر إليها بعد الصفحة، ثم بقيّة الصفحات.
    await _completeInspection(tab, bytes);
    await _completePreview(tab, bytes);
  }

  Future<void> _completeInspection(OpenTab tab, Uint8List bytes) async {
    final report = await loadInspection(bytes);
    // أُغلق التبويب أثناء الفحص؟ لا شيء يُحدَّث.
    if (!_tabs.contains(tab)) return;
    tab.inspecting = false;
    if (report == null) {
      notifyListeners();
      return;
    }
    tab.document = tab.document.withReport(report);
    // الخطوط أحادية العرض تُحمى تلقائيًا، والمستخدم يرى ذلك ويستطيع تغييره.
    for (final font in report.monospacedCandidates) {
      tab.own.preserveFonts.add(font.name);
    }
    notifyListeners();
  }

  Future<void> _completePreview(OpenTab tab, Uint8List bytes) async {
    final full = await loadFullPreview(bytes);
    // أُغلق التبويب أثناء الاستخراج؟ لا شيء يُحدَّث.
    if (full == null || !_tabs.contains(tab)) return;
    tab.document = tab.document.withPreview(full);
    tab.previewPartial = false;
    // المعاينة المحفوظة بُنيت على الأوائل، فتسقط.
    tab.cachedPreview = null;
    tab.cachedPlanHash = -1;
    notifyListeners();
  }

  void selectDocument(int index) {
    if (index < 0 || index >= _tabs.length || index == _active) return;
    _active = index;
    notifyListeners();
  }

  void closeDocument([int? index]) {
    final at = index ?? _active;
    if (at < 0 || at >= _tabs.length) return;
    _tabs.removeAt(at);
    _active = _tabs.isEmpty ? -1 : at.clamp(0, _tabs.length - 1);
    _failure = null;
    notifyListeners();
  }

  /// يمحو ما قرّره المستخدم. [scope] يحدّد أي طبقة تُمحى.
  ///
  /// **والعامّة تُمحى للمجموعة كلّها**، فتُسقط معاينات كل الملفات لا الحاليَّ
  /// وحده.
  void resetChanges([EditScope scope = EditScope.file]) {
    if (scope == EditScope.general) {
      _general.clear();
      _invalidateAll();
      return;
    }
    current?.own.clear();
    _invalidate();
  }

  /// يرفع علامة عن النصّ أو يعيدها.
  ///
  /// **الرفع قرار ملفٍّ لا هوية**: الهوية تصف ألوانًا وخطوطًا، وأثرُ لصقٍ
  /// في ملفٍّ بعينه لا يوصف في هوية تُطبَّق على غيره.
  void liftMark(
    TextMark mark,
    bool lifted, [
    EditScope scope = EditScope.file,
  ]) {
    final edits = _editsFor(scope);
    if (edits == null) return;
    if (lifted) {
      edits.liftedMarks.add(mark);
    } else {
      edits.liftedMarks.remove(mark);
    }
    _invalidateFor(scope);
  }

  /// يرفع كل علامات المستند دفعةً واحدة، أو يعيدها كلّها.
  void liftAllMarks(bool lifted, [EditScope scope = EditScope.file]) {
    final tab = current;
    final edits = _editsFor(scope);
    if (tab == null || edits == null) return;
    edits.liftedMarks.clear();
    if (lifted) {
      for (final usage in tab.document.report?.marks ?? const <MarkUsage>[]) {
        edits.liftedMarks.add(usage.mark);
      }
    }
    _invalidateFor(scope);
  }

  /// يبدّل لونًا. [scope] يقرّر أتسري القاعدة على المجموعة أم على هذا الملفّ.
  ///
  /// **ورفعُ التبديل عن لونٍ تحكمه قاعدة عامّة ليس حذفًا بل استثناء**: يُسجَّل
  /// في الطبقة الخاصّة بقيمة `null`، فيقول «هذا الملفّ يُبقيه» بدل أن يعود
  /// إلى العامّة صامتًا.
  void mapColor(
    HexColor from,
    HexColor? to, [
    EditScope scope = EditScope.file,
  ]) {
    final edits = _editsFor(scope);
    if (edits == null) return;
    final clearing = to == null || to == from;

    if (scope == EditScope.general) {
      if (clearing) {
        edits.colors.remove(from);
      } else {
        edits.colors[from] = to;
      }
      _invalidateAll();
      return;
    }

    if (!clearing) {
      edits.colors[from] = to;
    } else if (_general.colors[from] != null) {
      edits.colors[from] = null; // استثناءٌ صريح من قاعدةٍ عامّة
    } else {
      edits.colors.remove(from);
    }
    _invalidate();
  }

  /// يُلغي استثناء الملفّ فيعود اللون إلى ما تقوله القاعدة العامّة.
  void clearFileColor(HexColor from) {
    if (current?.own.colors.remove(from) == null) return;
    _invalidate();
  }

  StyleEdits? _editsFor(EditScope scope) =>
      scope == EditScope.general ? _general : current?.own;

  void _invalidateFor(EditScope scope) =>
      scope == EditScope.general ? _invalidateAll() : _invalidate();

  /// يُسقط معاينات كل الملفات: القاعدة العامّة تمسّها جميعًا.
  void _invalidateAll() {
    for (final tab in _tabs) {
      tab.cachedPreview = null;
      tab.cachedPlanHash = -1;
    }
    notifyListeners();
  }

  /// يقفل ملفًّا عن الخطة العامّة أو يفتحه.
  void setLocked(int index, bool value) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs[index].locked = value;
    _tabs[index].cachedPreview = null;
    _tabs[index].cachedPlanHash = -1;
    notifyListeners();
  }

  /// علامة «راجعته» — قرارُ المستخدم، لا ملاحظةُ الفحص.
  void setReviewed(int index, bool value) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs[index].reviewed = value;
    notifyListeners();
  }

  void setNote(int index, String? value) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs[index].note = (value == null || value.trim().isEmpty) ? null : value;
    notifyListeners();
  }

  void setLatinFont(String? name, [EditScope scope = EditScope.file]) {
    _editsFor(scope)?.latinFont = (name == null || name.isEmpty) ? null : name;
    _invalidateFor(scope);
  }

  void setArabicFont(String? name, [EditScope scope = EditScope.file]) {
    _editsFor(scope)?.arabicFont = (name == null || name.isEmpty) ? null : name;
    _invalidateFor(scope);
  }

  void togglePreserved(
    String font,
    bool preserved, [
    EditScope scope = EditScope.file,
  ]) {
    final edits = _editsFor(scope);
    if (edits == null) return;
    if (preserved) {
      edits.preserveFonts.add(font);
    } else {
      edits.preserveFonts.remove(font);
    }
    _invalidateFor(scope);
  }

  void selectTab(WorkspaceTab value) {
    _tab = value;
    notifyListeners();
  }

  void setOnlyChanged(bool value) {
    _onlyChanged = value;
    notifyListeners();
  }

  void setShowAfter(bool value) {
    _showAfter = value;
    notifyListeners();
  }

  /// يطبّق هوية محفوظة: يوزّع ألوانها على ألوان المستند بأقرب إضاءة.
  ///
  /// المطابقة بالإضاءة تحفظ بنية الفاتح والداكن، فيبقى النصّ مقروءًا
  /// ولا ينقلب عنوان داكن إلى خلفية فاتحة.
  void applyIdentity(Identity identity) {
    final tab = current;
    if (tab == null || (identity.colors.isEmpty && identity.map.isEmpty)) {
      return;
    }

    final report = tab.document.report;
    if (report == null) return; // لا فحص بعد: لا ألوان تُوزَّع عليها هوية.
    for (final usage in report.contentColors) {
      // **القاعدة الصريحة تسبق كل ترجيح**، وتسبق حارس المحايدين معه: من
      // كتب «هذا اللون يصير ذاك» قصده، ولا يُردّ عليه قصدُه بتخمين. وهي
      // التي تجعل الملف الحادي والأربعين يخرج مطابقًا لما قبله.
      final explicit = identity.map[usage.color];
      if (explicit != null) {
        tab.own.colors[usage.color] = explicit;
        continue;
      }
      if (identity.colors.isEmpty) continue;

      // الأبيض والأسود مرجعان محايدان: تبديلهما يقلب المستند رأسًا على عقب.
      if (usage.color.value == '#FFFFFF' || usage.color.value == '#000000') {
        continue;
      }
      var best = identity.colors.first;
      var bestGap = double.infinity;
      for (final candidate in identity.colors) {
        final gap =
            (candidate.hex.relativeLuminance - usage.color.relativeLuminance)
                .abs();
        if (gap < bestGap) {
          bestGap = gap;
          best = candidate;
        }
      }
      tab.own.colors[usage.color] = best.hex;
    }

    tab.own.latinFont = identity.latinFont ?? tab.own.latinFont;
    tab.own.arabicFont = identity.arabicFont ?? tab.own.arabicFont;
    tab.own.preserveFonts.addAll(identity.preserveFonts);
    _invalidate();
  }

  void _invalidate() {
    current?.cachedPreview = null;
    current?.cachedPlanHash = -1;
    notifyListeners();
  }
}
