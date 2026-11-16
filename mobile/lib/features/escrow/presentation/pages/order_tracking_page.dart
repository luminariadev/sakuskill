import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
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
import '../../data/models/escrow_order_model.dart';

/// Figma "14B · Tracking pesanan" (sisi klien) + "15C · Keputusan tambahan
/// waktu" (sheet saat penyedia meminta perpanjangan).
class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  EscrowOrderModel? _order;
  bool _initialized = false;
  bool? _extensionApproved;
  bool _submittingDecision = false;

  // 1. INTEGRASI: Ambil argumen dari halaman pembayaran dan sinkronkan ke BE
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _order = widget.order ?? (args is EscrowOrderModel ? args : null);
    _syncLatestDetail();
  }

  Future<void> _syncLatestDetail() async {
    final targetId = _order?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
    final result =
        await AppScope.of(context).escrowRepository.fetchOrderDetail(targetId);
    if (!mounted) return;
    if (!result.isFallback || _order == null) {
      setState(() => _order = result.data);
    }
  }

  // 2. INTEGRASI: Kirim keputusan perpanjangan waktu ke BE via EscrowRepository
  Future<void> _reviewExtension(EscrowOrderModel? currentOrder) async {
    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final providerFullName =
        currentOrder?.namaLawanTransaksi ?? DemoData.order.provider;
    final providerFirstName = providerFullName.split(' ').first;

    final approved = await showSakuSheet<bool>(
      context,
      builder: (ctx) => _ExtensionDecisionSheet(
        orderCode: orderCode,
        providerFullName: providerFullName,
        providerFirstName: providerFirstName,
      ),
    );
    if (approved == null || !mounted || _submittingDecision) return;

    setState(() => _submittingDecision = true);
    final orderId =
        currentOrder?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';

    await AppScope.of(context).escrowRepository.decideTimeExtension(
          orderId: orderId,
          disetujui: approved,
        );

    if (!mounted) return;
    setState(() {
      _submittingDecision = false;
      _extensionApproved = approved;
      if (approved && _order != null && _order!.detikTersisa != null) {
        _order = _order!.copyWith(
          detikTersisa: _order!.detikTersisa! + (12 * 3600),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Tambahan waktu +12 jam disetujui.'
              : 'Permintaan ditolak. Tenggat tetap sesuai kesepakatan awal.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const demo = DemoData.order;
    final currentOrder = _order;

    // 3. INTEGRASI: Data dinamis status order, status dana escrow, & sisa waktu
    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final statusPesanan =
        (currentOrder?.statusPesanan ?? 'Dikerjakan').toUpperCase();
    final statusEscrow = currentOrder?.statusEscrow ?? 'Ditahan (Simulasi)';
    final amount = currentOrder?.harga ?? demo.amount;
    final providerFullName =
        currentOrder?.namaLawanTransaksi ?? demo.provider;
    final providerFirstName = providerFullName.split(' ').first;
    final serviceTitle = currentOrder?.judulLayanan ??
        'Desain Spanduk Toko Katering Berkah (3×1 Meter)';

    final baseSeconds = currentOrder?.detikTersisa ??
        (const Duration(days: 2, hours: 14, minutes: 30).inSeconds);
    final remaining = Duration(seconds: baseSeconds.clamp(0, 31536000));
    final remainingDays = remaining.inDays.clamp(1, 365);

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Status Pesanan Saya'),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        InfoBox(
          tone: SakuTone.success,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                '✓  STATUS: $statusPesanan · DANA: ${statusEscrow.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 15 / 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPressed,
                ),
              ),
              Text(
                'TUGAS TELAH DITERIMA OLEH ${providerFullName.toUpperCase()}!',
                style: const TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bubbleProviderText,
                ),
              ),
              Text(
                '$providerFirstName telah menyetujui brief Anda. Dana '
                '${formatRupiah(amount)} Anda berstatus $statusEscrow di Rekening '
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
        StatusTimeline(items: [
          const ('Pesanan Dibuat', TimelineState.done),
          const ('Diterima Penyedia', TimelineState.done),
          ('Dana $statusEscrow', TimelineState.done),
          ('Dikerjakan · Sisa Waktu $remainingDays Hari', TimelineState.current),
          const ('Pemeriksaan Hasil', TimelineState.pending),
        ]),
        CountdownCard(
          key: ValueKey('${_extensionApproved}_${remaining.inSeconds}'),
          label:
              'ESTIMASI TENGGAT PENGERJAAN OLEH ${providerFirstName.toUpperCase()}',
          remaining: remaining,
          showDays: true,
          note:
              'Jaminan Escrow: Jika penyedia terlambat tanpa konfirmasi, Anda '
              'berhak membatalkan dan menarik dana kembali.',
        ),
        if (_extensionApproved == null)
          StatusStrip(
            '$providerFirstName mengajukan tambahan waktu +12 jam · Tinjau  ›',
            tone: SakuTone.warning,
            bordered: true,
            onTap: () => _reviewExtension(currentOrder),
          ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                serviceTitle,
                style: const TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              PersonRow(
                name: providerFullName,
                subtitle: '4.9 ★ · Desainer Grafis Cibiru',
                asset: demo.providerAsset,
              ),
              Text(
                '✓ ${currentOrder?.lampiranKlien ?? 'Foto_Ayam_Bakar.jpg (3 MB)'}\n'
                '${currentOrder?.catatanBrief ?? 'Output: CMYK 300 DPI (PDF & JPG)'}',
                style: const TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // 4. INTEGRASI: Teruskan currentOrder saat berpindah halaman
        SakuButton(
          label: 'Buka Chat dengan $providerFirstName',
          onPressed: () => Navigator.of(context).pushNamed(
            AppRoutes.orderChat,
            arguments: currentOrder,
          ),
        ),
        SakuButton(
          label: 'Rincian Dana Escrow (${formatRupiah(amount)})',
          variant: SakuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.wallet),
        ),
        SakuTextLink(
          'Lihat simulasi: penyedia terlambat  ›',
          color: AppColors.textSecondary,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.lateStatus,
            arguments: currentOrder,
          ),
        ),
      ],
    );
  }
}

class _ExtensionDecisionSheet extends StatelessWidget {
  const _ExtensionDecisionSheet({
    required this.orderCode,
    required this.providerFullName,
    required this.providerFirstName,
  });

  final String orderCode;
  final String providerFullName;
  final String providerFirstName;

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
        InfoBox(
          text: 'ORDER $orderCode',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        InfoBox(
          tone: SakuTone.neutral,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                '$providerFullName mengajukan perpanjangan:',
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                '+12 Jam Tambahan',
                style: TextStyle(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                '75% Selesai (Draf Spanduk Telah Dibuat)',
                style: TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Text(
                'Memerlukan penyesuaian format cetak CMYK 300 DPI agar hasil print tajam.',
                style: TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Jika Anda setujui, $providerFirstName diberikan waktu tambahan tanpa sanksi. Jika Anda '
          'tolak, $providerFirstName wajib menyelesaikan sesuai batas waktu semula.',
          style: const TextStyle(
            fontSize: 12,
            height: 17 / 12,
            color: AppColors.textSecondary,
          ),
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