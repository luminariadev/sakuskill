import 'package:flutter/material.dart';

/// Ilustrasi 3D claymorphism layar Awalan: statis dan tepinya membaur halus
/// ke warna latar belakang tanpa bingkai kartu atau animasi naik-turun.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    this.backgroundColor = const Color(0xFFDFEEEB),
  });

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final transparentBg = backgroundColor.withValues(alpha: 0);

    return Semantics(
      label: 'Ilustrasi dua mahasiswa bertukar keahlian',
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1200 / 896,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/welcome_clay_hero.png',
              fit: BoxFit.contain,
              width: double.infinity,
            ),
            // Feather tepi atas, bawah, kiri, kanan agar menyatu mulus dengan kanvas
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 26,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [backgroundColor, transparentBg],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 28,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [backgroundColor, transparentBg],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 18,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [backgroundColor, transparentBg],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 18,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [backgroundColor, transparentBg],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
