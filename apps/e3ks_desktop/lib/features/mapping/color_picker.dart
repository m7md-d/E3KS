/// منتقي ألوان مكتوب هنا لا مستورد.
///
/// مبني لهذه الحاجة تحديدًا: مستخدم يحمل لون هوية جاهزًا (‏#00635D‎) ويريد
/// لصقه، أو يريد اختياره بصريًا. الحقل النصّي أولًا لأنه الحالة الأشيع.
library;

import 'dart:math' as math;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../shared/widgets/app_dialog.dart';
import '../../app/l10n_extensions.dart';
import '../../data/identity.dart';
import '../../app/theme.dart';
import '../../shared/widgets/swatch.dart';

/// يفتح المنتقي ويُرجع اللون المختار، أو `null` عند الإلغاء،
/// أو [HexColor] الأصلي عند طلب إزالة التبديل.
Future<HexColor?> pickColor(
  BuildContext context, {
  required HexColor original,
  HexColor? current,
  List<QuickPickGroup> quickPicks = const [],
}) => showAppDialog<HexColor?>(
  context,
  (_) => _ColorDialog(
    original: original,
    current: current,
    quickPicks: quickPicks,
  ),
);

/// ألوان مسمّاة من مصدر واحد: هوية محفوظة، أو هوية مستخرَجة من ملفّ مفتوح.
typedef QuickPickGroup = ({String source, List<NamedColor> colors});

class _ColorDialog extends StatefulWidget {
  const _ColorDialog({
    required this.original,
    this.current,
    this.quickPicks = const [],
  });

  final HexColor original;
  final HexColor? current;

  /// **الاختيار السريع.** ألوان مسمّاة من الهويات المحفوظة ومن الملفات
  /// المفتوحة، مرتّبةً كما استُخرجت. الغرض ألّا يبني المستخدم كل لون في
  /// وقته: أغلب الحالات لصقُ لون هوية جاهز، لا تأليف لون جديد.
  final List<QuickPickGroup> quickPicks;

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late HSVColor _hsv;
  late final TextEditingController _hexField;

  @override
  void initState() {
    super.initState();
    final start = toFlutter(widget.current ?? widget.original);
    _hsv = HSVColor.fromColor(start);
    _hexField = TextEditingController(text: _hex);
  }

  @override
  void dispose() {
    _hexField.dispose();
    super.dispose();
  }

  String get _hex {
    final c = _hsv.toColor();
    String two(double v) =>
        (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${two(c.r)}${two(c.g)}${two(c.b)}'.toUpperCase();
  }

  HexColor get _selected => HexColor.tryParse(_hex)!;

  void _setFromHex(String raw) {
    final parsed = HexColor.tryParse(raw);
    if (parsed == null) return;
    setState(() => _hsv = HSVColor.fromColor(toFlutter(parsed)));
  }

  void _setHsv(HSVColor value) {
    setState(() => _hsv = value);
    _hexField.value = TextEditingValue(
      text: _hex,
      selection: TextSelection.collapsed(offset: _hex.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.l10n;
    final contrast = _selected.contrastWith(HexColor.tryParse('FFFFFF')!);

    return Dialog(
      backgroundColor: Shade.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Metrics.radius),
        side: const BorderSide(color: Shade.border),
      ),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(Metrics.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Swatch(color: widget.original, size: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      LucideIcons.moveLeft,
                      size: 16,
                      color: Shade.textFaint,
                    ),
                  ),
                  Swatch(color: _selected, size: 30, selected: true),
                  const Spacer(),
                  Text(t.replacementColor, style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              _SaturationBox(hsv: _hsv, onChanged: _setHsv),
              const SizedBox(height: 12),
              _HueSlider(hsv: _hsv, onChanged: _setHsv),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: _hexField,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(7),
                        FilteringTextInputFormatter.allow(
                          RegExp('[#0-9a-fA-F]'),
                        ),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Shade.canvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Metrics.radiusSmall,
                          ),
                          borderSide: const BorderSide(color: Shade.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            Metrics.radiusSmall,
                          ),
                          borderSide: const BorderSide(color: Shade.border),
                        ),
                      ),
                      onChanged: _setFromHex,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selected.describe(t),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        // التباين ليس ترفًا: نصّ فاتح على خلفية فاتحة يختفي.
                        Text(
                          contrast >= 4.5
                              ? t.contrastReadable(contrast.toStringAsFixed(1))
                              : t.contrastLow(contrast.toStringAsFixed(1)),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: contrast >= 4.5
                                ? Shade.success
                                : Shade.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // **درجات اللون الحالي.** المستخدم اختار لونه، وغالبًا يريد
              // أفتح منه للخلفية وأغمق للنصّ. نحسبها له بدل أن يفتح أداة
              // تصميم — والدرجة المُعلَّمة هي لونه نفسه لا تقريبٌ له.
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(t.shadesOf, style: theme.textTheme.labelSmall),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      t.shadesHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Shade.textFaint,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Ramp(
                base: HexColor.tryParse(_hex) ?? widget.original,
                selected: _hex,
                onPick: (color) =>
                    _setHsv(HSVColor.fromColor(toFlutter(color))),
              ),
              for (final group in widget.quickPicks)
                if (group.colors.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(group.source, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final named in group.colors)
                        // الاسم في التلميح لا تحته: صفٌّ من مربّعات صغيرة
                        // أسرع مسحًا بالعين من صفٍّ من بطاقات معنونة.
                        Tooltip(
                          message: '${named.name} · ${named.hex.value}',
                          child: Swatch(
                            color: named.hex,
                            size: 26,
                            selected: named.hex.value == _hex,
                            onTap: () => _setHsv(
                              HSVColor.fromColor(toFlutter(named.hex)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              const SizedBox(height: 22),
              Row(
                children: [
                  if (widget.current != null)
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(widget.original),
                      child: Text(t.removeMapping),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(t.confirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مربّع الإشباع والسطوع.
class _SaturationBox extends StatelessWidget {
  const _SaturationBox({required this.hsv, required this.onChanged});
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      void handle(Offset local) {
        final s = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
        final v = 1 - (local.dy / 170).clamp(0.0, 1.0);
        onChanged(hsv.withSaturation(s).withValue(v));
      }

      return GestureDetector(
        onPanDown: (d) => handle(d.localPosition),
        onPanUpdate: (d) => handle(d.localPosition),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Metrics.radiusSmall),
          child: SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _SaturationPainter(hsv),
              size: Size.infinite,
            ),
          ),
        ),
      );
    },
  );
}

class _SaturationPainter extends CustomPainter {
  const _SaturationPainter(this.hsv);
  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Picker.white, HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor()],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Picker.transparent, Picker.black],
        ).createShader(rect),
    );

    final center = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Picker.cursor,
    );
    canvas.drawCircle(
      center,
      9.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Picker.cursorRing,
    );
  }

  @override
  bool shouldRepaint(_SaturationPainter old) => old.hsv != hsv;
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hsv, required this.onChanged});
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      void handle(Offset local) {
        final ratio = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
        onChanged(hsv.withHue(ratio * 360));
      }

      return GestureDetector(
        onPanDown: (d) => handle(d.localPosition),
        onPanUpdate: (d) => handle(d.localPosition),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 18,
            child: CustomPaint(
              painter: _HuePainter(hsv.hue),
              size: Size.infinite,
            ),
          ),
        ),
      );
    },
  );
}

class _HuePainter extends CustomPainter {
  const _HuePainter(this.hue);
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var i = 0; i <= 6; i++)
              HSVColor.fromAHSV(1, i * 60.0 % 360, 1, 1).toColor(),
          ],
        ).createShader(rect),
    );
    final x = (hue / 360) * size.width;
    canvas.drawCircle(
      Offset(x.clamp(4.0, size.width - 4), size.height / 2),
      math.min(7, size.height / 2 - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Picker.cursor,
    );
  }

  @override
  bool shouldRepaint(_HuePainter old) => old.hue != hue;
}

/// سلَّم درجات اللون الحالي.
///
/// يُحسب في المحرّك (`tonalRamp`) لا هنا: حسابُ لونٍ منطقٌ قابل للاختبار بلا
/// واجهة، ومكانه حيث تُختبَر بقيّة حسابات الألوان.
class _Ramp extends StatelessWidget {
  const _Ramp({
    required this.base,
    required this.selected,
    required this.onPick,
  });

  final HexColor base;

  /// اللون المختار الآن، بصيغة `#RRGGBB`.
  final String selected;

  final ValueChanged<HexColor> onPick;

  @override
  Widget build(BuildContext context) {
    final ramp = tonalRamp(base);
    return Row(
      children: [
        for (final tone in ramp)
          Expanded(
            child: Tooltip(
              message: '${tone.step} · ${tone.color.value}',
              child: GestureDetector(
                onTap: () => onPick(tone.color),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: Motion.instant,
                    height: tone.isSource ? 40 : 32,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: toFlutter(tone.color),
                      borderRadius: BorderRadius.circular(3),
                      // الأصل أطول وله حدّ: يجب أن يرى المستخدم لونه هو
                      // داخل السلَّم، وإلّا بدا السلَّم غريبًا عنه.
                      border: tone.color.value == selected || tone.isSource
                          ? Border.all(color: Shade.mirror, width: 2)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
