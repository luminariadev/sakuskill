import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';

/// Glyph pertukaran ⇄ ungu. Saat pertama tampil berputar setengah putaran
/// (600 ms) — penanda visual "saling tukar" yang tenang.
class SwapGlyph extends StatelessWidget {
  const SwapGlyph({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final glyph = Text(
      '⇄',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        height: 45 / 32,
        fontWeight: FontWeight.w700,
        color: AppColors.barter,
      ),
    );
    return Semantics(
      label: 'ditukar dengan',
      excludeSemantics: true,
      child: Center(
        child: SakuMotion.reduced(context)
            ? glyph
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: SakuMotion.curve,
                builder: (_, t, child) =>
                    Transform.rotate(angle: (1 - t) * math.pi, child: child),
                child: glyph,
              ),
      ),
    );
  }
}

/// Teks label 10/700 ungu ("SALMA MENAWARKAN").
class BarterEyebrow extends StatelessWidget {
  const BarterEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        height: 14 / 10,
        fontWeight: FontWeight.w700,
        color: AppColors.barterText,
      ),
    );
  }
}
