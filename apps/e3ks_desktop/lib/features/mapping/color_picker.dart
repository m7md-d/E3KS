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
import '../../app/theme.dart';
import '../../shared/widgets/swatch.dart';

/// يفتح المنتقي ويُرجع اللون المختار، أو `null` عند الإلغاء،
/// أو [HexColor] الأصلي عند طلب إزالة التبديل.
Future<HexColor?> pickColor(
  BuildContext context, {
  required HexColor original,
  HexColor? current,
  List<HexColor> suggestions = const [],
  List<ColorUsage> reference = const [],
}) => showAppDialog<HexColor?>(
  context,
  (_) => _ColorDialog(
    original: original,
    current: current,
    suggestions: suggestions,
    reference: reference,
  ),
);

class _ColorDialog extends StatefulWidget {
  const _ColorDialog({
    required this.original,
    this.current,
    this.suggestions = const [],
    this.reference = const [],
  });

  final HexColor original;
  final HexColor? current;
  final List<HexColor> suggestions;

  /// ألوان مستند آخر مفتوح، مرتّبة بكثرة الاستعمال — أسرع طريق لأخذ هوية
  /// جاهزة من ملف بدل كتابة أرقام سداسية.
  final List<ColorUsage> reference;

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
              if (widget.reference.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(t.fromOtherDocument, style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final usage in widget.reference.take(18))
                      Tooltip(
                        message:
                            '${usage.color.value} · '
                            '${t.occurrences(usage.count)}',
                        child: Swatch(
                          color: usage.color,
                          size: 26,
                          selected: usage.color.value == _hex,
                          onTap: () => _setHsv(
                            HSVColor.fromColor(toFlutter(usage.color)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (widget.suggestions.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(t.fromSavedIdentities, style: theme.textTheme.labelSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final color in widget.suggestions)
                      Swatch(
                        color: color,
                        size: 26,
                        selected: color.value == _hex,
                        onTap: () =>
                            _setHsv(HSVColor.fromColor(toFlutter(color))),
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
