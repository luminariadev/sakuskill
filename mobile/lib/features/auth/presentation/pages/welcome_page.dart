import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../widgets/onboarding_illustration.dart';

/// Figma "1 · Awalan SakuSkill".
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SakuScreen(
      background: AppColors.canvasLight,
      children: [
        const SakuEmblem(size: 64),
        const Text(
          'sakuskill.',
          style: TextStyle(
            fontSize: 32,
            height: 45 / 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          'Marketplace Keahlian Mikro & Tukar Jasa Terpercaya',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const OnboardingIllustration(),
        const InfoBox(
          text: 'Dana Aman Rekening Bersama Escrow',
          tone: SakuTone.success,
        ),
        const InfoBox(
          text: 'Tukar Keahlian Tanpa Uang Tunai',
          tone: SakuTone.barter,
        ),
        const InfoBox(
          text: 'Talenta Terdekat Sekitar Kampus Cibiru',
          tone: SakuTone.escrow,
        ),
        SakuButton(
          key: const Key('welcome-login'),
          label: 'Masuk ke Akun Anda',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
        ),
        SakuButton(
          key: const Key('welcome-register'),
          label: 'Daftar Akun Baru',
          variant: SakuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
        ),
        const Text(
          'Dengan masuk atau mendaftar, Anda menyetujui Ketentuan Layanan SakuSkill.',
          style: TextStyle(
            fontSize: 11,
            height: 15 / 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
