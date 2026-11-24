import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../../../activity/presentation/pages/activity_page.dart';

/// Figma "25 · Dompet SakuSkill" (simulasi — tidak memindahkan uang).
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  /// Total saldo pendapatan di layar dompet (Figma: Rp 340.000).
  static const num income = 340000;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int? _destination;

  @override
  Widget build(BuildContext context) {
    const subtitle = TextStyle(
      fontSize: 17,
      height: 24 / 17,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Dompet SakuSkill'),
        const Text(
          'Saldo & penarikan dana',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.deepCanvas,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const Text(
                'TOTAL SALDO PENDAPATAN ANDA',
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const CountUpRupiah(
                value: WalletPage.income,
                style: TextStyle(
                  fontSize: 32,
                  height: 45 / 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Dana Ditahan di Escrow: ${formatRupiah(DemoData.escrowHeld)}\n'
                '1 Transaksi Berjalan',
                style: const TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.bannerBody),
              ),
              SakuButton(
                key: const Key('wallet-withdraw'),
                label: 'Tarik Saldo ke Rekening / E-Wallet',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_destination == null
                        ? 'Pilih tujuan penarikan terlebih dahulu.'
                        : 'Simulasi penarikan diproses. Tidak ada dana sungguhan '
                            'yang dipindahkan.'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Text('Pilihan Tujuan Penarikan', style: subtitle),
        SelectableOption(
          title: 'Transfer Bank',
          subtitle: 'BCA  ·  Bank Mandiri (131001...)  ·  BRI',
          selected: _destination == 0,
          onTap: () => setState(() => _destination = 0),
        ),
        SelectableOption(
          title: 'E-Wallet',
          subtitle: 'GoPay  ·  DANA  ·  OVO',
          selected: _destination == 1,
          onTap: () => setState(() => _destination = 1),
        ),
        const Text('Riwayat Mutasi Dompet', style: subtitle),
        const SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              _LedgerRow(
                title: 'Dana Escrow Masuk',
                amount: '+Rp 50.000',
                note: 'Spanduk Berkah Cibiru · Hari ini',
                incoming: true,
              ),
              _LedgerRow(
                title: 'Penarikan Dana',
                amount: '-Rp 100.000',
                note: 'Transfer Rekening Mandiri · 8 Nov 2026',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.title,
    required this.amount,
    required this.note,
    this.incoming = false,
  });

  final String title;
  final String amount;
  final String note;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      color: incoming ? AppColors.primary : AppColors.textPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        Row(children: [Expanded(child: Text(title, style: style)), Text(amount, style: style)]),
        Text(note, style: const TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
