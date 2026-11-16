import 'package:flutter/material.dart';

import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "15E · Banding kompensasi" (sisi penyedia setelah dibatalkan).
class AppealPage extends StatelessWidget {
  const AppealPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Banding Pembatalan\nPesanan'),
        const Text(
          '#SK-2026-091',
          style: TextStyle(
            fontSize: 11,
            height: 15 / 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const InfoBox(
          text: 'Pesanan #SK-091 dibatalkan klien karena keterlambatan. Jika Anda '
              'telah mengerjakan > 70% pekerjaan, Anda berhak mengajukan banding ke '
              'Admin untuk kompensasi damai 50:50.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        const SakuTextField(
          label: 'Estimasi Progres Kerja',
          initialValue: '80% Selesai (Draf Utama Siap Pakai)',
        ),
        const SakuTextField(
          label: 'Tautan Berkas Kerja',
          initialValue: 'https://drive.google.com/salma/draf-spanduk-80percent.pdf',
          keyboardType: TextInputType.url,
          maxLines: 3,
        ),
        const Text(
          'Unggah Screenshot Layer Kerja',
          style: TextStyle(
            fontSize: 12,
            height: 17 / 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Row(
          spacing: 9,
          children: [
            Expanded(child: _LayerScreenshot()),
            Expanded(child: _LayerScreenshot()),
          ],
        ),
        const SakuTextField(
          label: 'Kronologi',
          initialValue: 'Saya sudah menyelesaikan 80% desain sebelum pembatalan '
              'terjadi. File sudah dapat digunakan klien. Mohon pembagian '
              'kompensasi 50:50.',
          minLines: 3,
          maxLines: 6,
        ),
        SakuButton(
          key: const Key('appeal-submit'),
          label: 'Kirim Permohonan Banding 50:50 ke Admin',
          onPressed: () {
            SakuMotion.tick();
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(context).popUntil((r) => r.isFirst);
            messenger.showSnackBar(
              const SnackBar(content: Text('Banding terkirim. Admin Mediasi akan meninjau.')),
            );
          },
        ),
      ],
    );
  }
}

/// Pratinjau screenshot layer kerja (Figma "Screenshot layer"): toolbar,
/// daftar layer, dan kanvas desain mini.
class _LayerScreenshot extends StatelessWidget {
  const _LayerScreenshot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Screenshot layer kerja spanduk Katering Berkah',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 112,
          color: AppColors.cardSlate,
          child: Column(
            children: [
              Container(height: 14, color: AppColors.borderSlate),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 9, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        spacing: 8,
                        children: [
                          for (var i = 0; i < 4; i++)
                            Container(
                              width: 42,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.fromLTRB(8, 12, 4, 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'KATERING\nBERKAH',
                            style: TextStyle(
                              fontSize: 11,
                              height: 15 / 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
