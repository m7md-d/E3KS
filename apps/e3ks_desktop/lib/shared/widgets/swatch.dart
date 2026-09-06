/// عيّنة لون: مربّع يُظهر اللون نفسه.
///
/// العيّنة البصرية ليست تزيينًا — «#4C2FB8» لا تعني شيئًا لموظف مكتبي،
/// والمربّع الملوّن يعني كل شيء.
library;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

Color toFlutter(HexColor hex) =>
    Color(int.parse('FF${hex.ooxmlValue}', radix: 16));

/// الاتجاه المعاكس: من لون واجهة إلى لون المحرّك.
///
/// يلزم حين نقارن ما رُسم على الشاشة بألوان المستند — التقاط اللون من
/// المعاينة مثلًا. القناة الشفافة تُسقَط، فالمقارنة على RGB وحده.
HexColor fromFlutter(Color color) =>
    // `!` مضمون: ثمانية محارف سداسية دائمًا، وهو ما يقبله `tryParse`.
    HexColor.tryParse(color.toARGB32().toRadixString(16).padLeft(8, '0'))!;

class Swatch extends StatelessWidget {
  const Swatch({
    super.key,
    required this.color,
    this.size = 34,
    this.onTap,
    this.selected = false,
    this.dashed = false,
  });

  final HexColor? color;
  final double size;
  final VoidCallback? onTap;
  final bool selected;

  /// حدّ متقطّع = «بلا لون بعد»، حالة فارغة مفهومة بلا كلمات.
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final fill = color;
    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill == null ? Shade.surfaceHover : toFlutter(fill),
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        border: Border.all(
          color: selected
              ? Shade.mirror
              : (dashed ? Shade.borderStrong : Shade.border),
          width: selected ? 2 : 1,
        ),
      ),
      child: fill == null
          ? const Icon(Icons.add_rounded, size: 16, color: Shade.textFaint)
          : null,
    );

    if (onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
