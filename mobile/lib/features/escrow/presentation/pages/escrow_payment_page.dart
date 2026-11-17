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
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "14 · Pembayaran escrow" (simulasi — tidak ada uang sungguhan).
class EscrowPaymentPage extends StatefulWidget {
  const EscrowPaymentPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<EscrowPaymentPage> createState() => _EscrowPaymentPageState();
}

class _EscrowPaymentPageState extends State<EscrowPaymentPage> {
  int _method = 0;
  bool _processing = false;

  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (widget.order != null) return widget.order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  /// Menjalankan alur resmi API v1.3:
  /// 1. POST /api/v1/payments -> status: pending[cite: 4]
  /// 2. POST /api/v1/payments/:orderId/simulate-success (atau simulate-failed)[cite: 4]
  /// 3. Ambil detail order terbaru dari server agar status_kode & paymentStatusKode sinkron[cite: 4].
  Future<void> _processPaymentSimulation(
    EscrowOrderModel? currentOrder, {
    required bool isSuccess,
  }) async {
    if (_processing) return;

    final orderId = currentOrder?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
    setState(() => _processing = true);
    SakuMotion.tick();

    final repo = AppScope.of(context).escrowRepository;

    try {
      // Langkah 1: Inisiasi (atau reset) record pembayaran di backend -> status "pending"[cite: 4]
      await repo.startPayment(orderId);

      // Langkah 2: Jalankan simulasi sukses atau gagal[cite: 4]
      final simResult = await repo.simulatePayment(
        orderId,
        berhasil: isSuccess,
        alasanGagal: isSuccess
            ? null
            : 'Simulasi saldo tidak mencukupi untuk demonstrasi alur gagal[cite: 4].',
      );

      // Langkah 3: Tarik ulang detail order terbaru dari server[cite: 4]
      final detailResult = await repo.fetchOrderDetail(orderId);
      final updatedOrder = detailResult.isFallback
          ? (currentOrder ?? detailResult.data).copyWith(
              statusPesanan: 'Dikerjakan',
              statusKode: 'in_progress',
              paymentStatusKode: simResult.data.statusKode,
              bolehLanjutInProgress: simResult.data.bolehLanjutInProgress,
              statusEscrow: isSuccess
                  ? 'Dana Ditahan (Simulasi)'
                  : 'Pembayaran Gagal (Simulasi)',
            )
          : detailResult.data;

      if (!mounted) return;

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran simulasi berhasil (${simResult.data.referensiSimulasi})! '
              'Menunggu penyedia memulai pengerjaan.',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );

        Navigator.of(context).pushReplacementNamed(
          AppRoutes.tracking,
          arguments: updatedOrder,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Simulasi Pembayaran GAGAL. Order tertahan di status Disepakati '
              'dan penyedia belum bisa memulai pekerjaan[cite: 4].',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } on EscrowException catch (e) {
      if (!mounted) return;
      String errorMessage = e.message;
      if (e.code == 'INVALID_ORDER_STATE_FOR_PAYMENT') {
        errorMessage =
            'Pesanan harus disetujui penyedia terlebih dahulu sebelum dibayar[cite: 4].';
      } else if (e.code == 'FORBIDDEN_ONLY_CUSTOMER') {
        errorMessage =
            'Hanya pelanggan yang membuat pesanan yang dapat melakukan pembayaran[cite: 4].';
      } else if (e.code == 'PAYMENT_ALREADY_SUCCESS') {
        errorMessage = 'Pesanan ini sudah berhasil dibayar sebelumnya[cite: 4].';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses pembayaran: $e'),
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

    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final serviceTitle =
        currentOrder?.judulLayanan ?? 'Desain Spanduk Katering Berkah';
    final rawAmount = currentOrder?.harga ?? demo.amount;
    final amount = formatRupiah(rawAmount);
    final providerName =
        currentOrder?.namaLawanTransaksi?.split(' ').first ?? 'Salma';

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pembayaran\nRekening Bersama'),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                serviceTitle,
                style: const TextStyle(
                  fontSize: 15,
                  height: 21 / 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AmountRow('Harga jasa', amount),
              const AmountRow('Biaya Layanan SakuSkill', 'Rp 0'),
              const Text(
                'Simulasi Gratis (MVP)',
                style: TextStyle(
                  fontSize: 11,
                  height: 15 / 11,
                  color: AppColors.primary,
                ),
              ),
              AmountRow('Total Bayar', amount, total: true),
            ],
          ),
        ),
        const Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SelectableOption(
          title: 'Saldo Dompet SakuSkill',
          subtitle: 'Tersedia ${formatRupiah(DemoData.balance)}',
          selected: _method == 0,
          onTap: () => setState(() => _method = 0),
        ),
        SelectableOption(
          title: 'Transfer Bank Otomatis',
          subtitle: 'BCA / Mandiri / BRI',
          selected: _method == 1,
          onTap: () => setState(() => _method = 1),
        ),
        SelectableOption(
          title: 'QRIS Instan',
          selected: _method == 2,
          onTap: () => setState(() => _method = 2),
        ),
        InfoBox(
          text:
              'DISCLAIMER MVP: Bukan uang sungguhan & bukan rekening escrow perbankan nyata[cite: 4]. '
              'Dana simulasi hanya diteruskan ke $providerName setelah Anda menyetujui hasil kerja.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        SakuButton(
          key: const Key('payment-submit'),
          label: _processing
              ? 'Memproses Simulasi...'
              : 'Bayar & Kunci Dana di Escrow ($amount)',
          onPressed: _processing
              ? null
              : () => _processPaymentSimulation(currentOrder, isSuccess: true),
        ),
        OutlinedButton(
          onPressed: _processing
              ? null
              : () => _processPaymentSimulation(currentOrder, isSuccess: false),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade300),
            minimumSize: const Size.fromHeight(44),
          ),
          child: const Text('Uji Simulasi Pembayaran Gagal (Demo MVP)'),
        ),
      ],
    );
  }
}