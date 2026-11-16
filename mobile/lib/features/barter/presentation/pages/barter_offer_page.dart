import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../widgets/barter_widgets.dart';

/// Figma "20 · Detail tawaran barter".
class BarterOfferPage extends StatelessWidget {
  const BarterOfferPage({super.key});

  @override
  Widget build(BuildContext context) {
    const barter = DemoData.barter;
    const big = TextStyle(
      fontSize: 18,
      height: 25 / 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Detail Tawaran Barter'),
        const Text(
          '#BTR-2026-012',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        const InfoBox(
          tone: SakuTone.barter,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              BarterEyebrow('SALMA MENAWARKAN'),
              Text('Desain UI Web Portofolio', style: big),
              SwapGlyph(),
              BarterEyebrow('RIZKIA MENAWARKAN'),
              Text('Editing Video Teaser Reels 30 Detik', style: big),
            ],
          ),
        ),
        PersonRow(
          name: barter.partner,
          subtitle: 'Video Editor Cibiru · 4.8 ★',
          asset: barter.partnerAsset,
        ),
        const SakuTextField(
          label: 'Pesan Permintaan Barter',
          initialValue: 'Halo Rizkia, saya tertarik menukar jasa desain UI dengan '
              'editing video teaser untuk keperluan promosi portofolio saya.',
          minLines: 3,
          maxLines: 6,
        ),
        const SakuTextField(
          label: 'Usulan Tenggat Pengerjaan',
          initialValue: '4 Hari Bersama',
        ),
        SakuButton(
          key: const Key('barter-send-request'),
          label: 'Kirim Permintaan Barter ke Rizkia',
          variant: SakuButtonVariant.barter,
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pushReplacementNamed(AppRoutes.barterIncoming);
          },
        ),
      ],
    );
  }
}
