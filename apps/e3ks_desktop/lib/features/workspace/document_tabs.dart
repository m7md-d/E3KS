/// شريط تبويبات المستندات المفتوحة.
///
/// يظهر فقط عند فتح ملف ثانٍ — الملف الواحد لا يحتاج تبويبًا، وإظهاره
/// دائمًا يسرق سطرًا من المعاينة بلا مقابل.
///
/// **وهو غير الشجرة.** الشريط ما فُتح للنظر، والشجرة المجموعة كلّها. إغلاق
/// تبويبٍ هنا يُخفي ملفَّه عن النظر ولا يُخرجه من العمل — كما في محرّرات
/// الأكواد تمامًا.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../data/workspace_store.dart';

/// تبويبٌ في الشريط، ومعه حالُ مغادرته.
///
/// **يبقى بعد إغلاقه حتى تنتهي حركته.** المخزَن يُخرجه من `openTabs` فورًا،
/// فلو تبع الشريطُ المخزَنَ حرفيًّا لاختفى التبويب في إطارٍ واحد وقفزت
/// بقيّته إلى مكانه. فالشريط يحمل نسخته من الترتيب، يتأخّر عن المخزَن
/// بمقدار حركةٍ واحدة.
///
/// **والاسم منسوخ لا مقروء.** الإخراج التامّ من المجموعة يحذف الملفّ من
/// المخزَن، فلا يبقى ما يُقرأ منه اسمُ تبويبٍ ما زال على الشاشة.
final class _Slot {
  _Slot(this.path, this.label);

  final String path;
  final String label;
  bool closing = false;
}

class DocumentTabs extends StatefulWidget {
  const DocumentTabs({super.key, required this.store, required this.onAdd});

  final WorkspaceStore store;
  final VoidCallback onAdd;

  @override
  State<DocumentTabs> createState() => _DocumentTabsState();
}

class _DocumentTabsState extends State<DocumentTabs> {
  final List<_Slot> _slots = [];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(DocumentTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // المخزَن يُشعر، فتُعاد الشاشة كلّها ويصل التغيّر هنا. والمزامنة خارج
    // `build` لأنها تُعدّل حالًا.
    _sync();
  }

  void _sync() {
    final store = widget.store;
    final live = <String, String>{
      for (final index in store.openTabs)
        store.files[index].document.path: store.files[index].document.fileName,
    };

    for (final slot in _slots) {
      // العائد قبل انتهاء حركته يرجع بها نفسها معكوسة، ولا يُضاف مرّتين.
      slot.closing = !live.containsKey(slot.path);
    }
    for (final entry in live.entries) {
      if (!_slots.any((slot) => slot.path == entry.key)) {
        _slots.add(_Slot(entry.key, entry.value));
      }
    }
  }

  void _drop(String path) {
    if (!mounted) return;
    setState(() => _slots.removeWhere((s) => s.closing && s.path == path));
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final t = context.l10n;
    // **العدّ من نسخة الشريط لا من المخزَن**: تبويبٌ يغادر ما زال يشغل
    // مكانه، وإخفاء الشريط قبل خروجه يُلغي حركته.
    final showing = _slots.length >= 2;
    final index = <String, int>{
      for (var i = 0; i < store.files.length; i++)
        store.files[i].document.path: i,
    };

    // **والشريط نفسه ينزل ويصعد بحركة.** ظهوره باختفائه قفزةٌ في ارتفاع
    // الشاشة كلّها، والمعاينة تحته تقفز معه.
    return AnimatedSize(
      duration: Motion.normal,
      curve: Motion.standard,
      alignment: Alignment.topCenter,
      child: !showing
          ? const SizedBox(width: double.infinity)
          : Container(
              height: 40,
              decoration: const BoxDecoration(
                color: Shade.canvas,
                border: Border(bottom: BorderSide(color: Shade.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      itemCount: _slots.length,
                      // **بلا هذه ينهار الجار ويُعاد نفخه.** سقوطُ المغادر
                      // يُنقص العدد، فيبني المزوّد الفهرس بالفهرس ولا يعرف
                      // أن ودجة الفهرس الجديد هي ودجة القديم بمفتاحها —
                      // فيهدم عنصرها ويبني غيره، وتبدأ حركته من الصفر:
                      // يختفي الجار ثم ينفتح بدل أن ينزلق. وهذه تردّ
                      // المفتاح إلى موضعه فيُنقَل العنصر ولا يُهدَم.
                      findChildIndexCallback: (key) {
                        final path = (key as ValueKey<String>).value;
                        final at = _slots.indexWhere((s) => s.path == path);
                        return at < 0 ? null : at;
                      },
                      itemBuilder: (context, i) {
                        final slot = _slots[i];
                        final at = index[slot.path];
                        return _Sliding(
                          key: ValueKey(slot.path),
                          closing: slot.closing,
                          onGone: () => _drop(slot.path),
                          child: _Tab(
                            label: slot.label,
                            changes: at == null ? 0 : store.changeCountAt(at),
                            selected: at != null && at == store.activeIndex,
                            onTap: at == null
                                ? null
                                : () => store.selectDocument(at),
                            onClose: at == null
                                ? null
                                : () => store.closeTab(at),
                          ),
                        );
                      },
                    ),
                  ),
                  // **الموضع من العدد**: شريطٌ يُمرَّر داخله يُخفي أين أنت منه.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      t.tabPosition(store.activeTab + 1, store.openTabs.length),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  Tooltip(
                    message: t.chooseFile,
                    child: IconButton(
                      onPressed: widget.onAdd,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      color: Shade.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
    );
  }
}

/// تبويبٌ يدخل بالانزلاق ويخرج به، فينزلق جيرانه إلى مكانه.
///
/// **بلا متحكّم ولا مؤقّت** (`07` §7): `TweenAnimationBuilder` يحمل حركته،
/// و`onEnd` هو إشارة الانتهاء — فلا مؤقّتٌ معلَّق يُسقط اختبارًا لا ينتظر
/// الاستقرار.
///
/// **والعرض يُقصّ بمُعامل لا يُحسَب برقم.** عرض التبويب من طول اسمه، فلا
/// رقم يُحرَّك إليه؛ و`Align` بمُعامل عرضٍ يقصّ ما بين الكامل والصفر مهما
/// كان الأصل.
/// أين ينتهي الاختفاء ويبدأ الطيّ من المدّة. النصف: لكلٍّ ١١٠ms من ٢٢٠.
const double _split = 0.5;

class _Sliding extends StatelessWidget {
  const _Sliding({
    super.key,
    required this.closing,
    required this.onGone,
    required this.child,
  });

  final bool closing;
  final VoidCallback onGone;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: closing ? 0 : 1),
    // **`normal` لا `quick`**: الجدول في `07` §7 يضع التبويب هنا. و`quick`
    // زمنُ زرٍّ يستجيب، وهذا انزلاقُ صفٍّ تتبعه العين.
    duration: Motion.normal,
    // **و`standard` في الاتجاهين.** `exit` يتسارع مغادرًا فيقف التبويب
    // ستّين جزءًا من الثانية بلا حراك يُذكر ثم ينهار دفعةً — مقيسًا:
    // ١٨٢ ← ١٦٣ في أوّل الثلث، ثم ١١٢ ← ٠ في آخره. وهذا تغيّرٌ في مكانه.
    curve: Motion.standard,
    onEnd: closing ? onGone : null,
    child: child,
    builder: (context, extent, child) {
      // **حركتان بالتتابع لا بالتزامن**: يختفي التبويب أوّلًا، **ثمّ** ينزلق
      // جيرانه إلى مكانه. وبالتزامن يُقصّ اسمُه نصفَ كلمة وهو ما زال ظاهرًا،
      // فيبدو الشريط منكسرًا لا منسحبًا.
      final gone = 1 - extent;
      final fade = (1 - gone / _split).clamp(0.0, 1.0);
      final width = (1 - (gone - _split) / (1 - _split)).clamp(0.0, 1.0);
      return ClipRect(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: width,
          child: Opacity(opacity: fade, child: child),
        ),
      );
    },
  );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.changes,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final String label;
  final int changes;
  final bool selected;

  /// **يصيران `null` للمغادر**: تبويبٌ خرج من المخزَن لا يُختار ولا يُغلق
  /// ثانيةً، وضغطةٌ عليه في آخر حركته تطلب ملفًّا ليس هناك.
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Material(
      color: selected ? Shade.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        hoverColor: Shade.surfaceHover,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 230),
          padding: const EdgeInsets.only(left: 6, right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Metrics.radiusSmall),
            border: Border.all(
              color: selected ? Shade.mirrorSoft : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.fileText,
                size: 13,
                color: selected ? Shade.mirror : Shade.textFaint,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: selected ? Shade.text : Shade.textMuted,
                    fontWeight: selected ? Type.semiBold : Type.regular,
                  ),
                ),
              ),
              if (changes > 0) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Shade.mirror,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(3),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(LucideIcons.x, size: 12, color: Shade.textFaint),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
