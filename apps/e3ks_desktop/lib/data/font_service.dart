/// حلّ خطوط المستند: أين هي، وهل تُجلَب، وماذا نقول للمستخدم إن تعذّرت.
///
/// المعاينة تَعِد بعرض الملف **بشكله الحقيقي**. خطٌّ ناقص يجعلها كاذبةً بصمت،
/// ولذلك لا يكفي أن نجلب — يجب أن نُبلّغ حين نعجز (`00` §5).
///
/// الترتيب: **مضمَّن في المستند** ← مشحون معنا ← منصَّب في النظام ← محفوظ
/// عندنا ← يُجلَب من الشبكة ← بديل مطابق مقاسيًّا.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'font_cache.dart';
import 'font_fetcher.dart';
import 'font_probe.dart';
import 'font_substitutes.dart';

/// من أين جاء الخطّ، أو لماذا لم يأتِ.
enum FontOrigin {
  /// حمله المستند في نفسه. **أصدقها**: حروف كاتبه، بلا شبكة ولا بديل.
  embedded,

  /// مضمَّن في التطبيق.
  bundled,

  /// منصَّب على جهاز المستخدم.
  system,

  /// من مجلد الخطوط الذي سمّاه المستخدم في الإعدادات.
  folder,

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
      this == FontOrigin.embedded ||
      this == FontOrigin.bundled ||
      this == FontOrigin.system ||
      this == FontOrigin.folder ||
      this == FontOrigin.cached ||
      this == FontOrigin.fetched ||
      this == FontOrigin.substituted;
}

typedef FontStatus = ({String family, FontOrigin origin});

/// يحلّ الخطوط ويحمّلها وقت التشغيل، ويحتفظ بحصيلة آخر عملية.
class FontService extends ChangeNotifier {
  FontService(
    this.cache, {
    FontFetcher fetcher = const GoogleFontFetcher(),
    FontFetcher? folder,
  }) : _fetcher = fetcher,
       _folder = folder;

  final FontCache cache;
  final FontFetcher _fetcher;

  /// مزوّدٌ من قرص المستخدم، يُسأل قبل الشبكة ولا يحكمه مفتاح الجلب.
  final FontFetcher? _folder;

  final Map<String, FontOrigin> _known = {};
  final Set<String> _loaded = {};
  bool _working = false;
  bool _retrying = false;

  /// جلب الخطوط من الشبكة. يُطفأ من الإعدادات لمن لا يريد طلبًا خارجيًا.
  bool fetchEnabled = true;

  bool get working => _working;

  /// هل الجاري إعادةُ محاولةٍ طلبها المستخدم من الإعدادات؟
  ///
  /// **الأثر يظهر حيث وقع الفعل.** بلا هذا التمييز يضيء شريط المعاينة
  /// «جارٍ جلب الخطوط» لضغطةٍ وقعت في نافذة الإعدادات.
  bool get retrying => _retrying;

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

  /// يعيد محاولة ما لم يُحلّ.
  ///
  /// **العجز حالٌ لا حكم.** انقطاعٌ لحظيّ عند بدء التشغيل — والشبكة لم تصل
  /// بعد — كان يبقى إلى آخر الجلسة: الحصيلة محفوظة، والمحاولة لا تتكرّر.
  /// وإضافةُ مجلد خطوطٍ أو ملفٍّ فيه تغيّر الجواب كذلك.
  Future<void> retryMissing() async {
    final again = [
      for (final status in statuses)
        if (!status.origin.isResolved) status.family,
    ];
    if (again.isEmpty) return;
    _known.removeWhere((_, origin) => !origin.isResolved);
    _retrying = true;
    try {
      await resolveAll(again);
    } finally {
      _retrying = false;
      notifyListeners();
    }
  }

  /// يتبنّى ما ضمّنه المستند في نفسه، قبل أي بحثٍ عن بديل.
  ///
  /// **ولا يُحفَظ على القرص.** المضمَّن حقّ هذا المستند: يُحمَّل في الذاكرة
  /// لرسم معاينته، ولا يُوزَّع ولا يبقى بعده. وحفظُه في `FontCache` يجعله
  /// خطًّا عندنا لمستنداتٍ أخرى — وهو ما لا يُخوّلنا إياه أحد.
  Future<void> adoptEmbedded(Iterable<EmbeddedFont> fonts) async {
    final byFamily = <String, List<EmbeddedFont>>{};
    for (final font in fonts) {
      byFamily.putIfAbsent(font.family.trim(), (() => [])).add(font);
    }
    if (byFamily.isEmpty) return;

    for (final entry in byFamily.entries) {
      if (_loaded.contains(entry.key)) continue;
      final loader = FontLoader(entry.key);
      for (final font in entry.value) {
        loader.addFont(Future.value(ByteData.sublistView(font.bytes)));
      }
      await loader.load();
      _loaded.add(entry.key);
      forgetFontProbe(entry.key);
      _known[entry.key] = FontOrigin.embedded;
    }
    notifyListeners();
  }

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

    // **قرص المستخدم قبل الشبكة**: أسرع، وبلا طلب خارجي، وهو الطريق الوحيد
    // إلى خطٍّ مملوك يملكه هو. ولا يُحفَظ عندنا: ملفّه في مكانه.
    final local = _folder;
    if (local != null) {
      final result = await local.fetch(family);
      if (result.outcome == FetchOutcome.fetched) {
        await _register(family, result.bytes!);
        return FontOrigin.folder;
      }
    }

    if (!fetchEnabled) return await _lastResort(family, FontOrigin.disabled);

    final result = await _fetcher.fetch(family);
    switch (result.outcome) {
      case FetchOutcome.fetched:
        await cache.write(family, result.bytes!);
        await _register(family, result.bytes!);
        return FontOrigin.fetched;
      case FetchOutcome.offline:
        return await _lastResort(family, FontOrigin.offline);
      case FetchOutcome.notFound:
      case FetchOutcome.failed:
        return await _lastResort(family, FontOrigin.unavailable);
    }
  }

  /// البديل المطابق مقاسيًّا آخر ما نجرّبه قبل إعلان العجز.
  ///
  /// **يُعلَن ولا يُخفى**: التخطيط سليم والحروف ليست حروف الخطّ المطلوب،
  /// فالمستخدم يستحقّ أن يعرف (`00` §5). ويبقى [failure] لما لا بديل له —
  /// «انقطع الاتصال» غير «لن نجده أبدًا»، والفرق يقرّر هل يعيد المحاولة.
  ///
  /// **والبديل المجلوب يُجلب كما يُجلب أي خطّ.** بعضها مشحون معنا وبعضها
  /// على القنوات العامّة، فالوعد به قبل وصوله يجعل الرقاقة تقول «بديل
  /// مطابق» والصفحة مرسومة بخطّ التطبيق.
  Future<FontOrigin> _lastResort(String family, FontOrigin failure) async {
    final stand = substituteFor(family);
    if (stand == null) return failure;
    if (isBundled(stand) || _loaded.contains(stand)) {
      return FontOrigin.substituted;
    }
    if (isFontAvailable(stand)) return FontOrigin.substituted;

    final saved = cache.read(stand);
    if (saved != null) {
      await _register(stand, saved);
      return FontOrigin.substituted;
    }

    if (!fetchEnabled) return failure;
    final result = await _fetcher.fetch(stand);
    if (result.outcome != FetchOutcome.fetched) return failure;
    await cache.write(stand, result.bytes!);
    await _register(stand, result.bytes!);
    return FontOrigin.substituted;
  }

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
