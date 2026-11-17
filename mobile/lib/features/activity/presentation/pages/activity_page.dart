import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../../escrow/data/datasources/escrow_remote_data_source.dart';
import '../../../escrow/data/models/escrow_order_model.dart';
import '../../../escrow/presentation/pages/incoming_order_page.dart';

/// Figma "9 · Aktivitas saya" — tab Aktivitas.
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _loadingOrders = false;
  List<EscrowOrderModel> _customerOrders = const [];
  List<EscrowOrderModel> _providerOrders = const [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    setState(() => _loadingOrders = true);
    final remote = EscrowRemoteDataSource(
      tokenProvider: () async => AuthSession.instance.accessToken,
    );

    try {
      final results = await Future.wait([
        remote.fetchMyOrders(peran: 'pelanggan'),
        remote.fetchMyOrders(peran: 'penyedia'),
      ]);
      if (!mounted) return;
      setState(() {
        _customerOrders = results[0];
        _providerOrders = results[1];
      });
    } catch (_) {
      // Tetap pertahankan state terakhir / fallback demo jika server belum merespons
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  void _openOrder(EscrowOrderModel order, {required bool asProvider}) {
    final status = order.statusKode.toLowerCase();
    final isPrePayment =
        status == 'submitted' ||
        status == 'diajukan' ||
        status == 'accepted' ||
        status == 'disepakati';

    if (isPrePayment) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(builder: (_) => IncomingOrderPage(order: order)),
          )
          .then((_) => _loadOrders());
    } else {
      Navigator.of(context)
          .pushNamed(
            asProvider ? AppRoutes.workroom : AppRoutes.tracking,
            arguments: order,
          )
          .then((_) => _loadOrders());
    }
  }

  @override
  Widget build(BuildContext context) {
    const order = DemoData.order;
    const barter = DemoData.barter;
    void go(String route) => Navigator.of(context).pushNamed(route);

    final hasLiveOrders =
        _customerOrders.isNotEmpty || _providerOrders.isNotEmpty;

    final items = <Widget>[
      const PageHeader(
        'Aktivitas Saya',
        subtitle: 'Kelola pesanan jasa, pengerjaan proyek, dan barter di satu tempat.',
      ),
      WalletSummaryCard(onWithdraw: () => go(AppRoutes.wallet)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SectionLabel('PESANAN JASA · ESCROW'),
          GestureDetector(
            onTap: _loadingOrders ? null : _loadOrders,
            child: Text(
              _loadingOrders ? 'Memuat...' : 'Segarkan',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      if (hasLiveOrders) ...[
        for (final item in _providerOrders)
          _LiveOrderCard(
            order: item,
            roleBadge: 'PESANAN MASUK · PENYEDIA JASA',
            actionLabel: _actionTextFor(item, asProvider: true),
            onPrimaryTap: () => _openOrder(item, asProvider: true),
            onChatTap: () =>
                Navigator.of(context)
                    .pushNamed(AppRoutes.orderChat, arguments: item),
          ),
        for (final item in _customerOrders)
          _LiveOrderCard(
            order: item,
            roleBadge: 'PESANAN SAYA · PELANGGAN',
            actionLabel: _actionTextFor(item, asProvider: false),
            onPrimaryTap: () => _openOrder(item, asProvider: false),
            onChatTap: () =>
                Navigator.of(context)
                    .pushNamed(AppRoutes.orderChat, arguments: item),
          ),
      ] else
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
      _LinkStrip(
        'Jasa Saya · Kelola layanan yang ditawarkan',
        () => go(AppRoutes.myServices),
      ),
      _LinkStrip(
        'Kontrak Barter Saya · Lihat riwayat',
        () => go(AppRoutes.barterHistory),
      ),
      _LinkStrip(
        'Sengketa & Mediasi Transaksi (0 Kasus Aktif)',
        () => go(AppRoutes.complaint),
      ),
      _LinkStrip(
        _providerOrders.isNotEmpty
            ? 'Pesanan Masuk (${_providerOrders.length}) · Tinjau permintaan klien'
            : 'Pesanan Masuk · Tinjau permintaan klien',
        () {
          if (_providerOrders.isNotEmpty) {
            _openOrder(_providerOrders.first, asProvider: true);
          } else {
            go(AppRoutes.incomingOrders);
          }
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadOrders,
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
      ),
    );
  }

  String _actionTextFor(EscrowOrderModel order, {required bool asProvider}) {
    final s = order.statusKode.toLowerCase();
    if (s == 'submitted' || s == 'diajukan') {
      return asProvider ? 'Tinjau & Terima Pesanan' : 'Lihat Status Pengajuan';
    }
    if (s == 'accepted' || s == 'disepakati') {
      return asProvider
          ? 'Lihat Detail (Menunggu Bayar)'
          : 'Bayar Sekarang (Escrow)';
    }
    return asProvider ? 'Buka Ruang Proyek' : 'Pantau Progres Pesanan';
  }
}

class _LiveOrderCard extends StatelessWidget {
  const _LiveOrderCard({
    required this.order,
    required this.roleBadge,
    required this.actionLabel,
    required this.onPrimaryTap,
    required this.onChatTap,
  });

  final EscrowOrderModel order;
  final String roleBadge;
  final String actionLabel;
  final VoidCallback onPrimaryTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return SakuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          StatusStrip(
            '$roleBadge · ${order.statusPesanan.toUpperCase()}',
            tone: SakuTone.escrow,
          ),
          Text(
            '${order.kodePesanan}  ·  ${formatRupiah(order.harga)}',
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          PersonRow(
            name: order.namaLawanTransaksi ?? 'Pengguna SakuSkill',
            subtitle: order.judulLayanan,
            asset: DemoData.order.clientAsset,
          ),
          SakuButton(label: actionLabel, onPressed: onPrimaryTap),
          SakuButton(
            label: 'Buka Chat Transaksi',
            variant: SakuButtonVariant.outline,
            onPressed: onChatTap,
          ),
        ],
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
