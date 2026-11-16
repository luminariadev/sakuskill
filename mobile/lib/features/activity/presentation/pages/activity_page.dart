import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "9 · Aktivitas saya" — tab Aktivitas.
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    const order = DemoData.order;
    const barter = DemoData.barter;
    void go(String route) => Navigator.of(context).pushNamed(route);

    final items = <Widget>[
      const PageHeader(
        'Aktivitas Saya',
        subtitle: 'Kelola pesanan jasa, pengerjaan proyek, dan barter di satu tempat.',
      ),
      WalletSummaryCard(onWithdraw: () => go(AppRoutes.wallet)),
      const SectionLabel('PESANAN JASA · ESCROW'),
      SakuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            const StatusStrip('DANA DITAHAN SIMULASI', tone: SakuTone.escrow),
            Text(
              '${order.code}  ·  ${formatRupiah(order.amount)}',
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            PersonRow(
              name: order.clientLabel,
              subtitle: order.title,
              asset: order.clientAsset,
            ),
            const MilestoneSteps(current: 1),
            const StatusStrip(
              'Sisa 4 Jam · Segera kirim hasil kerja',
              tone: SakuTone.warning,
              bordered: true,
            ),
            SakuButton(
              key: const Key('activity-open-project'),
              label: 'Buka Ruang Proyek',
              onPressed: () => go(AppRoutes.workroom),
            ),
            SakuButton(
              label: 'Chat Klien',
              variant: SakuButtonVariant.outline,
              onPressed: () => go(AppRoutes.orderChat),
            ),
          ],
        ),
      ),
      const SectionLabel('SMART BARTER · TUKAR KEAHLIAN'),
      SakuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            PersonRow(
              name: barter.partner,
              subtitle: '${barter.mySkill} ⇄ ${barter.partnerSkill}',
              asset: barter.partnerAsset,
            ),
            Text(
              'Pengerjaan Bersama\nProgress Salma ${(barter.myProgress * 100).round()}% · '
              'Rizkia ${(barter.partnerProgress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                height: 17 / 12,
                color: AppColors.textSecondary,
              ),
            ),
            SakuButton(
              label: 'Buka Ruang Barter',
              variant: SakuButtonVariant.barter,
              onPressed: () => go(AppRoutes.barterWorkroom),
            ),
          ],
        ),
      ),
      const SectionLabel('KELOLA & BANTUAN'),
      _LinkStrip('Jasa Saya · Kelola layanan yang ditawarkan',
          () => go(AppRoutes.myServices)),
      _LinkStrip('Kontrak Barter Saya · Lihat riwayat',
          () => go(AppRoutes.barterHistory)),
      _LinkStrip('Sengketa & Mediasi Transaksi (0 Kasus Aktif)',
          () => go(AppRoutes.complaint)),
      _LinkStrip('Pesanan Masuk · Tinjau permintaan klien',
          () => go(AppRoutes.incomingOrders)),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              FadeSlideIn(index: i, child: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkStrip extends StatelessWidget {
  const _LinkStrip(this.text, this.onTap);

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: StatusStrip(
        '$text  ›',
        background: AppColors.cardSurface,
        textColor: AppColors.textPrimary,
        bordered: true,
        onTap: onTap,
      ),
    );
  }
}

/// Ringkasan dompet gelap (Figma "Wallet summary"): padding 18, saldo 28/800.
/// Angka saldo menghitung naik saat pertama tampil (600 ms) — halus.
class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({super.key, required this.onWithdraw});

  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.deepCanvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          const Text(
            'TOTAL SALDO SAKUSKILL',
            style: TextStyle(
              fontSize: 10,
              height: 14 / 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const CountUpRupiah(
            value: DemoData.balance,
            style: TextStyle(
              fontSize: 28,
              height: 39 / 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'Dana Ditahan di Escrow: ${formatRupiah(DemoData.escrowHeld)}\n'
            '1 Transaksi Berjalan',
            style: const TextStyle(
              fontSize: 12,
              height: 17 / 12,
              color: AppColors.bannerBody,
            ),
          ),
          SakuButton(
            label: 'Tarik Saldo ke Rekening Bank',
            onPressed: onWithdraw,
          ),
        ],
      ),
    );
  }
}

/// Angka rupiah yang menghitung naik dari 0 sekali saat tampil.
class CountUpRupiah extends StatelessWidget {
  const CountUpRupiah({super.key, required this.value, required this.style});

  final num value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (SakuMotion.reduced(context)) {
      return Text(formatRupiah(value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: SakuMotion.curve,
      builder: (_, v, __) => Text(formatRupiah(v), style: style),
    );
  }
}
