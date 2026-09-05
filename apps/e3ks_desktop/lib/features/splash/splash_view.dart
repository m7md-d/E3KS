/// شاشة الدخول.
///
/// **مقصودة قصيرة.** الشعار وانعكاسه على أرضية التطبيق، يظهران ويثبتان
/// ريثما تُفتح الإعدادات والهويات ومخزن الخطوط، ثمّ يتلاشيان إلى مساحة العمل.
///
/// لا شعار يكبر ثم يصغر، ولا وميض، ولا شريط تقدّم يتظاهر بالعمل. الحركة
/// الوحيدة هنا **ظهورٌ واحد** — لأن ما يُعرَض عند كل تشغيل يجب أن يحتمل أن
/// يُرى ألف مرّة.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/mirror_mark.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key, required this.name});

  /// اسم التطبيق. لا يُترجَم — هو علامة لا كلمة.
  final String name;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Shade.canvas,
    child: Center(
      child: Entrance(child: MirrorMark(name: name, size: 54)),
    ),
  );
}
