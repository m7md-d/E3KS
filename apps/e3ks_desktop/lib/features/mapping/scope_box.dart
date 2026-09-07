/// مربّع «خاصّ بهذا الملفّ» — على القاعدة نفسها، لا في رأس اللوحة.
///
/// **موضعه هو معناه** ([`ADR 0005`](../../../../../docs/adr/0005-مجموعة-العمل.md) §٢):
/// مبدّلٌ في رأس اللوحة يقول «التالي عامّ» فيصير حالةً يحملها المستخدم في
/// رأسه ويخطئ فيها؛ ومربّعٌ على القاعدة يقول عنها هي، ويُقرأ بعد أسبوع كما
/// كُتب اليوم.
///
/// **وهو مؤشّرٌ قبل أن يكون فعلًا.** من يتصفّح الملفّ السابع يرى لونًا بُدّل،
/// وبلا هذا المربّع لا يعرف أقاعدةٌ عامّة بدّلته أم قرارٌ منه هنا — فيرفعه
/// ظانًّا أنه محلّي، ويرفعه عن أربعين ملفًا.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';

class ScopeBox extends StatelessWidget {
  const ScopeBox({
    super.key,
    required this.specific,
    required this.onChanged,
    this.excluded = false,
  });

  /// القاعدة تسكن طبقة هذا الملفّ.
  final bool specific;

  /// استثناءٌ صريح من قاعدة عامّة: «هذا اللون يبقى». يُسمّى لئلّا يبدو الصفّ
  /// كأنه لم يُمَسّ.
  final bool excluded;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Tooltip(
        message: specific ? t.scopeFileOnlyOn : t.scopeFileOnlyOff,
        child: InkWell(
          onTap: () => onChanged(!specific),
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          hoverColor: Shade.surfaceHover,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 8, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: Motion.instant,
                  curve: Motion.standard,
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: specific ? Shade.mirror : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: specific ? Shade.mirror : Shade.border,
                    ),
                  ),
                  child: specific
                      ? const Icon(
                          LucideIcons.check,
                          size: 10,
                          color: Shade.onMirror,
                        )
                      : null,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    excluded ? t.scopeExcluded : t.scopeFileOnly,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: specific ? Type.semiBold : Type.regular,
                      color: specific ? Shade.mirror : Shade.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
