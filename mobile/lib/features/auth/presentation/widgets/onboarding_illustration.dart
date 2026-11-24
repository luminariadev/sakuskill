import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

import '../../../../core/motion/saku_motion.dart';

/// Ilustrasi "Generated illustration" layar Awalan (353 × 218): dua
/// mahasiswa bertukar keahlian. Disusun dari bagian SVG Figma dengan inset
/// pecahan yang sama. Kartu pena & palet melayang pelan (±3 px, 3 detik)
/// sebagai micro-interaction; diam bila "kurangi animasi" aktif.
class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({super.key});

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SakuMotion.reduced(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  static Widget _svg(String name) => SvgPicture.asset(
        'assets/illustrations/$name.svg',
        fit: BoxFit.fill,
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ilustrasi dua mahasiswa bertukar keahlian',
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 353 / 218,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            // Inset Figma: top, right, bottom, left (pecahan ukuran frame).
            Widget at(double t, double r, double b, double l, Widget child) =>
                Positioned(
                  top: t * h,
                  right: r * w,
                  bottom: b * h,
                  left: l * w,
                  child: child,
                );

            return AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                final dy = math.sin(_float.value * 2 * math.pi) * 3;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    at(.1125, .1146, .1009, .0990, _svg('onboarding_background')),
                    at(.1697, .2153, .2798, .1643, _svg('onboarding_accents')),
                    at(.1686, .4299, .6915, .4328, _svg('onboarding_arrows')),
                    at(.2110, .4476, .1284, .2368, _svg('onboarding_woman')),
                    at(.2256, .2436, .1284, .4758, _svg('onboarding_man')),
                    at(
                      .2492, .7709, .5611, .1165,
                      Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.rotate(
                          angle: -10 * math.pi / 180,
                          child: Center(
                            child: SizedBox(
                              width: 35 / 353 * w,
                              height: 37 / 218 * h,
                              child: _svg('onboarding_pen_card'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    at(
                      .2820, .1340, .5389, .7600,
                      Transform.translate(
                        offset: Offset(0, -dy),
                        child: Transform.rotate(
                          angle: 10 * math.pi / 180,
                          child: Center(
                            child: SizedBox(
                              width: 33 / 353 * w,
                              height: 35 / 218 * h,
                              child: _svg('onboarding_palette_card'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
