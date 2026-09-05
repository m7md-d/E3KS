// E3KS — اعكس. تطبيق سطح مكتب لعكس الهوية البصرية في المستندات.
// Copyright (C) 2026  m7md-d
//
// برنامج حرّ تحت رخصة جنو العمومية العامة، الإصدار الثالث أو أيّ إصدار
// لاحق. يُوزَّع بلا أيّ ضمان. النصّ الكامل في `LICENSE` بجذر المشروع.
import 'package:flutter/material.dart';

import 'app/about.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledLicenses();
  // بلا `await`: التهيئة تجري وشاشة الدخول معروضة، لا والنافذة بيضاء.
  runApp(const E3ksApp());
}
