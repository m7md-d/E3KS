/// حوار بحركة التطبيق الواحدة.
///
/// **لماذا لا `showDialog` مباشرةً؟** لأن حركتها من إعدادات Material لا من
/// [Motion]، فتختلف عن بقيّة التطبيق بفارقٍ تلتقطه العين ولا تسمّيه. وخمسة
/// مواضع تستدعيها تعني خمس فرص للانحراف.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

Future<T?> showAppDialog<T>(BuildContext context, WidgetBuilder builder) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Shade.scrim,
      transitionDuration: Motion.normal,
      pageBuilder: (context, _, _) => builder(context),
      transitionBuilder: (context, animation, _, child) {
        final eased = CurvedAnimation(
          parent: animation,
          curve: Motion.enter,
          reverseCurve: Motion.exit,
        );
        return FadeTransition(
          opacity: eased,
          child: ScaleTransition(
            // من 0.98 لا من 0.8: الحوار يستقرّ ولا يقفز. القفزة تُلاحَظ
            // مرّةً وتُزعج عشرًا.
            scale: Tween<double>(begin: 0.98, end: 1).animate(eased),
            child: child,
          ),
        );
      },
    );
