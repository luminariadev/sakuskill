import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "15D · Status terlambat" (sisi klien) + "15D-2 · Konfirmasi
/// pembatalan".
class LateStatusPage extends StatelessWidget {
  const LateStatusPage({super.key});

  Future<void> _cancel(BuildContext context) async {
    final amount = formatRupiah(DemoData.order.amount);
    final confirmed = await showSakuSheet<bool>(
      context,
      builder: (ctx) => SakuSheetContent(
        title: 'Batalkan Pesanan & Tarik Dana 100%?',
        message: 'Karena penyedia telah terlambat lebih dari 12 jam, Anda berhak '
            'membatalkan pesanan ini secara sepihak.',
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
                  style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
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
    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        SnackBar(content: Text('Pesanan dibatalkan. $amount kembali ke Dompet SakuSkill.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const late = TextStyle(color: AppColors.danger);
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pesanan #SK-091'),
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
              Text('!  PESANAN MELEWATI TENGGAT',
                  style: late.copyWith(fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w700)),
              Text('Masa Tenggang Keterlambatan',
                  style: late.copyWith(fontSize: 12, height: 17 / 12, fontWeight: FontWeight.w600)),
              Text('14 Jam Berjalan',
                  style: late.copyWith(fontSize: 26, height: 36 / 26, fontWeight: FontWeight.w800)),
              Text('Sisa 10 Jam dari masa tenggang 24 jam',
                  style: late.copyWith(fontSize: 13, height: 18 / 13)),
            ],
          ),
        ),
        const SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                'Hak Pembatalan Klien',
                style: TextStyle(
                  fontSize: 17,
                  height: 24 / 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Keterlambatan telah berjalan lebih dari 12 jam (Jam ke-14). Anda berhak '
                'membatalkan pesanan secara sepihak dan menarik seluruh dana simulasi '
                'Anda 100%.',
                style: TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        SakuButton(
          key: const Key('late-cancel'),
          label: 'Batalkan Pesanan & Tarik Dana 100%',
          variant: SakuButtonVariant.destructive,
          onPressed: () => _cancel(context),
        ),
        SakuButton(
          label: 'Beri Kesempatan & Hubungi Salma via Chat',
          variant: SakuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.orderChat),
        ),
        SakuTextLink(
          'Sisi penyedia: ajukan banding kompensasi 50:50  ›',
          color: AppColors.textSecondary,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.appeal),
        ),
      ],
    );
  }
}
