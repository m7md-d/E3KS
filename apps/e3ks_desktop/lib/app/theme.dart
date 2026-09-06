/// بناء الثيم من الرموز.
///
/// السماوي ليس زينة — التطبيق **يعكس** الهويات، والسماوي لون المرآة:
/// انعكاس بارد على سطح داكن.
///
/// **لا قيمة لون هنا.** كلها من `tokens.dart` — مرجع الحقيقة الواحد.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

export 'tokens.dart';

abstract final class Metrics {
  static const double radius = 10;
  static const double radiusSmall = 6;
  static const double gutter = 20;
  static const double sidebarWidth = 268;

  /// بكسل منطقي لكل نقطة طباعية. مرجع Flutter 96dpi والنقطة 1/72 بوصة،
  /// فتكبير ١٠٠٪ يعني **مقاس الورقة الحقيقي** لا مقاسًا اصطلاحيًّا.
  static const double pxPerPoint = 96 / 72;
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Shade.mirror,
    onPrimary: Shade.onMirror,
    secondary: Shade.mirrorSoft,
    surface: Shade.surface,
    onSurface: Shade.text,
    error: Shade.danger,
  );

  TextStyle body(
    double size, {
    FontWeight weight = Type.regular,
    Color? color,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color ?? Shade.text,
    fontFamily: Type.family,
    fontFamilyFallback: Type.fallback,
    height: 1.45,
    // **الفراغ يُوزَّع بالتساوي فوق الحرف وتحته.** التوزيع النِّسبي — وهو
    // الافتراضي — يعطي الفراغ لأعلى الصندوق، فينزل خطّ الأساس ويخرج ذيل
    // الحرف عن الصندوق فيُقصّ. رأينا ذلك في راء «اختر» داخل الزرّ:
    // الذيل مبتور، وبالتوزيع المتساوي يعود كاملًا وتباعد الأسطر كما هو.
    leadingDistribution: TextLeadingDistribution.even,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Shade.canvas,
    canvasColor: Shade.canvas,
    dividerColor: Shade.border,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: TextTheme(
      displaySmall: body(28, weight: Type.semiBold),
      headlineSmall: body(20, weight: Type.semiBold),
      titleMedium: body(15, weight: Type.semiBold),
      titleSmall: body(13, weight: Type.semiBold, color: Shade.textMuted),
      bodyLarge: body(14),
      bodyMedium: body(13),
      bodySmall: body(12, color: Shade.textMuted),
      labelLarge: body(13, weight: Type.semiBold),
      labelSmall: body(11, color: Shade.textFaint),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Shade.surfaceHigh,
        border: Border.all(color: Shade.borderStrong),
        borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      ),
      textStyle: body(12),
      waitDuration: Motion.tooltipDelay,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(8),
      radius: const Radius.circular(4),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? Shade.borderStrong
            : Shade.border,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Shade.mirror,
        foregroundColor: Shade.onMirror,
        disabledBackgroundColor: Shade.surfaceHover,
        disabledForegroundColor: Shade.textFaint,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: body(14, weight: Type.semiBold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Shade.text,
        side: const BorderSide(color: Shade.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: body(13, weight: Type.semiBold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Shade.mirror,
        textStyle: body(13, weight: Type.semiBold),
      ),
    ),
  );
}
