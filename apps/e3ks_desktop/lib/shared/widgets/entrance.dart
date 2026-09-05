/// دخول العناصر إلى المشهد: تلاشٍ وانزلاق قصير، مرّةً واحدة.
///
/// **الغرض شرحٌ لا استعراض.** الترتيب المتدرّج ([order]) يقول للعين من أين
/// تبدأ القراءة، فتستقرّ على الواجهة بدل أن تمسحها كلّها دفعةً واحدة.
///
/// و**مرّةً واحدة** شرط: هذه الودجة تُبنى داخل `ListenableBuilder` يُعاد
/// بناؤه مع كل تغيّر حالة. لو أعادت الحركة مع كل بناء لارتجّت الواجهة كلّما
/// بدّل المستخدم لونًا — وهذا أسوأ من غياب الحركة أصلًا.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.order = 0,
    this.enabled = true,
  });

  final Widget child;

  /// ترتيب العنصر في التتابع. التأخير = [order] × [Motion.stagger].
  final int order;

  /// إطفاؤها يُظهر الطفل فورًا بلا حركة — للاختبارات وللدخول الثاني.
  final bool enabled;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final Duration _delay = Motion.stagger * widget.order;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.entrance + _delay,
  );

  /// التأخير جزءٌ من المنحنى لا مؤقّتٌ منفصل.
  ///
  /// ‏`Future.delayed` كان يترك مؤقّتًا معلَّقًا يبقى بعد التخلّص من الودجة،
  /// ويُسقط كل اختبار لا ينتظر استقرار الحركة. و`Interval` يؤدّي المعنى نفسه
  /// داخل المتحكّم: لا مؤقّت، ولا تسريب، ولا شيء يُنظَّف يدويًّا.
  late final Animation<double> _eased = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _controller.duration!.inMicroseconds == 0
          ? 0
          : _delay.inMicroseconds / _controller.duration!.inMicroseconds,
      1,
      curve: Motion.enter,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return FadeTransition(
      opacity: _eased,
      child: AnimatedBuilder(
        animation: _eased,
        builder: (context, child) => Transform.translate(
          // ينزلق صاعدًا مسافةً قصيرة: تدلّ على الاتجاه ولا تُشاهَد.
          offset: Offset(0, Motion.slideIn * (1 - _eased.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
