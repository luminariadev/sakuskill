import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../widgets/onboarding_illustration.dart';

/// Warna latar belakang yang disampling persis dari tepi aset `welcome_clay_hero.png`
/// agar ilustrasi 3D clay menyatu tanpa garis batas kotak.
const Color _kWelcomeCanvas = Color(0xFFDFEEEB);

/// Figma "1 · Awalan SakuSkill" — header gelombang mint/emerald berlapis ala
/// tema claymorphism & glassmorphism, ikon terpusat di atas, ilustrasi clay
/// menyatu dengan background tanpa animasi mengambang, dan dock tombol Masuk/Daftar.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _kWelcomeCanvas,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: topInset + 188,
              width: double.infinity,
              child: const CustomPaint(
                painter: _WelcomeWavePainter(),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xF5FFFFFF),
                                        Color(0xE8EAF7F2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      width: 1.6,
                                    ),
                                    boxShadow: AppShadows.clayElevated,
                                  ),
                                  child: const SakuEmblem(size: 62),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          child: OnboardingIllustration(
                            backgroundColor: _kWelcomeCanvas,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xE6FFFFFF),
                                      Color(0xCCF3FBF8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    width: 1.5,
                                  ),
                                  boxShadow: AppShadows.floatingDock,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 12,
                                  children: [
                                    SakuButton(
                                      key: const Key('welcome-login'),
                                      label: 'Masuk ke Akun Anda',
                                      onPressed: () => Navigator.of(context)
                                          .pushNamed(AppRoutes.login),
                                    ),
                                    SakuButton(
                                      key: const Key('welcome-register'),
                                      label: 'Daftar Akun Baru',
                                      variant: SakuButtonVariant.outline,
                                      onPressed: () => Navigator.of(context)
                                          .pushNamed(AppRoutes.register),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _WelcomeWavePainter extends CustomPainter {
  const _WelcomeWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gelombang belakang lembut (efek kedalaman glassmorphic)
    final backPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.78)
      ..cubicTo(
        w * 0.72,
        h * 0.56,
        w * 0.34,
        h * 1.04,
        0,
        h * 0.80,
      )
      ..close();

    final backPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x4500A870),
          Color(0x3852D6AC),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(backPath, backPaint);

    // Gelombang utama emerald -> mint menyambung halus ke kanvas bawah
    final frontPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.62)
      ..cubicTo(
        w * 0.72,
        h * 0.96,
        w * 0.30,
        h * 0.54,
        0,
        h * 0.74,
      )
      ..close();

    final frontPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryPressed,
          AppColors.primary,
          Color(0xFF5AD8AF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
