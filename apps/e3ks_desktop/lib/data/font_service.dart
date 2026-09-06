/// حلّ خطوط المستند: أين هي، وهل تُجلَب، وماذا نقول للمستخدم إن تعذّرت.
///
/// المعاينة تَعِد بعرض الملف **بشكله الحقيقي**. خطٌّ ناقص يجعلها كاذبةً بصمت،
/// ولذلك لا يكفي أن نجلب — يجب أن نُبلّغ حين نعجز (`00` §5).
///
/// الترتيب: مضمَّن ← منصَّب في النظام ← محفوظ عندنا ← يُجلَب من الشبكة.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'font_cache.dart';
import 'font_fetcher.dart';
import 'font_probe.dart';
import 'font_substitutes.dart';

/// من أين جاء الخطّ، أو لماذا لم يأتِ.
enum FontOrigin {
  /// مضمَّن في التطبيق.
  bundled,

  /// منصَّب على جهاز المستخدم.
  system,

  /// محفوظ على قرص المستخدم: جلبناه سابقًا، أو أضافه هو بنفسه.
  cached,

  /// جُلب الآن.
  fetched,

  /// غير موجود في مصدرنا.
  unavailable,

  /// لم نجده، ورسمناه ببديل مطابق مقاسيًّا. المعاينة سليمة التخطيط.
  substituted,

  /// تعذّر الاتصال.
  offline,

  /// الجلب معطَّل من الإعدادات.
  disabled,
}

extension FontOriginX on FontOrigin {
  /// هل سيُرسَم النصّ بخطّه الحقيقي؟
  bool get isResolved =>
      this == FontOrigin.bundled ||
      this == FontOrigin.system ||
      this == FontOrigin.cached ||
      this == FontOrigin.fetched ||
      this == FontOrigin.substituted;
}

typedef FontStatus = ({String family, FontOrigin origin});

/// يحلّ الخطوط ويحمّلها وقت التشغيل، ويحتفظ بحصيلة آخر عملية.
class FontService extends ChangeNotifier {
  FontService(this.cache, {FontFetcher fetcher = const GoogleFontFetcher()})
    : _fetcher = fetcher;

  final FontCache cache;
  final FontFetcher _fetcher;

  final Map<String, FontOrigin> _known = {};
  final Set<String> _loaded = {};
  bool _working = false;

  /// جلب الخطوط من الشبكة. يُطفأ من الإعدادات لمن لا يريد طلبًا خارجيًا.
  bool fetchEnabled = true;

  bool get working => _working;

  /// حصيلة آخر حلّ، مرتّبة: المتعذّر أولًا لأنه ما يهمّ المستخدم.
  List<FontStatus> get statuses {
    final items = [
      for (final e in _known.entries) (family: e.key, origin: e.value),
    ];
    items.sort((a, b) {
      final byResolved = (a.origin.isResolved ? 1 : 0).compareTo(
        b.origin.isResolved ? 1 : 0,
      );
      return byResolved != 0 ? byResolved : a.family.compareTo(b.family);
    });
    return items;
  }

  List<FontStatus> get missing => [
    for (final s in statuses)
      if (!s.origin.isResolved) s,
  ];

  /// يحلّ كل الخطوط المطلوبة، ويحمّل ما أمكن.
  Future<void> resolveAll(Iterable<String> families) async {
    final wanted = {
      for (final f in families)
        if (f.trim().isNotEmpty) f.trim(),
    }..removeWhere(_known.containsKey);
    if (wanted.isEmpty) return;

    _working = true;
    notifyListeners();

    for (final family in wanted) {
      _known[family] = await _resolve(family);
    }

    _working = false;
    notifyListeners();
  }

  Future<FontOrigin> _resolve(String family) async {
    if (isBundled(family)) return FontOrigin.bundled;

    if (isFontAvailable(family)) return FontOrigin.system;

    final saved = cache.read(family);
    if (saved != null) {
      await _register(family, saved);
      return FontOrigin.cached;
    }

    if (!fetchEnabled) return _lastResort(family, FontOrigin.disabled);

    final result = await _fetcher.fetch(family);
    switch (result.outcome) {
      case FetchOutcome.fetched:
        await cache.write(family, result.bytes!);
        await _register(family, result.bytes!);
        return FontOrigin.fetched;
      case FetchOutcome.offline:
        return _lastResort(family, FontOrigin.offline);
      case FetchOutcome.notFound:
      case FetchOutcome.failed:
        return _lastResort(family, FontOrigin.unavailable);
    }
  }

  /// البديل المطابق مقاسيًّا آخر ما نجرّبه قبل إعلان العجز.
  ///
  /// **يُعلَن ولا يُخفى**: التخطيط سليم والحروف ليست حروف الخطّ المطلوب،
  /// فالمستخدم يستحقّ أن يعرف (`00` §5). ويبقى [failure] لما لا بديل له —
  /// «انقطع الاتصال» غير «لن نجده أبدًا»، والفرق يقرّر هل يعيد المحاولة.
  FontOrigin _lastResort(String family, FontOrigin failure) =>
      hasSubstitute(family) ? FontOrigin.substituted : failure;

  /// يسجّل الخطّ في محرّك الرسم كي تراه المعاينة فورًا، بلا إعادة تشغيل.
  Future<void> _register(String family, Uint8List bytes) async {
    if (!_loaded.add(family)) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    forgetFontProbe(family);
  }

  /// يضيف خطًّا من ملفّ اختاره المستخدم من قرصه.
  ///
  /// **الاسم من داخل الملفّ لا من اسمه.** «Cairo-Regular.ttf» عائلتها
  /// «Cairo»، وتسجيلها باسم الملفّ يجعل المستند الذي يطلب «Cairo» لا يجدها.
  ///
  /// يُرجع اسم العائلة، أو `null` إن لم يكن الملفّ خطًّا نقرأه.
  Future<String?> addFromFile(Uint8List bytes) async {
    final family = fontFamilyName(bytes);
    if (family == null) return null;

    await cache.write(family, bytes);
    await _register(family, bytes);
    _known[family] = FontOrigin.cached;
    notifyListeners();
    return family;
  }

  /// يحذف خطًّا محفوظًا. يبقى محمَّلًا حتى إعادة التشغيل — فهو في الذاكرة،
  /// ولا سبيل لتفريغه في Flutter. نقولها للمستخدم ولا نوهمه.
  void forget(CachedFont font) {
    cache.delete(font);
    _known.remove(font.family);
    notifyListeners();
  }

  void forgetAll() {
    cache.clear();
    _known.removeWhere(
      (_, origin) =>
          origin == FontOrigin.cached || origin == FontOrigin.fetched,
    );
    notifyListeners();
  }

  void setFetchEnabled(bool value) {
    if (fetchEnabled == value) return;
    fetchEnabled = value;
    // ما تعذّر بسبب الإطفاء يُعاد تقييمه عند التشغيل.
    _known.removeWhere(
      (_, origin) =>
          origin == FontOrigin.disabled ||
          origin == FontOrigin.offline ||
          origin == FontOrigin.unavailable,
    );
    notifyListeners();
  }
}
