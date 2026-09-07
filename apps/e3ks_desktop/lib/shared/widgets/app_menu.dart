/// قائمة الاختيار الواحدة في التطبيق.
///
/// **لا تُخترَع قائمة.** `PopupMenuButton` من Material قائمة وتحمل ما لا يُرى:
/// التموضع داخل الشاشة، وحبس التركيز، والإغلاق بالمفتاح، والحركة، وقراءة
/// قارئ الشاشة. الذي كان ينقصها هويتنا — والهوية تُضبط مرّةً في
/// `popupMenuTheme`، والعنصر يُبنى هنا.
///
/// **ولماذا مكوّن فوق الثيم؟** لأن الثيم يضبط الصندوق ولا يضبط ما بداخله:
/// `CheckedPopupMenuItem` من Material يرسم علامته بأيقونة Material على
/// أرضيتنا فلا تكاد تُرى، وكل نداء كان يعيد تأليف صفّه — فاختلفت قائمة
/// اللغة عن قائمة الملفّ عن قائمة الأقسام. **البيانات تُمرَّر، والعرض من
/// هنا وحده.**
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';

/// عنصرٌ في قائمة اختيار: خيارٌ أو فاصل.
sealed class AppMenuEntry<T> {
  const AppMenuEntry();
}

final class AppMenuChoice<T> extends AppMenuEntry<T> {
  const AppMenuChoice({
    required this.value,
    required this.label,
    this.selected = false,
  });

  final T value;
  final String label;

  /// مختارٌ الآن، أو حالٌ قائمة — تُرسَم علامةً في صدر الصفّ.
  final bool selected;
}

final class AppMenuSeparator<T> extends AppMenuEntry<T> {
  const AppMenuSeparator();
}

/// ارتفاع الصفّ: أقلّ من ٤٨ الافتراضية، فأداتنا مكتبية تُقرأ قوائمها بسرعة.
const double _rowHeight = 34;

List<PopupMenuEntry<T>> _entries<T>(List<AppMenuEntry<T>> items) => [
  for (final item in items)
    switch (item) {
      AppMenuSeparator<T>() => const PopupMenuDivider(height: 9),
      AppMenuChoice<T>(:final value, :final label, :final selected) =>
        PopupMenuItem<T>(
          value: value,
          height: _rowHeight,
          // `PopupMenuItem` تقبل حشوةً غير اتجاهية، والمتناظرة تصحّ
          // في الاتجاهين معًا.
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _ChoiceRow(label: label, selected: selected),
        ),
    },
];

/// زرٌّ يفتح قائمة اختيار. [items] تُقرأ عند الفتح، فحالُ الخيارات لحظتَه.
class AppMenuButton<T> extends StatelessWidget {
  const AppMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.tooltip,
    this.onOpened,
    this.onClosed,
  });

  final ValueGetter<List<AppMenuEntry<T>>> items;
  final ValueChanged<T> onSelected;
  final Widget child;
  final String? tooltip;

  /// **يلزمان لمن يُظهر الزرّ عند التصويب.** خروج المؤشّر إلى القائمة يُنهي
  /// التصويب، فإن أُزيل الزرّ عندها وُصف بأنه غير مركَّب — و`PopupMenuButton`
  /// **تُسقط الاختيار صامتةً** إن لم يكن زرّها مركَّبًا لحظةَ وصوله.
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    tooltip: tooltip,
    padding: EdgeInsets.zero,
    onSelected: (value) {
      onClosed?.call();
      onSelected(value);
    },
    onOpened: onOpened,
    onCanceled: onClosed,
    itemBuilder: (_) => _entries(items()),
    child: child,
  );
}

/// يفتح القائمة عند نقطةٍ بعينها — للضغطة اليمنى.
Future<T?> showAppMenu<T>({
  required BuildContext context,
  required Offset at,
  required List<AppMenuEntry<T>> items,
}) {
  // `!` مضمون: للسياق طبقةٌ عائمة، وإلّا تعذّر عرض أي قائمة أصلًا.
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(at & Size.zero, Offset.zero & overlay.size),
    items: _entries(items),
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      // **الصدر محجوز علامةً كان أو فراغًا**، فلا تزحف الأسماء حين يتغيّر
      // الاختيار.
      SizedBox(
        width: 18,
        child: selected
            ? const Icon(LucideIcons.check, size: 13, color: Shade.mirror)
            : null,
      ),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? Type.semiBold : Type.regular,
            color: selected ? Shade.mirror : Shade.text,
          ),
        ),
      ),
    ],
  );
}
