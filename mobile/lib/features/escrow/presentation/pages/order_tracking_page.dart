import 'dart:async';
import 'package:flutter/material.dart';

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
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "14B · Tracking pesanan" + "15C · Keputusan tambahan waktu".
class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  EscrowOrderModel? _order;
  bool _initialized = false;
  bool _isDemoFallback = false;
  bool? _extensionApproved;
  bool _submittingAction = false;
  Timer? _clockTimer;
  Timer? _pollTimer;
  String _liveClock = formatClockSeconds(DateTime.now());

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _liveClock = formatClockSeconds(DateTime.now()));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _order = widget.order ?? (args is EscrowOrderModel ? args : null);
    _syncLatestDetail();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _syncLatestDetail(),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncLatestDetail() async {
    final targetId = _order?.orderId;
    if (targetId == null || targetId.isEmpty) return;

    final result =
        await AppScope.of(context).escrowRepository.fetchOrderDetail(targetId);
    if (!mounted) return;
    setState(() {
      _isDemoFallback = result.isFallback;
      if (!result.isFallback || _order == null) {
        _order = result.data;
      }
    });
  }

  /// POST /api/v1/orders/:id/start (Penyedia memulai pengerjaan; wajib payment success)
  Future<void> _startWork(EscrowOrderModel currentOrder) async {
    if (_submittingAction) return;
    setState(() => _submittingAction = true);
    SakuMotion.tick();

    final repo = AppScope.of(context).escrowRepository;
    try {
      final res = await repo.startWork(currentOrder.orderId);
      if (!mounted) return;
      setState(() => _order = res.data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pengerjaan resmi dimulai (Status: Dikerjakan).'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      final pesan = e.code == 'PAYMENT_REQUIRED_BEFORE_START'
          ? 'Pembayaran belum lunas! Pelanggan harus menyelesaikan simulasi pembayaran sebelum pengerjaan dimulai.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submittingAction = false);
    }
  }

  /// POST /api/v1/orders/:id/request-completion (Penyedia mengirim hasil kerja)
  Future<void> _requestCompletion(EscrowOrderModel currentOrder) async {
    if (_submittingAction) return;
    setState(() => _submittingAction = true);
    SakuMotion.tick();

    final repo = AppScope.of(context).escrowRepository;
    try {
      await repo.requestCompletion(
        orderId: currentOrder.orderId,
        tautanBerkas:
            'https://sakuskill.id/deliverables/${currentOrder.kodePesanan}',
        catatanPenyedia: 'Hasil pekerjaan telah diunggah sesuai brief.',
      );
      await _syncLatestDetail();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Hasil pekerjaan berhasil dikirim! Menunggu konfirmasi pelanggan.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submittingAction = false);
    }
  }

  /// POST /api/v1/orders/:id/complete (Pelanggan konfirmasi selesai & lepas dana)
  Future<void> _confirmCompletion(EscrowOrderModel currentOrder) async {
    if (_submittingAction) return;
    setState(() => _submittingAction = true);
    SakuMotion.tick();

    final repo = AppScope.of(context).escrowRepository;
    try {
      await repo.confirmCompletion(currentOrder.orderId);
      final updatedRes = await repo.fetchOrderDetail(currentOrder.orderId);
      final finalOrder = updatedRes.isFallback
          ? currentOrder.copyWith(
              statusKode: 'completed',
              statusPesanan: 'Selesai',
              statusEscrow: 'Dana Dilepas ke Penyedia (Simulasi)',
            )
          : updatedRes.data;

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.orderDone,
        arguments: finalOrder,
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submittingAction = false);
    }
  }

  /// POST /api/v1/orders/:id/time-extensions/decide (Pelanggan menyetujui/menolak tambahan waktu)
  Future<void> _reviewExtension(EscrowOrderModel currentOrder) async {
    final ext = currentOrder.activeTimeExtension;
    if (ext == null || !ext.isPending) return;

    final providerFullName =
        currentOrder.namaLawanTransaksi ?? DemoData.order.provider;
    final providerFirstName = providerFullName.split(' ').first;

    final approved = await showSakuSheet<bool>(
      context,
      builder: (ctx) => _ExtensionDecisionSheet(
        orderCode: currentOrder.kodePesanan,
        providerFullName: providerFullName,
        providerFirstName: providerFirstName,
        tambahanJam: ext.tambahanJam,
        alasan: ext.alasan,
      ),
    );
    if (approved == null || !mounted || _submittingAction) return;

    setState(() => _submittingAction = true);
    try {
      final res =
          await AppScope.of(context).escrowRepository.decideTimeExtension(
                orderId: currentOrder.orderId,
                disetujui: approved,
              );
      if (!mounted) return;
      setState(() {
        _order = res.data;
        _extensionApproved = approved;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Tambahan waktu +${ext.tambahanJam} jam disetujui. Tenggat diperpanjang.'
                : 'Permintaan ditolak. Tenggat tetap sesuai kesepakatan awal.',
          ),
          backgroundColor:
              approved ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submittingAction = false);
    }
  }

  List<String> _buildBriefLines(EscrowOrderModel? currentOrder) {
    if (currentOrder == null) {
      return const [
        '✓ Foto_Ayam_Bakar.jpg (3 MB)',
        'Output: CMYK 300 DPI (PDF & JPG)',
      ];
    }

    final lines = <String>[];
    if (currentOrder.deskripsiBrief != null &&
        currentOrder.deskripsiBrief!.trim().isNotEmpty) {
      lines.add('Brief: ${currentOrder.deskripsiBrief!.trim()}');
    }
    if (currentOrder.catatanBrief != null &&
        currentOrder.catatanBrief!.trim().isNotEmpty) {
      lines.add('Catatan: ${currentOrder.catatanBrief!.trim()}');
    }
    if (currentOrder.lampiranKlien != null &&
        currentOrder.lampiranKlien!.trim().isNotEmpty) {
      lines.add('✓ Lampiran: ${currentOrder.lampiranKlien!.trim()}');
    }
    if (lines.isEmpty) {
      lines.add('✓ Pesanan terverifikasi melalui SakuSkill Escrow');
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    const demo = DemoData.order;
    final currentOrder = _order;

    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final statusKode = (currentOrder?.statusKode ?? 'in_progress').toLowerCase();
    final isCancelled = statusKode == 'cancelled' || statusKode == 'dibatalkan';

    final statusPesanan =
        (currentOrder?.statusPesanan ?? 'Dikerjakan').toUpperCase();
    final statusEscrow = currentOrder?.statusEscrow ?? 'Dana Ditahan (Simulasi)';
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

    final isPaid = currentOrder?.bolehLanjutInProgress ?? false;
    final pendingExt = currentOrder?.activeTimeExtension;
    final briefLines = _buildBriefLines(currentOrder);

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PageHeader('Status Pesanan Saya'),
            IconButton(
              onPressed: _syncLatestDetail,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              tooltip: 'Muat ulang status terbaru dari server',
            ),
          ],
        ),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Sinkronisasi Realtime · $_liveClock',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        if (_isDemoFallback)
          const InfoBox(
            text:
                'MODE DEMO: Server tidak terjangkau, menampilkan data simulasi lokal.',
            tone: SakuTone.warning,
            fontWeight: FontWeight.w600,
          ),
        InfoBox(
          tone: isCancelled
              ? SakuTone.neutral
              : (statusKode == 'accepted' && !isPaid
                  ? SakuTone.warning
                  : SakuTone.success),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                isCancelled
                    ? 'STATUS: DIBATALKAN · DANA DIKEMBALIKAN KE DOMPET'
                    : '✓  STATUS: $statusPesanan · DANA: ${statusEscrow.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 15 / 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPressed,
                ),
              ),
              Text(
                isCancelled
                    ? 'PESANAN TELAH DIBATALKAN'
                    : (statusKode == 'accepted'
                        ? (isPaid
                            ? 'PEMBAYARAN LUNAS · SIAP DIKERJAKAN'
                            : 'MENUNGGU PEMBAYARAN PELANGGAN')
                        : 'PESANAN DITANGANI OLEH ${providerFullName.toUpperCase()}'),
                style: const TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bubbleProviderText,
                ),
              ),
              Text(
                isCancelled
                    ? 'Status pesanan: DIBATALKAN. Seluruh dana sebesar ${formatRupiah(amount)} telah dikembalikan ke Dompet SakuSkill.'
                    : (statusKode == 'accepted' && isPaid
                        ? 'Dana ${formatRupiah(amount)} telah diamankan di Escrow (Simulasi). Penyedia jasa kini dapat menekan tombol Mulai Kerjakan.'
                        : 'Status pesanan: $statusPesanan. Dana ${formatRupiah(amount)} berstatus $statusEscrow.'),
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: AppColors.bubbleProviderText,
                ),
              ),
            ],
          ),
        ),
        if (!isCancelled)
          StatusTimeline(items: [
            const ('Pesanan Dibuat', TimelineState.done),
            const ('Diterima Penyedia', TimelineState.done),
            (
              'Dana $statusEscrow',
              isPaid ? TimelineState.done : TimelineState.current,
            ),
            (
              'Dikerjakan · Sisa Waktu $remainingDays Hari',
              statusKode == 'in_progress'
                  ? TimelineState.current
                  : (statusKode == 'completion_requested' ||
                          statusKode == 'completed'
                      ? TimelineState.done
                      : TimelineState.pending),
            ),
            (
              'Pemeriksaan Hasil',
              statusKode == 'completion_requested'
                  ? TimelineState.current
                  : (statusKode == 'completed'
                      ? TimelineState.done
                      : TimelineState.pending),
            ),
          ]),

        // --- AKSI SESUAI STATE MACHINE API v1.3 ---
        if (currentOrder != null && !isCancelled) ...[
          // 1. Jika accepted tapi belum dibayar -> Tombol Bayar untuk Pelanggan
          if (statusKode == 'accepted' && !isPaid)
            SakuButton(
              label: 'Lanjut Simulasi Pembayaran (${formatRupiah(amount)})',
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.payment,
                arguments: currentOrder,
              ),
            ),

          // 2. Jika accepted & sudah dibayar -> Tombol Mulai Kerjakan untuk Penyedia
          if (statusKode == 'accepted' && isPaid)
            SakuButton(
              label: _submittingAction
                  ? 'Memulai Pengerjaan...'
                  : 'Mulai Kerjakan Pesanan (Penyedia)',
              onPressed:
                  _submittingAction ? null : () => _startWork(currentOrder),
            ),

          // 3. Jika in_progress -> Tombol Kirim Hasil & Buka Workroom untuk Penyedia
          if (statusKode == 'in_progress') ...[
            SakuButton(
              label: _submittingAction
                  ? 'Mengirim Hasil...'
                  : 'Kirim Hasil Kerja & Ajukan Selesai (Penyedia)',
              onPressed: _submittingAction
                  ? null
                  : () => _requestCompletion(currentOrder),
            ),
            SakuButton(
              label: 'Buka Ruang Pengerjaan / Ajukan Tambahan Waktu',
              variant: SakuButtonVariant.outline,
              onPressed: () async {
                await Navigator.of(context).pushNamed(
                  AppRoutes.workroom,
                  arguments: currentOrder,
                );
                _syncLatestDetail();
              },
            ),
          ],

          // 4. Jika completion_requested -> Tombol Periksa Hasil / Konfirmasi Selesai untuk Pelanggan
          if (statusKode == 'completion_requested') ...[
            SakuButton(
              label: 'Periksa Hasil Kerja & Ajukan Revisi',
              onPressed: () async {
                await Navigator.of(context).pushNamed(
                  AppRoutes.reviewWork,
                  arguments: currentOrder,
                );
                _syncLatestDetail();
              },
            ),
            SakuButton(
              label: _submittingAction
                  ? 'Melepas Dana...'
                  : 'Konfirmasi Selesai & Lepas Dana (Pelanggan)',
              variant: SakuButtonVariant.outline,
              onPressed: _submittingAction
                  ? null
                  : () => _confirmCompletion(currentOrder),
            ),
          ],

          // 5. Jika completed -> Tombol Beri Ulasan
          if (statusKode == 'completed')
            SakuButton(
              label: 'Lihat Ringkasan & Beri Ulasan',
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.orderDone,
                arguments: currentOrder,
              ),
            ),
        ],

        if (!isCancelled)
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
        if (currentOrder != null &&
            pendingExt != null &&
            pendingExt.isPending &&
            statusKode == 'in_progress')
          StatusStrip(
            '$providerFirstName mengajukan tambahan waktu +${pendingExt.tambahanJam} jam · Tinjau  ›',
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
                subtitle: currentOrder != null
                    ? '${currentOrder.peranLawanTransaksi ?? 'Penyedia Jasa'} · $orderCode'
                    : '4.9 ★ · Desainer Grafis Cibiru',
                asset: currentOrder == null ? demo.providerAsset : null,
              ),
              Text(
                briefLines.join('\n'),
                style: const TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (currentOrder?.tautanBerkas != null &&
                  currentOrder!.tautanBerkas!.trim().isNotEmpty)
                InfoBox(
                  tone: SakuTone.escrow,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      const Text(
                        'Hasil Pekerjaan Penyedia:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        currentOrder.tautanBerkas!,
                        style: AppTypography.mono.copyWith(
                          fontSize: 11,
                          color: AppColors.escrow,
                        ),
                      ),
                      if (currentOrder.catatanPenyedia != null &&
                          currentOrder.catatanPenyedia!.trim().isNotEmpty)
                        Text(
                          currentOrder.catatanPenyedia!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SakuButton(
          label: 'Buka Chat dengan $providerFirstName',
          variant: SakuButtonVariant.outline,
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
        if (!isCancelled)
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
    required this.tambahanJam,
    required this.alasan,
  });

  final String orderCode;
  final String providerFullName;
  final String providerFirstName;
  final int tambahanJam;
  final String alasan;

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
              Text(
                '+$tambahanJam Jam Tambahan',
                style: const TextStyle(
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                alasan,
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
          label: 'Setujui Tambahan Waktu (+$tambahanJam Jam)',
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