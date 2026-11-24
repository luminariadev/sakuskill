import 'package:flutter/material.dart';

import '../motion/saku_motion.dart';
import '../theme/app_colors.dart';
import '../widgets/saku_icon.dart';
import '../widgets/saku_surfaces.dart';
import 'app_router.dart';

/// Figma "7 · Menu aksi cepat" — bottom sheet "Buat Aktivitas Baru".
Future<void> showQuickActionSheet(BuildContext context) {
  final navigator = Navigator.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Handle digambar sendiri sesuai Figma (36×4 #CBD5E1).
    showDragHandle: false,
    backgroundColor: AppColors.cardSurface,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 280),
      reverseDuration: Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    ),
    builder: (sheet) {
      void go(String route) {
        Navigator.of(sheet).pop();
        navigator.pushNamed(route);
      }

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dashedBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Buat Aktivitas Baru',
                style: TextStyle(
                  fontSize: 18,
                  height: 25 / 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'Pilih jenis transaksi yang ingin Anda buat hari ini:',
                style: TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: AppColors.textSecondary,
                ),
              ),
              FadeSlideIn(
                index: 0,
                child: _ActionTile(
                  key: const Key('quick-offer'),
                  icon: SakuIcons.briefcase,
                  tone: SakuTone.success,
                  title: 'Tawarkan Jasa Baru',
                  subtitle: 'Publikasikan keahlian ke katalog dengan tarif manual.',
                  onTap: () => go(AppRoutes.myServices),
                ),
              ),
              FadeSlideIn(
                index: 1,
                child: _ActionTile(
                  key: const Key('quick-request'),
                  icon: SakuIcons.search,
                  tone: SakuTone.escrow,
                  title: 'Cari Jasa / Buat Permintaan',
                  subtitle:
                      'Posting kebutuhan proyek agar ditemukan talenta sekitar.',
                  onTap: () => go(AppRoutes.search),
                ),
              ),
              FadeSlideIn(
                index: 2,
                child: _ActionTile(
                  key: const Key('quick-barter'),
                  icon: SakuIcons.swap,
                  tone: SakuTone.barter,
                  title: 'Ajukan Tawaran Barter',
                  subtitle: 'Tukar keahlian simetris tanpa uang tunai.',
                  onTap: () => go(AppRoutes.proposeBarter),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(sheet).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final SakuIcons icon;
  final SakuTone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = switch (tone) {
      SakuTone.escrow => AppColors.escrowText,
      SakuTone.barter => AppColors.barter,
      _ => AppColors.primary,
    };
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: SakuCard(
        onTap: onTap,
        radius: 12,
        padding: const EdgeInsets.fromLTRB(11, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tone.surface, shape: BoxShape.circle),
              child: SakuIcon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 15 / 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SakuIcon(SakuIcons.chevron, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
