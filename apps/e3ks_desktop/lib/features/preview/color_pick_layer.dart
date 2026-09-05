/// طبقة التقاط اللون فوق المعاينة.
///
/// **منتقٍ حقيقي لا قائمة اختيار.** المستخدم يرى اللون في صفحته، فالطريق
/// إليه أن يشير إليه — لا أن يبحث عن رقمه السداسي في قائمة من ثلاثين.
///
/// تقرأ الطبقة بكسلات ما رُسم فعلًا (`RepaintBoundary`)، وتردّ النقطة إلى
/// لونٍ يعلنه المستند عبر `color_sampler.dart`. والعدسة تُظهر ما سيُلتقَط
/// **قبل** الضغط: التقاطٌ لا يرى المستخدمُ نتيجته قبل حدوثها تخمينٌ منه.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:e3ks_engine/e3ks_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../app/l10n_extensions.dart';
import '../../app/theme.dart';
import '../../shared/widgets/swatch.dart';
import 'color_sampler.dart';

/// أقصى دقّة نلتقط بها. شاشة Retina على نافذة واسعة تعني عشرين ميغابايت
/// من البكسلات؛ الحدّ يكفي لتمييز ساق الحرف ولا يثقل الذاكرة.
const double _maxCaptureRatio = 2;

/// كم إطارًا ننتظر حدًّا يتّسخ قبل أن نتركه.
const int _maxAttempts = 3;

class ColorPickLayer extends StatefulWidget {
  const ColorPickLayer({
    super.key,
    required this.boundary,
    required this.candidates,
    required this.onPicked,
    required this.onCancel,
  });

  /// مفتاح `RepaintBoundary` الذي يغلّف الورق — منه تُلتقط البكسلات.
  final GlobalKey boundary;

  /// ألوان المستند **كما تُرسم الآن**: في عرض «بعد» هي ألوان البدائل.
  final List<HexColor> candidates;

  final void Function(HexColor color) onPicked;
  final VoidCallback onCancel;

  @override
  State<ColorPickLayer> createState() => _ColorPickLayerState();
}

class _ColorPickLayerState extends State<ColorPickLayer> {
  PixelGrid? _grid;
  double _ratio = 1;

  /// الالتقاط الجاري. مشترك بين التمرير والضغط، فلا يلتقط اثنان معًا.
  Future<void>? _running;

  HexColor? _hover;
  Offset? _at;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() =>
      _running ??= _grab(0).whenComplete(() => _running = null);

  /// يلتقط **داخل نداء ما بعد الإطار**، لا بعد انتظار غير مضمون.
  ///
  /// `toImage` تشترط أن يكون الحدّ مرسومًا؛ انتظار «نهاية الإطار» ثم
  /// الالتقاط في مهمّة صغرى لاحقة يترك فجوةً قد يتّسخ فيها الحدّ فتسقط
  /// الشرط. النداء بعد الإطار مباشرةً يلتقط ما رُسم للتوّ بلا فجوة.
  Future<void> _grab(int attempt) {
    final done = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _capture(attempt).whenComplete(done.complete),
    );
    WidgetsBinding.instance.scheduleFrame();
    return done.future;
  }

  Future<void> _capture(int attempt) async {
    final object = widget.boundary.currentContext?.findRenderObject();
    if (!mounted || object is! RenderRepaintBoundary) return;

    // حدٌّ ينتظر رسمًا لا يُلتقَط: صورته إمّا ساقطةٌ بشرط أو قديمة. نعيد
    // المحاولة في الإطار التالي بدل أن نلتقط ما لا يراه المستخدم.
    var painted = true;
    assert(() {
      painted = !object.debugNeedsPaint;
      return true;
    }());
    if (!painted) {
      return attempt < _maxAttempts ? _grab(attempt + 1) : null;
    }

    final ratio = math.min(
      MediaQuery.devicePixelRatioOf(context),
      _maxCaptureRatio,
    );
    final image = object.toImageSync(pixelRatio: ratio);
    final width = image.width;
    final height = image.height;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (!mounted || data == null) return;

    setState(() {
      _grid = PixelGrid(bytes: data, width: width, height: height);
      _ratio = ratio;
    });
  }

  HexColor? _resolve(Offset global) {
    final grid = _grid;
    final object = widget.boundary.currentContext?.findRenderObject();
    if (grid == null || object is! RenderRepaintBoundary) return null;

    final local = object.globalToLocal(global);
    return resolveColorAt(
      grid,
      (local.dx * _ratio).round(),
      (local.dy * _ratio).round(),
      candidates: widget.candidates,
      background: fromFlutter(Paper.sheet),
    );
  }

  Future<void> _commit(Offset global) async {
    // نلتقط عند الضغط لا قبله: ما رُسم في هذه اللحظة هو ما قصده المستخدم،
    // ولو كان المخزون قديمًا بعد تمرير.
    await _refresh();
    if (!mounted) return;

    final match = _resolve(global);
    // لا مطابقة ⇒ يبقى الالتقاط ليعيد المحاولة. إغلاقه عقوبةٌ على تصويب
    // فاتَ بالبكسل.
    if (match == null) return;

    widget.onPicked(match);
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        // التمرير لا يمرّ عبرنا فحسب — يغيّر ما تحت المؤشّر، فنلتقط ثانيةً.
        onPointerSignal: (_) => unawaited(_refresh()),
        child: MouseRegion(
          cursor: SystemMouseCursors.precise,
          onHover: (event) => setState(() {
            _at = event.localPosition;
            _hover = _resolve(event.position);
          }),
          onExit: (_) => setState(() => _at = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => unawaited(_commit(details.globalPosition)),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _Chip(child: Text(t.pickingHint)),
                    ),
                  ),
                  if (_at case final at?)
                    Positioned(
                      left: math.min(at.dx + 18, constraints.maxWidth - 150),
                      top: math.min(at.dy + 18, constraints.maxHeight - 44),
                      child: _Loupe(color: _hover),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ما تحت المؤشّر الآن — يرى المستخدم نتيجة الضغط قبل أن يضغط.
class _Loupe extends StatelessWidget {
  const _Loupe({required this.color});

  final HexColor? color;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return _Chip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color case final found?) ...[
            Swatch(color: found, size: 18),
            const SizedBox(width: 8),
            Text(found.value, textDirection: TextDirection.ltr),
          ] else
            Text(t.noColorMatch),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Shade.surfaceHigh,
      borderRadius: BorderRadius.circular(Metrics.radiusSmall),
      border: Border.all(color: Shade.borderStrong),
    ),
    child: DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.labelSmall,
      child: child,
    ),
  );
}
