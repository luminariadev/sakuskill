import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "15D · Status terlambat" (sisi klien) + "15D-2 · Konfirmasi pembatalan".
class LateStatusPage extends StatelessWidget {
  const LateStatusPage({super.key, this.order});

  final EscrowOrderModel? order;

  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (order != null) return order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  Future<void> _cancel(
    BuildContext context,
    EscrowOrderModel? currentOrder,
    int lateHours,
  ) async {
    final rawAmount = currentOrder?.harga ?? DemoData.order.amount;
    final amount = formatRupiah(rawAmount);

    final confirmed = await showSakuSheet<bool>(
      context,
      builder: (ctx) => SakuSheetContent(
        title: 'Batalkan Pesanan & Tarik Dana 100%?',
        message:
            'Karena penyedia telah melewati tenggat ($lateHours jam berjalan), Anda berhak '
            'membatalkan pesanan ini.',
        body: [
          InfoBox(
            tone: SakuTone.neutral,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 34 / 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  '100% Penuh Tanpa Potongan',
                  style: TextStyle(
                    fontSize: 12,
                    height: 17 / 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'Saldo Dompet SakuSkill Anda\nDapat ditarik ke bank kapan saja\n\n'
                  'Pesanan akan langsung ditutup dan penyedia akan menerima '
                  'notifikasi pembatalan.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 17 / 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
        confirmLabel: 'Ya, Batalkan Pesanan & Tarik $amount',
        confirmVariant: SakuButtonVariant.destructive,
        cancelLabel: 'Kembali / Beri Waktu Tambahan',
        onConfirm: () {
          SakuMotion.tick();
          Navigator.of(ctx).pop(true);
        },
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final repo = AppScope.of(context).escrowRepository;
    final orderId = currentOrder?.orderId;

    if (orderId == null || orderId.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Simulasi: Pesanan dibatalkan. $amount kembali ke Dompet SakuSkill.',
          ),
        ),
      );
      return;
    }

    try {
      await repo.cancelOverdueOrder(orderId);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Pesanan dibatalkan. $amount kembali ke Dompet SakuSkill.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on EscrowException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const late = TextStyle(color: AppColors.danger);
    final currentOrder = _resolveOrder(context);

    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final providerFirstName =
        currentOrder?.namaLawanTransaksi?.split(' ').first ?? 'Penyedia';

    final actualLateSeconds = currentOrder?.terlambatDetik ?? 0;
    final lateHours =
        actualLateSeconds > 0 ? (actualLateSeconds / 3600).ceil() : 14;
    final graceRemaining = (24 - lateHours).clamp(0, 24);

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        PageHeader('Pesanan $orderCode'),
        Text(
          orderCode,
          style: const TextStyle(
            fontSize: 11,
            height: 15 / 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const InfoBox(
          text: 'STATUS: TERLAMBAT',
          tone: SakuTone.danger,
          fontWeight: FontWeight.w500,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.disputeSurface,
            borderRadius: AppRadius.cardBr,
            border: Border.all(color: AppColors.dispute),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Text(
                '!  PESANAN MELEWATI TENGGAT',
                style: late.copyWith(
                  fontSize: 17,
                  height: 24 / 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Masa Tenggang Keterlambatan',
                style: late.copyWith(
                  fontSize: 12,
                  height: 17 / 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$lateHours Jam Berjalan',
                style: late.copyWith(
                  fontSize: 26,
                  height: 36 / 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                graceRemaining > 0
                    ? 'Sisa $graceRemaining Jam dari masa tenggang 24 jam'
                    : 'Masa tenggang 24 jam telah habis',
                style: late.copyWith(fontSize: 13, height: 18 / 13),
              ),
            ],
          ),
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const Text(
                'Hak Pembatalan Klien',
                style: TextStyle(
                  fontSize: 17,
                  height: 24 / 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Keterlambatan telah berjalan $lateHours jam dari tenggat kesepakatan. Anda berhak '
                'membatalkan pesanan dan menarik seluruh dana simulasi Anda 100%.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SakuButton(
          key: const Key('late-cancel'),
          label: 'Batalkan Pesanan & Tarik Dana 100%',
          variant: SakuButtonVariant.destructive,
          onPressed: () => _cancel(context, currentOrder, lateHours),
        ),
        SakuButton(
          label: 'Beri Kesempatan & Hubungi $providerFirstName via Chat',
          variant: SakuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pushNamed(
            AppRoutes.orderChat,
            arguments: currentOrder,
          ),
        ),
        SakuTextLink(
          'Sisi penyedia: ajukan banding kompensasi 50:50  ›',
          color: AppColors.textSecondary,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.appeal,
            arguments: currentOrder,
          ),
        ),
      ],
    );
  }
}