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
import '../../data/models/escrow_order_model.dart';

/// Figma "12 · Pesanan masuk" (sisi penyedia) + "12B · Tolak pesanan".
class IncomingOrderPage extends StatelessWidget {
  const IncomingOrderPage({super.key, this.order});

  final EscrowOrderModel? order;

  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (order != null) return order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  Future<void> _reject(BuildContext context, String clientName) async {
    final rejected = await showSakuSheet<bool>(
      context,
      builder: (_) => _RejectSheet(clientName: clientName),
    );
    if (rejected == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Pesanan ditolak. $clientName sudah diberi tahu.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const demo = DemoData.order;
    final currentOrder = _resolveOrder(context);

    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final serviceTitle =
        currentOrder?.judulLayanan ?? 'Desain Spanduk Toko Ukuran 3×1 m';
    final amount = currentOrder?.harga ?? demo.amount;
    final deadlineDays = currentOrder?.detikTersisa != null
        ? (currentOrder!.detikTersisa! / 86400).ceil().clamp(1, 365)
        : demo.deadlineDays;
    final briefNote =
        currentOrder?.catatanBrief ?? 'Warna cerah, lampiran foto menu ayam bakar.';
    final attachment = currentOrder?.lampiranKlien ?? 'Foto_Ayam_Bakar.jpg';
    final clientShortName = demo.client.split(' ').first;

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pesanan Baru Masuk'),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        InfoBox(
          text:
              '${(currentOrder?.statusPesanan ?? 'PESANAN BARU').toUpperCase()} · MENUNGGU RESPONS',
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
                asset: demo.clientAsset,
              ),
              Text(
                serviceTitle,
                style: const TextStyle(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatRupiah(amount),
                style: const TextStyle(
                  fontSize: 24,
                  height: 34 / 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Tenggat: $deadlineDays Hari',
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
              Text(
                briefNote,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textPrimary,
                ),
              ),
              InfoBox(
                text: 'Lampiran · $attachment',
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
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.orderChat,
              arguments: currentOrder,
            );
          },
        ),
        SakuButton(
          key: const Key('incoming-reject'),
          label: 'Tolak Pesanan',
          variant: SakuButtonVariant.destructive,
          onPressed: () => _reject(context, clientShortName),
        ),
        const InfoBox(
          text:
              'Jika menolak, pilih alasan agar komunikasi dengan klien tetap profesional.',
          tone: SakuTone.neutral,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.clientName});

  final String clientName;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  int _reason = 0;

  @override
  Widget build(BuildContext context) {
    return SakuSheetContent(
      title: 'Tolak Pesanan Ini?',
      message:
          'Beri tahu ${widget.clientName} alasan Anda tidak dapat menerima pesanan ini '
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
        SakuTextField(
          label: 'Catatan tambahan (opsional)',
          hint: 'Tuliskan pesan singkat untuk Pak ${widget.clientName}...',
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