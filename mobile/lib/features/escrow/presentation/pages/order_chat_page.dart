import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "13 · Diskusi brief" — chat dengan draf kesepakatan tersemat.
class OrderChatPage extends StatelessWidget {
  const OrderChatPage({super.key, this.order});

  final EscrowOrderModel? order;

  // 1. INTEGRASI: Ambil objek order dari parameter atau navigasi sebelumnya
  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (order != null) return order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  @override
  Widget build(BuildContext context) {
    const demo = DemoData.order;
    final currentOrder = _resolveOrder(context);

    // 2. INTEGRASI: Gunakan data dinamis dari EscrowOrderModel (fallback ke DemoData)
    final providerName = currentOrder?.namaLawanTransaksi ?? demo.provider;
    final serviceTitle = currentOrder?.judulLayanan ?? 'Spanduk 3×1 m';
    final amount = currentOrder?.harga ?? demo.amount;
    final deadlineDays = currentOrder?.detikTersisa != null
        ? (currentOrder!.detikTersisa! / 86400).ceil().clamp(1, 365)
        : demo.deadlineDays;

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        PageHeader(providerName),
        const Text(
          'Online · Diskusi Brief & Tenggat',
          style: TextStyle(
            fontSize: 11,
            height: 15 / 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        InfoBox(
          tone: SakuTone.escrow,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const Text(
                'DRAFT KESEPAKATAN',
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.escrowText,
                ),
              ),
              Text(
                '$serviceTitle · Harga: ${formatRupiah(amount)}\n'
                'Tenggat: $deadlineDays Hari',
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SakuButton(
                key: const Key('chat-agree'),
                label: 'Setujui & Lanjut Pembayaran Escrow',
                onPressed: () {
                  SakuMotion.tick();
                  // 3. INTEGRASI: Teruskan currentOrder ke halaman pembayaran
                  Navigator.of(context).pushNamed(
                    AppRoutes.payment,
                    arguments: currentOrder,
                  );
                },
              ),
            ],
          ),
        ),
        const ChatThread(
          initial: [
            ChatMessage(
              text: 'Halo Mbak Salma, spanduk kateringnya ukuran 3×1 m ya. '
                  'Foto ayam bakarnya sudah saya lampirkan.',
              time: '10:14',
            ),
            ChatMessage(
              text: 'Halo Pak Dimas! Siap, materi sudah saya terima. Saya kerjakan '
                  'format CMYK siap cetak selesai dalam 3 hari dengan tarif Rp 50.000.',
              time: '10:15',
              mine: true,
            ),
            ChatMessage(
              text: 'Baik Mbak, saya setuju. Saya langsung proses pembayarannya ya.',
              time: '10:16',
            ),
          ],
        ),
      ],
    );
  }
}