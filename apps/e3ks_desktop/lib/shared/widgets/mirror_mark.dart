/// الشعار: الاسم وانعكاسه.
///
/// الانعكاس ليس زينة — هو ما يفعله التطبيق. يتلاشى نزولًا لأن الانعكاس على
/// سطحٍ داكن يبهت، ولأن انعكاسًا كاملًا يقرأه البصر حرفًا ثانيًا لا ظلًّا.
///
/// مشترك بين شاشة الدخول ومكان الإسقاط — ولذلك يسكن في `shared/` (`01`).
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MirrorMark extends StatelessWidget {
  const MirrorMark({super.key, required this.name, this.size = 42});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: Type.display,
      color: Shade.text,
      letterSpacing: size * 0.19,
      height: 1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: style, textDirection: TextDirection.ltr),
        SizedBox(
          height: size * 0.57,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Shade.mirror, Shade.transparent],
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: Transform.flip(
              flipY: true,
              child: Text(name, style: style, textDirection: TextDirection.ltr),
            ),
          ),
        ),
      ],
    );
  }
}
