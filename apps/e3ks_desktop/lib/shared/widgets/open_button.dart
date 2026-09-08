/// بابُ الفتح: ملفات أو مجلد، من زرٍّ واحد.
///
/// **الحصر بالملفات قيدٌ من الأداة لا من المستخدم.** حوار النظام يختار
/// أحدهما لا كليهما على المنصّات الثلاث، و`file_selector` تثبّت
/// `canChooseDirectories` في كل نداء — فالسؤال يُطرح عندنا قبل الحوار،
/// ويبقى للزرّ اسمه ومكانه.
library;

import 'package:flutter/widgets.dart';

import '../../app/l10n_extensions.dart';
import 'app_menu.dart';

class OpenButton extends StatelessWidget {
  const OpenButton({
    super.key,
    required this.child,
    required this.onFiles,
    required this.onFolder,
    this.enabled = true,
  });

  /// **مظهرٌ لا فعل**: الضغطة تفتح القائمة، فلا يبتلعها الزرّ الداخلي.
  final Widget child;
  final VoidCallback onFiles;
  final VoidCallback onFolder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return IgnorePointer(child: child);
    final t = context.l10n;
    return AppMenuButton<bool>(
      tooltip: t.chooseFile,
      onSelected: (folder) => folder ? onFolder() : onFiles(),
      items: () => [
        AppMenuChoice(value: false, label: t.addFiles),
        AppMenuChoice(value: true, label: t.addFolder),
      ],
      child: IgnorePointer(child: child),
    );
  }
}
