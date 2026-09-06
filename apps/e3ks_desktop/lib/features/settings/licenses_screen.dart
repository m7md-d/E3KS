/// شاشة رخص المكوّنات.
///
/// **لماذا شاشتنا لا `showLicensePage`؟** شاشة Material تبني تخطيط
/// «قائمة وتفصيل» فتتراكب لوحتاها على عرض سطح المكتب، وتحمل ترويستها هي
/// بعلامة «Powered by Flutter» — ترويسةٌ ليست ترويستنا في شاشةٍ تعرض حقوقنا.
///
/// وهنا قائمة واحدة تتوسّع عناصرها: لا لوحتين تتزاحمان، ولا تخطيط يتغيّر
/// بتغيّر العرض. والحركة كلّها من [Motion] كبقيّة التطبيق.
///
/// **والعرض محدود لا ممدود.** سطرٌ يمتدّ على شاشة عريضة يُتعِب العين: تفقد
/// بداية السطر التالي بعد نهاية الحالي. القياس المقروء 70–90 محرفًا، وهو
/// ما يقابل [_measure] هنا. الفراغ حول النصّ ليس ضياعًا للمساحة، هو ما
/// يجعلها مقروءة.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';

/// أقصى عرض للمحتوى: القياس المقروء لا عرض الشاشة.
const double _measure = 860;

/// حزمة واحدة ونصوص رخصها.
typedef LicenseGroup = ({String package, List<String> texts});

/// المسار كقيمة لا كإجراء: نحتاجه بعد إغلاق الحوار، وقتها يكون سياق الزرّ
/// قد بطل. من يملك `NavigatorState` يدفعه متى شاء.
Route<void> licensesRoute() => PageRouteBuilder<void>(
  transitionDuration: Motion.normal,
  reverseTransitionDuration: Motion.quick,
  pageBuilder: (_, _, _) => const LicensesScreen(),
  transitionsBuilder: (_, animation, _, child) {
    // ترتفع قليلًا وهي تظهر: الحركة تقول «جاءت من تحت» فيعرف المستخدم أين
    // تذهب حين تُغلَق. مسافة قصيرة عمدًا — تدلّ ولا تُشاهَد.
    final eased = CurvedAnimation(parent: animation, curve: Motion.enter);
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(eased),
        child: child,
      ),
    );
  },
);

/// يجمع رخص Flutter المسجَّلة ويضمّ ما تكرّرت حزمته.
Future<List<LicenseGroup>> collectLicenses() async {
  final byPackage = <String, List<String>>{};
  await for (final entry in LicenseRegistry.licenses) {
    final text = entry.paragraphs
        .map((p) => p.text.trim())
        .where((p) => p.isNotEmpty)
        .join('\n\n');
    for (final package in entry.packages) {
      byPackage.putIfAbsent(package, () => []).add(text);
    }
  }
  final names = byPackage.keys.toList()..sort();
  return [for (final name in names) (package: name, texts: byPackage[name]!)];
}

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  late final Future<List<LicenseGroup>> _licenses = collectLicenses();

  /// المفتوح حاليًّا. واحدٌ فقط: قائمة كلّها مفتوحة تفقد كونها قائمة.
  int _open = -1;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      backgroundColor: Shade.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder<List<LicenseGroup>>(
            future: _licenses,
            builder: (context, snapshot) => _Header(
              title: t.licensesTitle,
              hint: t.licensesHint,
              count: snapshot.data?.length,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LicenseGroup>>(
              future: _licenses,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _Note(text: t.licensesLoading);
                }
                final groups = snapshot.data!;
                if (groups.isEmpty) return _Note(text: t.licensesEmpty);

                return Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      Metrics.gutter,
                      10,
                      Metrics.gutter,
                      Metrics.gutter,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (context, i) => _Measured(
                      child: _PackageTile(
                        group: groups[i],
                        expanded: _open == i,
                        onTap: () =>
                            setState(() => _open = _open == i ? -1 : i),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ترويستنا: اسم الشاشة وزرّ الرجوع. بلا علامة طرف ثالث.
/// يحصر طفله في القياس المقروء ويوسّطه.
class _Measured extends StatelessWidget {
  const _Measured({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _measure),
      child: child,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.hint, this.count});
  final String title;
  final String hint;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, Metrics.gutter, 12),
      decoration: const BoxDecoration(
        color: Shade.surface,
        border: Border(bottom: BorderSide(color: Shade.border)),
      ),
      // الترويسة تتبع القياس نفسه، وإلّا انفصل عنوانها عن قائمتها على
      // الشاشة العريضة فبدا كلٌّ منهما في جهة.
      child: _Measured(
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(LucideIcons.arrowLeftDir, size: 17),
              color: Shade.textMuted,
              tooltip: t.back,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (count != null)
              Text(
                t.licenseEntries(count!),
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// حزمة واحدة: اسمها، وعدد رخصها، ونصوصها عند الفتح.
class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.group,
    required this.expanded,
    required this.onTap,
  });

  final LicenseGroup group;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: Motion.quick,
        curve: Motion.standard,
        decoration: BoxDecoration(
          color: expanded ? Shade.surfaceHigh : Shade.surface,
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          border: Border.all(
            color: expanded ? Shade.borderStrong : Shade.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(Metrics.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.package,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          color: expanded ? Shade.mirror : Shade.text,
                        ),
                      ),
                    ),
                    Text(
                      t.licenseEntries(group.texts.length),
                      style: text.labelSmall,
                    ),
                    const SizedBox(width: 8),
                    // السهم يدور بدل أن يُستبدل: الدوران يقول «هذا هو نفسه
                    // في حالة أخرى»، والاستبدال يقول «هذا شيء آخر».
                    //
                    // **والدوران يتبع الاتجاه كما تتبعه الأيقونة.** الأيقونة
                    // معكوسة في العربية، فدورانٌ موحّد يجعلها تشير إلى فوق
                    // بدل تحت. الانعكاس والدوران لا يتركّبان من تلقائهما.
                    AnimatedRotation(
                      turns: expanded
                          ? (Directionality.of(context) == TextDirection.rtl
                                ? -0.25
                                : 0.25)
                          : 0,
                      duration: Motion.quick,
                      curve: Motion.standard,
                      child: const Icon(
                        LucideIcons.chevronRightDir,
                        size: 15,
                        color: Shade.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // النصّ الطويل يُبنى عند الفتح فقط: أربعون حزمة بنصوصها كاملةً
            // في كل رسمة ثقلٌ بلا فائدة (`03`).
            AnimatedSize(
              duration: Motion.normal,
              curve: Motion.standard,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      // **نصّ الرخصة إنجليزي دائمًا، فاتجاهه ثابت.** تبديل
                      // لغة التطبيق لا يغيّر لغة النصّ، وعرضه من اليمين
                      // يبعثر ترقيمه وعلاماته ويكسر أسطره.
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: SelectableText(
                          group.texts.join('\n\n———\n\n'),
                          textAlign: TextAlign.left,
                          style: text.labelSmall?.copyWith(height: 1.6),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(text, style: Theme.of(context).textTheme.labelSmall));
}
