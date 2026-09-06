/// أين يضع التطبيق بياناته على كل منصّة.
///
/// كان المسار مكتوبًا في ثلاثة مواضع بصيغة macOS وحدها
/// (`~/Library/Application Support`)، فيصنع على لينكس وويندوز مجلَّدًا غريبًا
/// في بيت المستخدم. المرجع الواحد هنا، وكل منصّة تأخذ ما تعارف عليه أهلها.
library;

import 'dart:io';

/// جذر بيانات التطبيق. لا يُنشئ شيئًا — الإنشاء عند من يحتاجه.
Directory appDataDirectory() {
  if (Platform.isMacOS) {
    return Directory('${_home()}/Library/Application Support/E3KS');
  }
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory('$appData\\E3KS');
    }
  }
  // لينكس وما شابهه: معيار XDG، وبديله المعلَن في المعيار نفسه.
  final xdg = Platform.environment['XDG_DATA_HOME'];
  if (xdg != null && xdg.isNotEmpty) return Directory('$xdg/E3KS');
  return Directory('${_home()}/.local/share/E3KS');
}

/// الجذر نفسه، مُنشأً.
Directory appDataRoot() => _ensure(appDataDirectory());

/// مجلَّد فرعي جاهز للكتابة.
Directory appDataSubdirectory(String name) => _ensure(
  Directory('${appDataDirectory().path}${Platform.pathSeparator}$name'),
);

Directory _ensure(Directory directory) {
  if (!directory.existsSync()) directory.createSync(recursive: true);
  return directory;
}

String _home() =>
    Platform.environment['HOME'] ??
    Platform.environment['USERPROFILE'] ??
    Directory.current.path;
