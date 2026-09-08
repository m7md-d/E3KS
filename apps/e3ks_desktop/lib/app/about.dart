// E3KS — اعكس.
// Copyright (C) 2026  m7md-d
//
// برنامج حرّ تحت رخصة جنو العمومية العامة، الإصدار الثالث أو أيّ إصدار
// لاحق. يُوزَّع بلا أيّ ضمان. النصّ الكامل في `LICENSE` بجذر المشروع.

/// ثوابت الهوية القانونية للتطبيق.
///
/// ليست نصًّا يُترجَم: رقم ورابط. ما يُترجَم من صياغة يسكن في ARB.
///
/// **رخصة GPL‑3 §5 تُلزم البرنامج التفاعلي بعرض إشعاراته**، فعرضها في
/// الإعدادات شرطُ ترخيص لا زينة.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/font_substitutes.dart';

/// يطابق `version` في `pubspec.yaml` — واختبارٌ يحرس التطابق.
const String appVersion = '0.2.1';

const String sourceUrl = 'https://github.com/m7md-d/E3KS';

/// نصّ رخصة الخطّ المضمَّن، ليظهر في «رخص المكوّنات» مع بقيّة الحزم.
///
/// OFL 1.1 تُلزم بشحن نصّ الرخصة مع الخطّ. نشحنه ونعرضه.
void registerBundledLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final family in bundledFamilies) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/OFL-${_slug(family)}.txt'));
    }
  });
}

/// اسم الملفّ من اسم العائلة: «IBM Plex Sans» ← «IBMPlexSans».
String _slug(String family) => family.replaceAll(' ', '');
