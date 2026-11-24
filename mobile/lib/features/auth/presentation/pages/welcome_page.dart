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
            height: 40 / 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
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
        const SakuCard(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              _ValuePropRow(
                icon: SakuIcons.shield,
                bg: AppColors.primarySurface,
                fg: AppColors.primaryPressed,
                text: 'Dana Aman Rekening Bersama Escrow',
              ),
              Divider(height: 18),
              _ValuePropRow(
                icon: SakuIcons.swap,
                bg: AppColors.barterSurface,
                fg: AppColors.barterText,
                text: 'Tukar Keahlian Tanpa Uang Tunai',
              ),
              Divider(height: 18),
              _ValuePropRow(
                icon: SakuIcons.pin,
                bg: AppColors.escrowSurface,
                fg: AppColors.escrowText,
                text: 'Talenta Terdekat Sekitar Kampus Cibiru',
              ),
            ],
          ),
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

class _ValuePropRow extends StatelessWidget {
  const _ValuePropRow({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.text,
  });

  final SakuIcons icon;
  final Color bg;
  final Color fg;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: SakuIcon(icon, size: 17, color: fg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 17 / 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
