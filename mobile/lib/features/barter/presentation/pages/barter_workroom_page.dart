import 'package:flutter/material.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';

/// Figma "23 · Ruang kerja barter" — progres kedua pihak.
class BarterWorkroomPage extends StatelessWidget {
  const BarterWorkroomPage({super.key});

  @override
  Widget build(BuildContext context) {
    const barter = DemoData.barter;
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Proyek Barter Berjalan'),
        const Text(
          '#BTR-2026-012',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        const InfoBox(
          text: 'BARTER AKTIF · PENGERJAAN BERSAMA',
          tone: SakuTone.barter,
          fontWeight: FontWeight.w500,
        ),
        _ProgressCard(
          name: DemoData.me,
          skill: 'Desain UI Web',
          asset: DemoAssets.salma,
          progress: barter.myProgress,
          stage: 'Draf Mockup Diunggah',
          link: 'https://figma.com/@salma/ui-landing.fig',
        ),
        _ProgressCard(
          name: barter.partner,
          skill: 'Video Reels',
          asset: barter.partnerAsset,
          progress: barter.partnerProgress,
          stage: 'Rough Cut Video',
          link: 'https://drive.google.com/rizkia/teaser-rough.mp4',
        ),
        const InfoBox(
          text: 'Kedua pihak harus mengajukan penyelesaian dan saling mengonfirmasi '
              'selesai agar kontrak barter tuntas.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        SakuButton(
          key: const Key('barter-submit'),
          label: 'Ajukan Penyelesaian Karya Saya',
          variant: SakuButtonVariant.barter,
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pushReplacementNamed(AppRoutes.barterDone);
          },
        ),
        SakuButton(
          label: 'Buka Chat Diskusi Barter',
          variant: SakuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.barterChat),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.name,
    required this.skill,
    required this.asset,
    required this.progress,
    required this.stage,
    required this.link,
  });

  final String name;
  final String skill;
  final String asset;
  final double progress;
  final String stage;
  final String link;

  @override
  Widget build(BuildContext context) {
    return SakuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          PersonRow(name: name, subtitle: skill, asset: asset),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: SakuMotion.curve,
            builder: (_, v, __) => Text(
              '${(v * 100).round()}% Selesai',
              style: const TextStyle(
                fontSize: 22,
                height: 31 / 22,
                fontWeight: FontWeight.w700,
                color: AppColors.barter,
              ),
            ),
          ),
          SakuProgressBar(value: progress, color: AppColors.barter),
          Text(
            stage,
            style: const TextStyle(
              fontSize: 12,
              height: 17 / 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            link,
            style: const TextStyle(fontSize: 11, height: 15 / 11, color: AppColors.barterText),
          ),
        ],
      ),
    );
  }
}
