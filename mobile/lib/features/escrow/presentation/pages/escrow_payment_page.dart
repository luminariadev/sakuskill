import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';

/// Figma "14 · Pembayaran escrow" (simulasi — tidak ada uang sungguhan).
class EscrowPaymentPage extends StatefulWidget {
  const EscrowPaymentPage({super.key});

  @override
  State<EscrowPaymentPage> createState() => _EscrowPaymentPageState();
}

class _EscrowPaymentPageState extends State<EscrowPaymentPage> {
  int _method = 0;

  @override
  Widget build(BuildContext context) {
    const order = DemoData.order;
    final amount = formatRupiah(order.amount);
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pembayaran\nRekening Bersama'),
        Text(
          '#SK-2026-091',
          style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textSecondary),
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const Text(
                'Desain Spanduk Katering Berkah',
                style: TextStyle(
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
                style: TextStyle(fontSize: 11, height: 15 / 11, color: AppColors.primary),
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
        const InfoBox(
          text: 'Status Dana: Ditahan Simulasi di Penampungan SakuSkill. Dana HANYA '
              'diteruskan ke Salma setelah Anda memeriksa dan menyetujui hasil kerja.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        SakuButton(
          key: const Key('payment-submit'),
          label: 'Bayar & Kunci Dana di Escrow ($amount)',
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pushReplacementNamed(AppRoutes.tracking);
          },
        ),
      ],
    );
  }
}
