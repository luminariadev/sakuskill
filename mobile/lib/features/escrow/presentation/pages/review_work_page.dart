import 'package:flutter/material.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "17 · Pemeriksaan hasil" (sisi klien).
class ReviewWorkPage extends StatefulWidget {
  const ReviewWorkPage({super.key});

  @override
  State<ReviewWorkPage> createState() => _ReviewWorkPageState();
}

class _ReviewWorkPageState extends State<ReviewWorkPage> {
  int _revisionsLeft = 1;

  @override
  Widget build(BuildContext context) {
    final amount = formatRupiah(DemoData.order.amount);
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pemeriksaan Hasil Kerja'),
        Text('#SK-2026-091',
            style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.canvasLight,
            borderRadius: AppRadius.cardBr,
            border: Border.all(color: AppColors.accent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const Text(
                'Spanduk_Katering_Berkah_Final.pdf',
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                '34 MB · PDF siap cetak',
                style: TextStyle(fontSize: 11, height: 15 / 11, color: AppColors.textSecondary),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 112,
                  width: double.infinity,
                  child: Image.asset(DemoAssets.spandukBerkah, fit: BoxFit.cover),
                ),
              ),
              SakuButton(
                label: 'Buka Tautan Google Drive',
                variant: SakuButtonVariant.outline,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka tautan Google Drive...')),
                ),
              ),
              const Text(
                'Catatan Salma',
                style: TextStyle(
                  fontSize: 11,
                  height: 15 / 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Text(
                'File sudah siap cetak format CMYK 300 DPI Pak Dimas.',
                style: TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        SakuButton(
          key: const Key('review-approve'),
          label: 'Konfirmasi Selesai & Lepas Dana Simulasi ($amount)',
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pushReplacementNamed(AppRoutes.orderDone);
          },
        ),
        SakuButton(
          label: 'Ajukan Komplain (Masuk Status Sengketa)',
          variant: SakuButtonVariant.destructive,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.complaint),
        ),
        Center(
          child: SakuTextLink(
            _revisionsLeft > 0
                ? 'Minta Revisi Ringan (Sisa ${_revisionsLeft}x)'
                : 'Kuota revisi ringan sudah habis',
            fontSize: 13,
            color: _revisionsLeft > 0 ? AppColors.primary : AppColors.textSecondary,
            onTap: () {
              if (_revisionsLeft == 0) return;
              setState(() => _revisionsLeft--);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permintaan revisi ringan dikirim ke Salma.')),
              );
            },
          ),
        ),
        const InfoBox(
          text: 'Periksa seluruh berkas sebelum menyetujui. Dana baru dilepas setelah '
              'Anda konfirmasi.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}
