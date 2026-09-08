/// مستعرض النظام: ملفات ومجلدات في لوحة واحدة.
///
/// **القيد كان من الأداة لا من النظام.** `file_selector` تفتح أحدهما لا
/// كليهما — تثبّت `canChooseDirectories` في كل نداء — فيُطلَب من المستخدم أن
/// يقرّر قبل أن يرى ما عنده. و AppKit يقدر على الاثنين، فنسأله مباشرةً.
///
/// **وما لا قناة له يسقط إلى حوار الملفات**: ويندوز ولينكس لا يخلطان
/// الاثنين في لوحة واحدة أصلًا، وزرّ المجلد قائمٌ في رأس الشجرة عندهما.
library;

import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('e3ks/open');

/// المسارات التي اختارها المستخدم — ملفات أو مجلدات أو الاثنان.
///
/// قائمة فارغة إن ألغى، و`null` إن لم تكن اللوحة متاحة على هذه المنصّة.
Future<List<String>?> pickFilesOrFolders(List<String> extensions) async {
  try {
    final picked = await _channel.invokeListMethod<String>(
      'pickAny',
      extensions,
    );
    return picked ?? const [];
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}
