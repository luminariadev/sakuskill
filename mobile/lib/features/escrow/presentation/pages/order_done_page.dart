import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';

/// Figma "18 · Pesanan selesai" — dana dilepas + ulasan.
class OrderDonePage extends StatefulWidget {
  const OrderDonePage({super.key});

  @override
  State<OrderDonePage> createState() => _OrderDonePageState();
}

class _OrderDonePageState extends State<OrderDonePage> {
  int _stars = 5;

  @override
  Widget build(BuildContext context) {
    const order = DemoData.order;
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pesanan Selesai'),
        Text('#SK-2026-091',
            style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        SakuCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            spacing: 14,
            children: [
              const Align(alignment: Alignment.centerLeft, child: SuccessBadge()),
              const Text(
                'Pesanan Telah Selesai!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  height: 31 / 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              InfoBox(
                text: 'STATUS DANA: DILEPAS SIMULASI\n'
                    '${formatRupiah(order.amount).toUpperCase()}',
                tone: SakuTone.success,
                fontWeight: FontWeight.w500,
              ),
              Text(
                'Dana telah diteruskan ke Saldo Dompet ${order.provider}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Berikan Penilaian untuk\n${order.provider}',
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
          initialValue: 'Hasil desain spanduk sangat memuaskan, resolusi cetak tajam '
              'dan pengerjaan cepat. Recommended untuk promosi UMKM!',
          minLines: 4,
          maxLines: 6,
        ),
        SakuButton(
          key: const Key('done-submit'),
          label: 'Kirim Ulasan & Kembali ke Beranda',
          onPressed: () {
            SakuMotion.tick();
            final messenger = ScaffoldMessenger.of(context);
            Navigator.of(context).popUntil((r) => r.isFirst);
            messenger.showSnackBar(
              SnackBar(content: Text('Terima kasih! Ulasan $_stars★ terkirim.')),
            );
          },
        ),
      ],
    );
  }
}
