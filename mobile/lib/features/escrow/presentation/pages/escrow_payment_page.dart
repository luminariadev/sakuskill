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
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
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

  // 1. INTEGRASI: Ambil data order dari parameter atau argumen navigasi
  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (widget.order != null) return widget.order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  // 2. INTEGRASI: Proses pembayaran simulasi & ubah status dana menjadi Ditahan (Simulasi)
  Future<void> _payAndLockEscrow(EscrowOrderModel? currentOrder) async {
    if (_processing) return;
    setState(() => _processing = true);
    SakuMotion.tick();

    final repo = AppScope.of(context).escrowRepository;
    EscrowOrderModel updatedOrder;

    if (currentOrder != null) {
      // Coba sinkronkan status terbaru dari BE jika tersedia
      final detailResult = await repo.fetchOrderDetail(currentOrder.orderId);
      final base = detailResult.isFallback ? currentOrder : detailResult.data;

      updatedOrder = base.copyWith(
        statusPesanan: 'Dikerjakan',
        statusEscrow: 'Ditahan (Simulasi)',
        stepperTahap: 2,
      );
    } else {
      final fallbackResult =
          await repo.fetchOrderDetail('9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d');
      updatedOrder = fallbackResult.data.copyWith(
        statusPesanan: 'Dikerjakan',
        statusEscrow: 'Ditahan (Simulasi)',
        stepperTahap: 2,
      );
    }

    if (!mounted) return;
    setState(() => _processing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pembayaran simulasi berhasil! Status dana: Ditahan (Simulasi).',
        ),
      ),
    );

    // 4. INTEGRASI: Teruskan order dengan status Ditahan (Simulasi) ke OrderTrackingPage
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.tracking,
      arguments: updatedOrder,
    );
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
                'Simulasi Gratis',
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
        // 3. INTEGRASI: InfoBox dinamis sesuai nama penyedia
        InfoBox(
          text:
              'Status Dana: Ditahan Simulasi di Penampungan SakuSkill. Dana HANYA '
              'diteruskan ke $providerName setelah Anda memeriksa dan menyetujui hasil kerja.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        SakuButton(
          key: const Key('payment-submit'),
          label: _processing
              ? 'Memproses Pembayaran...'
              : 'Bayar & Kunci Dana di Escrow ($amount)',
          onPressed: _processing ? null : () => _payAndLockEscrow(currentOrder),
        ),
      ],
    );
  }
}