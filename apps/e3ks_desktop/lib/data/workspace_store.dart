/// حالة مساحة العمل: المستند المفتوح، وخطة التبديل، والمعاينة الناتجة.
///
/// `ChangeNotifier` من نواة Flutter — بلا حزمة إدارة حالة. التطبيق يحمل
/// مستندًا واحدًا وخطة واحدة، وإضافة إطار عمل هنا دَيْن بلا مقابل.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/foundation.dart';

import 'document_loader.dart';
import 'identity.dart';

enum WorkspaceTab { colors, fonts, identities }

/// مستند مفتوح ومعه خطّته. كل تبويب يحمل خطّته الخاصّة، فلا تتسرّب
/// تعديلات ملفٍ إلى آخر.
class OpenTab {
  OpenTab(this.document);

  final LoadedDocument document;
  final Map<HexColor, HexColor> colorMap = {};
  final Set<String> preserveFonts = {};
  String? latinFont;
  String? arabicFont;

  DocumentPreview? cachedPreview;
  int cachedPlanHash = -1;

  StylePlan get plan => StylePlan(
    colors: Map.of(colorMap),
    fonts: FontPlan(latin: latinFont, arabic: arabicFont),
    preserveFonts: Set.of(preserveFonts),
  );

  int get changeCount =>
      colorMap.length +
      (latinFont != null ? 1 : 0) +
      (arabicFont != null ? 1 : 0);
}

class WorkspaceStore extends ChangeNotifier {
  final List<OpenTab> _tabs = [];
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
  bool get hasDocument => current != null;
  InspectionReport? get report => current?.document.report;

  /// ألوان المستندات الأخرى المفتوحة — أساس «خذ الهوية من ملف ثانٍ».
  List<ColorUsage> otherDocumentColors() {
    final result = <ColorUsage>[];
    for (var i = 0; i < _tabs.length; i++) {
      if (i == _active) continue;
      result.addAll(_tabs[i].document.report.contentColors);
    }
    return result;
  }

  WorkspaceTab get tab => _tab;
  bool get onlyChanged => _onlyChanged;
  bool get showAfter => _showAfter;

  Map<HexColor, HexColor> get colorMap =>
      Map.unmodifiable(current?.colorMap ?? const {});
  String? get latinFont => current?.latinFont;
  String? get arabicFont => current?.arabicFont;
  Set<String> get preserveFonts =>
      Set.unmodifiable(current?.preserveFonts ?? const {});

  /// عدد التغييرات في المستند النشط — يظهر في الشريط العلوي.
  int get changeCount => current?.changeCount ?? 0;

  bool get hasChanges => changeCount > 0;

  StylePlan get plan => current?.plan ?? const StylePlan();

  /// المعاينة بعد تطبيق الخطة، محسوبة عند الحاجة ومحفوظة لكل تبويب.
  DocumentPreview? get previewAfter {
    final tab = current;
    if (tab == null) return null;
    final hash = _planHash;
    if (tab.cachedPreview != null && tab.cachedPlanHash == hash) {
      return tab.cachedPreview;
    }
    tab.cachedPreview = restylePreview(tab.document.preview, tab.plan);
    tab.cachedPlanHash = hash;
    return tab.cachedPreview;
  }

  int get _planHash {
    final tab = current;
    if (tab == null) return -1;
    return Object.hashAll([
      for (final entry in tab.colorMap.entries) entry.key.value,
      for (final entry in tab.colorMap.entries) entry.value.value,
      tab.latinFont,
      tab.arabicFont,
      tab.preserveFonts.length,
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
    // الخطوط أحادية العرض تُحمى تلقائيًا، والمستخدم يرى ذلك ويستطيع تغييره.
    for (final font in result.document!.report.monospacedCandidates) {
      tab.preserveFonts.add(font.name);
    }
    _tabs.add(tab);
    _active = _tabs.length - 1;
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

  void resetChanges() {
    final tab = current;
    if (tab == null) return;
    tab.colorMap.clear();
    tab.latinFont = null;
    tab.arabicFont = null;
    _invalidate();
  }

  void mapColor(HexColor from, HexColor? to) {
    final tab = current;
    if (tab == null) return;
    if (to == null || to == from) {
      tab.colorMap.remove(from);
    } else {
      tab.colorMap[from] = to;
    }
    _invalidate();
  }

  void setLatinFont(String? name) {
    current?.latinFont = (name == null || name.isEmpty) ? null : name;
    _invalidate();
  }

  void setArabicFont(String? name) {
    current?.arabicFont = (name == null || name.isEmpty) ? null : name;
    _invalidate();
  }

  void togglePreserved(String font, bool preserved) {
    final tab = current;
    if (tab == null) return;
    if (preserved) {
      tab.preserveFonts.add(font);
    } else {
      tab.preserveFonts.remove(font);
    }
    _invalidate();
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
    if (tab == null || identity.colors.isEmpty) return;

    for (final usage in tab.document.report.contentColors) {
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
      tab.colorMap[usage.color] = best.hex;
    }

    tab.latinFont = identity.latinFont ?? tab.latinFont;
    tab.arabicFont = identity.arabicFont ?? tab.arabicFont;
    tab.preserveFonts.addAll(identity.preserveFonts);
    _invalidate();
  }

  void _invalidate() {
    current?.cachedPreview = null;
    current?.cachedPlanHash = -1;
    notifyListeners();
  }
}
