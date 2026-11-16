import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';

/// Figma "14B · Tracking pesanan" (sisi klien) + "15C · Keputusan tambahan
/// waktu" (sheet saat penyedia meminta perpanjangan).
class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  bool? _extensionApproved;

  Future<void> _reviewExtension() async {
    final approved = await showSakuSheet<bool>(
      context,
      builder: (ctx) => const _ExtensionDecisionSheet(),
    );
    if (approved == null || !mounted) return;
    setState(() => _extensionApproved = approved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approved
            ? 'Tambahan waktu +12 jam disetujui.'
            : 'Permintaan ditolak. Tenggat tetap sesuai kesepakatan awal.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const order = DemoData.order;
    final remaining = Duration(
      days: 2,
      hours: 14 + (_extensionApproved == true ? 12 : 0),
      minutes: 30,
    );
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Status Pesanan Saya'),
        Text('#SK-2026-091',
            style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        InfoBox(
          tone: SakuTone.success,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const Text(
                '✓  STATUS: DIKERJAKAN',
                style: TextStyle(
                  fontSize: 11,
                  height: 15 / 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPressed,
                ),
              ),
              const Text(
                'TUGAS TELAH DITERIMA OLEH SALMA NUR OKTAVIA!',
                style: TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bubbleProviderText,
                ),
              ),
              Text(
                'Salma telah menyetujui brief spanduk Anda. Dana '
                '${formatRupiah(order.amount)} Anda telah diamankan di Rekening '
                'Bersama Escrow dan proses pengerjaan resmi dimulai.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: AppColors.bubbleProviderText,
                ),
              ),
            ],
          ),
        ),
        const StatusTimeline(items: [
          ('Pesanan Dibuat', TimelineState.done),
          ('Diterima Penyedia', TimelineState.done),
          ('Dana Diamankan Escrow', TimelineState.done),
          ('Dikerjakan · Sisa Waktu 2 Hari', TimelineState.current),
          ('Pemeriksaan Hasil', TimelineState.pending),
        ]),
        CountdownCard(
          key: ValueKey(_extensionApproved),
          label: 'ESTIMASI TENGGAT PENGERJAAN OLEH SALMA',
          remaining: remaining,
          showDays: true,
          note: 'Jaminan Escrow: Jika penyedia terlambat tanpa konfirmasi, Anda '
              'berhak membatalkan dan menarik dana kembali.',
        ),
        if (_extensionApproved == null)
          StatusStrip(
            'Salma mengajukan tambahan waktu +12 jam · Tinjau  ›',
            tone: SakuTone.warning,
            bordered: true,
            onTap: _reviewExtension,
          ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const Text(
                'Desain Spanduk Toko Katering Berkah (3×1 Meter)',
                style: TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              PersonRow(
                name: order.provider,
                subtitle: '4.9 ★ · Desainer Grafis Cibiru',
                asset: order.providerAsset,
              ),
              const Text(
                '✓ Foto_Ayam_Bakar.jpg (3 MB)\nOutput: CMYK 300 DPI (PDF & JPG)',
                style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        SakuButton(
          label: 'Buka Chat dengan Salma',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.orderChat),
        ),
        SakuButton(
          label: 'Rincian Dana Escrow (${formatRupiah(order.amount)})',
          variant: SakuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.wallet),
        ),
        SakuTextLink(
          'Lihat simulasi: penyedia terlambat  ›',
          color: AppColors.textSecondary,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.lateStatus),
        ),
      ],
    );
  }
}

class _ExtensionDecisionSheet extends StatelessWidget {
  const _ExtensionDecisionSheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Text(
          'Permintaan Tambahan Waktu Pengerjaan',
          style: TextStyle(
            fontSize: 18,
            height: 25 / 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const InfoBox(
          text: 'ORDER #SK-2026-091',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        const InfoBox(
          tone: SakuTone.neutral,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                'Salma Nur Oktavia mengajukan perpanjangan:',
                style: TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '+12 Jam Tambahan',
                style: TextStyle(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '75% Selesai (Draf Spanduk Telah Dibuat)',
                style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
              ),
              Text(
                'Memerlukan penyesuaian format cetak CMYK 300 DPI agar hasil print tajam.',
                style: TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const Text(
          'Jika Anda setujui, Salma diberikan waktu tambahan tanpa sanksi. Jika Anda '
          'tolak, Salma wajib menyelesaikan sesuai batas waktu semula.',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        SakuButton(
          key: const Key('extension-approve'),
          label: 'Setujui Tambahan Waktu (+12 Jam)',
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pop(true);
          },
        ),
        SakuButton(
          label: 'Tolak (Tetap Sesuai Batas Waktu Awal)',
          variant: SakuButtonVariant.destructive,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
