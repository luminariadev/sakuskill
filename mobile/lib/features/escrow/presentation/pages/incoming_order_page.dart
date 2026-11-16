import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "12 · Pesanan masuk" (sisi penyedia) + "12B · Tolak pesanan".
class IncomingOrderPage extends StatelessWidget {
  const IncomingOrderPage({super.key});

  Future<void> _reject(BuildContext context) async {
    final rejected = await showSakuSheet<bool>(
      context,
      builder: (_) => const _RejectSheet(),
    );
    if (rejected == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Pesanan ditolak. Dimas sudah diberi tahu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const order = DemoData.order;
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pesanan Baru Masuk'),
        Text(
          '#SK-2026-091',
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const InfoBox(
          text: 'PESANAN BARU · MENUNGGU RESPONS',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              PersonRow(
                name: 'Dimas (Katering Berkah Cibiru)',
                subtitle: 'Pelanggan · Cibiru, Bandung',
                asset: order.clientAsset,
              ),
              const Text(
                'Desain Spanduk Toko Ukuran 3×1 m',
                style: TextStyle(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatRupiah(order.amount),
                style: const TextStyle(
                  fontSize: 24,
                  height: 34 / 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Tenggat: ${order.deadlineDays} Hari',
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Text(
                'CATATAN BRIEF',
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Text(
                'Warna cerah, lampiran foto menu ayam bakar.',
                style: TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.textPrimary),
              ),
              const InfoBox(
                text: 'Lampiran · Foto_Ayam_Bakar.jpg',
                tone: SakuTone.neutral,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
        SakuButton(
          key: const Key('incoming-accept'),
          label: 'Terima & Masuk Diskusi Brief',
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pushReplacementNamed(AppRoutes.orderChat);
          },
        ),
        SakuButton(
          key: const Key('incoming-reject'),
          label: 'Tolak Pesanan',
          variant: SakuButtonVariant.destructive,
          onPressed: () => _reject(context),
        ),
        const InfoBox(
          text: 'Jika menolak, pilih alasan agar komunikasi dengan klien tetap profesional.',
          tone: SakuTone.neutral,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  int _reason = 0;

  @override
  Widget build(BuildContext context) {
    return SakuSheetContent(
      title: 'Tolak Pesanan Ini?',
      message: 'Beri tahu Dimas alasan Anda tidak dapat menerima pesanan ini '
          'agar komunikasi tetap profesional:',
      body: [
        RadioOptions(
          options: const [
            'Jadwal pengerjaan saya saat ini sedang penuh',
            'Spesifikasi brief di luar keahlian/lingkup saya',
            'Tenggat waktu yang diminta terlalu singkat',
            'Alasan lainnya...',
          ],
          selected: _reason,
          onChanged: (i) => setState(() => _reason = i),
        ),
        const SakuTextField(
          label: 'Catatan tambahan (opsional)',
          hint: 'Tuliskan pesan singkat untuk Pak Dimas...',
          minLines: 2,
          maxLines: 4,
        ),
      ],
      confirmLabel: 'Konfirmasi Tolak Pesanan',
      confirmVariant: SakuButtonVariant.destructive,
      cancelLabel: 'Kembali (Batal Menolak)',
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
