import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../widgets/barter_widgets.dart';

/// Figma "24 · Barter selesai" — verifikasi bilateral + ulasan mitra.
class BarterDonePage extends StatefulWidget {
  const BarterDonePage({super.key});

  @override
  State<BarterDonePage> createState() => _BarterDonePageState();
}

class _BarterDonePageState extends State<BarterDonePage> {
  int _stars = 5;

  @override
  Widget build(BuildContext context) {
    const barter = DemoData.barter;
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Barter Selesai'),
        const Text(
          '#BTR-2026-012',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        const SakuCard(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              SwapGlyph(size: 56),
              InfoBox(
                text: 'STATUS: BARTER SELESAI & TUNTAS',
                fontWeight: FontWeight.w500,
              ),
              Center(
                child: Text(
                  'Kedua Belah Pihak Telah Mengonfirmasi Selesai!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    height: 31 / 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '✓ Salma menyetujui video dari Rizkia\n'
                '✓ Rizkia menyetujui desain dari Salma',
                style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          'Berikan Ulasan untuk Mitra Barter\n${barter.partner}',
          style: const TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        StarRating(value: _stars, onChanged: (v) => setState(() => _stars = v)),
        const SakuTextField(
          label: 'Ulasan Anda',
          initialValue: 'Hasil editing videonya sangat estetik dan tepat waktu. '
              'Kolaborasi barter yang luar biasa!',
          minLines: 3,
          maxLines: 6,
        ),
        SakuButton(
          key: const Key('barter-done-submit'),
          label: 'Kirim Ulasan & Selesaikan Barter',
          variant: SakuButtonVariant.barter,
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pushReplacementNamed(AppRoutes.barterHistory);
          },
        ),
      ],
    );
  }
}
