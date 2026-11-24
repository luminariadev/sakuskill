import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "18 · Pesanan selesai" — dana dilepas + ulasan.
class OrderDonePage extends StatefulWidget {
  const OrderDonePage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<OrderDonePage> createState() => _OrderDonePageState();
}

class _OrderDonePageState extends State<OrderDonePage> {
  int _stars = 5;
  bool _submitting = false;
  final _reviewCtrl = TextEditingController(
    text: 'Hasil desain spanduk sangat memuaskan, resolusi cetak tajam '
        'dan pengerjaan cepat. Recommended untuk promosi UMKM!',
  );

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (widget.order != null) return widget.order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  /// POST /api/v1/orders/:id/reviews (hanya pelanggan setelah status completed)
  Future<void> _submitReview(EscrowOrderModel? currentOrder) async {
    if (_submitting) return;
    SakuMotion.tick();

    if (currentOrder == null || currentOrder.orderId.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        SnackBar(content: Text('Terima kasih! Ulasan $_stars★ terkirim.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final repo = AppScope.of(context).escrowRepository;

    try {
      await repo.submitReview(
        orderId: currentOrder.orderId,
        rating: _stars,
        komentar: _reviewCtrl.text.trim(),
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Terima kasih! Ulasan $_stars★ berhasil disimpan.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      String msg = e.message;
      if (e.code == 'REVIEW_ALREADY_EXISTS') {
        msg = 'Anda sudah pernah memberikan ulasan untuk pesanan ini.';
      } else if (e.code == 'ORDER_NOT_COMPLETED') {
        msg = 'Pesanan harus berstatus Selesai sebelum mengirim ulasan.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim ulasan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const demo = DemoData.order;
    final currentOrder = _resolveOrder(context);

    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final statusEscrow =
        (currentOrder?.statusEscrow ?? 'Dana Dilepas ke Penyedia (Simulasi)')
            .toUpperCase();
    final amount = currentOrder?.harga ?? demo.amount;
    final providerName = currentOrder?.namaLawanTransaksi ?? demo.provider;
    final alreadyReviewed = currentOrder?.sudahDiulas ?? false;

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pesanan Selesai'),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
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
                text: 'STATUS DANA: $statusEscrow\n'
                    '${formatRupiah(amount).toUpperCase()}',
                tone: SakuTone.success,
                fontWeight: FontWeight.w500,
              ),
              Text(
                'Dana simulasi telah diteruskan ke Saldo Dompet $providerName.',
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
        if (!alreadyReviewed) ...[
          Text(
            'Berikan Penilaian untuk\n$providerName',
            style: const TextStyle(
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          StarRating(value: _stars, onChanged: (v) => setState(() => _stars = v)),
          SakuTextField(
            controller: _reviewCtrl,
            label: 'Ulasan Anda',
            minLines: 4,
            maxLines: 6,
          ),
          SakuButton(
            key: const Key('done-submit'),
            label: _submitting
                ? 'Mengirim Ulasan...'
                : 'Kirim Ulasan & Kembali ke Beranda',
            onPressed: _submitting ? null : () => _submitReview(currentOrder),
          ),
        ] else ...[
          const InfoBox(
            text: 'Anda sudah mengirimkan ulasan untuk transaksi ini.',
            tone: SakuTone.neutral,
          ),
          SakuButton(
            label: 'Kembali ke Beranda',
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
        if (currentOrder != null && currentOrder.orderId.isNotEmpty)
          SakuButton(
            label: 'Ajukan Komplain Transaksi',
            variant: SakuButtonVariant.outline,
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.complaint,
              arguments: currentOrder,
            ),
          ),
      ],
    );
  }
}