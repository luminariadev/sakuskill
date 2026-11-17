import 'package:flutter/material.dart';

import 'escrow_payment_page.dart';
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
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "12 · Pesanan masuk" (sisi penyedia) + "12B · Tolak pesanan"
/// serta status menunggu / lanjut bayar escrow (sisi pelanggan).
class IncomingOrderPage extends StatefulWidget {
  const IncomingOrderPage({super.key, this.order, this.isProviderView});

  final EscrowOrderModel? order;
  final bool? isProviderView;

  @override
  State<IncomingOrderPage> createState() => _IncomingOrderPageState();
}

class _IncomingOrderPageState extends State<IncomingOrderPage> {
  bool _processing = false;
  EscrowOrderModel? _refreshedOrder;

  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (_refreshedOrder != null) return _refreshedOrder;
    if (widget.order != null) return widget.order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  /// GET /api/v1/orders/:id — menyegarkan status terbaru pesanan dari backend
  Future<void> _refreshOrder(EscrowOrderModel? currentOrder) async {
    if (_processing || currentOrder == null || currentOrder.orderId.isEmpty) {
      return;
    }
    setState(() => _processing = true);
    try {
      final remote = EscrowRemoteDataSource(
        tokenProvider: () async => AuthSession.instance.accessToken,
      );
      final detail = await remote.fetchOrderDetail(currentOrder.orderId);
      if (!mounted) return;
      setState(() => _refreshedOrder = detail);
    } on EscrowException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyegarkan status pesanan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// POST /api/v1/orders/:id/accept
  Future<void> _accept(EscrowOrderModel? currentOrder) async {
    if (_processing) return;
    SakuMotion.tick();

    if (currentOrder == null || currentOrder.orderId.isEmpty) {
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.orderChat, arguments: currentOrder);
      return;
    }

    setState(() => _processing = true);
    final repo = AppScope.of(context).escrowRepository;

    try {
      final result = await repo.acceptOrder(currentOrder.orderId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pesanan disetujui! Status berubah menjadi Disepakati (Menunggu Pembayaran).',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.orderChat, arguments: result.data);
    } on EscrowException catch (e) {
      if (!mounted) return;
      final pesan = e.code == 'INVALID_STATE_TRANSITION'
          ? 'Pesanan ini sudah diproses sebelumnya.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.red.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui pesanan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// POST /api/v1/orders/:id/reject
  Future<void> _reject(
    EscrowOrderModel? currentOrder,
    String clientName,
  ) async {
    if (_processing) return;

    final reasonText = await showSakuSheet<String>(
      context,
      builder: (_) => _RejectSheet(clientName: clientName),
    );

    if (reasonText == null || !mounted) return;

    if (currentOrder == null || currentOrder.orderId.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Pesanan ditolak. $clientName sudah diberi tahu.'),
        ),
      );
      return;
    }

    setState(() => _processing = true);
    final repo = AppScope.of(context).escrowRepository;

    try {
      await repo.rejectOrder(currentOrder.orderId, alasan: reasonText);
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Pesanan resmi ditolak. $clientName sudah diberi tahu.',
          ),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menolak pesanan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const demo = DemoData.order;
    final currentOrder = _resolveOrder(context);
    final session = AuthSession.instance;

    // Tentukan apakah pengguna aktif adalah Penyedia Jasa pada pesanan ini
    final bool isProviderRole = widget.isProviderView ?? session.isProvider;

    final statusKode = (currentOrder?.statusKode ?? 'submitted').toLowerCase();
    final isSubmitted = statusKode == 'submitted' || statusKode == 'diajukan';
    final isAccepted = statusKode == 'accepted' || statusKode == 'disepakati';

    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final serviceTitle =
        currentOrder?.judulLayanan ?? 'Desain Spanduk Toko Ukuran 3×1 m';
    final amount = currentOrder?.harga ?? demo.amount;
    final deadlineDays = currentOrder?.detikTersisa != null
        ? (currentOrder!.detikTersisa! / 86400).ceil().clamp(1, 365)
        : demo.deadlineDays;
    final briefNote =
        currentOrder?.catatanBrief ??
        'Warna cerah, lampiran foto menu ayam bakar.';
    final attachment = currentOrder?.lampiranKlien ?? 'Foto_Ayam_Bakar.jpg';
    final counterpartyName =
        currentOrder?.namaLawanTransaksi ?? 'Dimas (Katering Berkah Cibiru)';
    final counterpartyShortName = counterpartyName.split(' ').first;

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        PageHeader(
          isProviderRole ? 'Pesanan Baru Masuk' : 'Detail Pengajuan Pesanan',
        ),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        InfoBox(
          text:
              '${(currentOrder?.statusPesanan ?? 'PESANAN BARU').toUpperCase()} · ${isAccepted ? 'SIAP PEMBAYARAN ESCROW' : 'MENUNGGU RESPONS'}',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              PersonRow(
                name: counterpartyName,
                subtitle: isProviderRole
                    ? 'Pelanggan · Cibiru, Bandung'
                    : 'Penyedia Jasa · Cibiru, Bandung',
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
        if (isProviderRole) ...[
          if (isSubmitted) ...[
            SakuButton(
              key: const Key('incoming-accept'),
              label: _processing
                  ? 'Menyetujui Pesanan...'
                  : 'Terima & Sepakati Pesanan',
              onPressed: _processing ? null : () => _accept(currentOrder),
            ),
            SakuButton(
              key: const Key('incoming-reject'),
              label: 'Tolak Pesanan',
              variant: SakuButtonVariant.destructive,
              onPressed: _processing
                  ? null
                  : () => _reject(currentOrder, counterpartyShortName),
            ),
            const InfoBox(
              text: 'Jika menolak, pilih alasan agar komunikasi dengan klien tetap profesional.',
              tone: SakuTone.neutral,
              fontWeight: FontWeight.w500,
            ),
          ] else ...[
            InfoBox(
              text: isAccepted
                  ? 'Pesanan sudah Anda setujui. Menunggu pelanggan menyelesaikan pembayaran ke rekening escrow.'
                  : 'Status pesanan saat ini: ${currentOrder?.statusPesanan ?? statusKode}.',
              tone: SakuTone.escrow,
              fontWeight: FontWeight.w500,
            ),
            SakuButton(
              label: _processing ? 'Memuat...' : 'Segarkan Status Pesanan',
              onPressed: _processing ? null : () => _refreshOrder(currentOrder),
            ),
          ],
        ] else ...[
          if (isAccepted) ...[
            SakuButton(
              key: const Key('customer-pay-escrow'),
              label: 'Lanjut Pembayaran Escrow',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => EscrowPaymentPage(order: currentOrder),
                  ),
                );
              },
            ),
            const InfoBox(
              text: 'Penyedia jasa telah menyetujui pesanan Anda. Silakan amankan dana ke Rekening Bersama Escrow untuk memulai pengerjaan.',
              tone: SakuTone.escrow,
              fontWeight: FontWeight.w500,
            ),
          ] else ...[
            InfoBox(
              text: isSubmitted
                  ? 'Pesanan Anda sudah terkirim ke $counterpartyName. Menunggu penyedia jasa menyetujui pesanan sebelum pembayaran escrow dibuka.'
                  : 'Status pesanan saat ini: ${currentOrder?.statusPesanan ?? statusKode}.',
              tone: SakuTone.escrow,
              fontWeight: FontWeight.w500,
            ),
            SakuButton(
              key: const Key('customer-refresh-order'),
              label: _processing
                  ? 'Memeriksa Status...'
                  : 'Segarkan Status Pesanan',
              onPressed: _processing ? null : () => _refreshOrder(currentOrder),
            ),
          ],
        ],
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
  final _noteController = TextEditingController();

  static const _reasons = [
    'Jadwal pengerjaan saya saat ini sedang penuh',
    'Spesifikasi brief di luar keahlian/lingkup saya',
    'Tenggat waktu yang diminta terlalu singkat',
    'Alasan lainnya...',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SakuSheetContent(
      title: 'Tolak Pesanan Ini?',
      message:
          'Beri tahu ${widget.clientName} alasan Anda tidak dapat menerima pesanan ini '
          'agar komunikasi tetap profesional:',
      body: [
        RadioOptions(
          options: _reasons,
          selected: _reason,
          onChanged: (i) => setState(() => _reason = i),
        ),
        SakuTextField(
          controller: _noteController,
          label: 'Catatan tambahan (opsional)',
          hint: 'Tuliskan pesan singkat untuk ${widget.clientName}...',
          minLines: 2,
          maxLines: 4,
        ),
      ],
      confirmLabel: 'Konfirmasi Tolak Pesanan',
      confirmVariant: SakuButtonVariant.destructive,
      cancelLabel: 'Kembali (Batal Menolak)',
      onConfirm: () {
        final selectedReason = _reasons[_reason];
        final extra = _noteController.text.trim();
        final fullReason = extra.isNotEmpty
            ? '$selectedReason ($extra)'
            : selectedReason;
        Navigator.of(context).pop(fullReason);
      },
    );
  }
}
