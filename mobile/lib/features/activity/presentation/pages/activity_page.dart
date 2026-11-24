import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/state/account_finance_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../../barter/data/models/barter_model.dart';
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
  bool _initialized = false;
  List<EscrowOrderModel> _customerOrders = const [];
  List<EscrowOrderModel> _providerOrders = const [];
  List<BarterAgreementModel> _liveBarters = const [];
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
    _loadOrders();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      _loadOrders(silent: true);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (AppConfig.useMockData) return;
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    if (!silent) setState(() => _loadingOrders = true);
    final deps = AppScope.of(context);

    try {
      final results = await Future.wait([
        deps.escrowRepository.fetchMyOrders(peran: 'pelanggan'),
        deps.escrowRepository.fetchMyOrders(peran: 'penyedia'),
        deps.barterDataSource
            .listMyBarters()
            .catchError((_) => const <BarterAgreementModel>[]),
      ]);

      final custRes = results[0] as dynamic;
      final provRes = results[1] as dynamic;
      final barters = results[2] as List<BarterAgreementModel>;
      if (!mounted) return;

      if (!custRes.isFallback && !provRes.isFallback) {
        final custList = custRes.data as List<EscrowOrderModel>;
        final provList = provRes.data as List<EscrowOrderModel>;

        AccountFinanceStore.instance.syncFromOrders(
          providerOrders: provList,
          customerOrders: custList,
          userId: AuthSession.instance.userId,
        );

        setState(() {
          _customerOrders = custList;
          _providerOrders = provList;
          _liveBarters = barters;
        });
      }
    } catch (_) {
      // Pertahankan state terakhir jika server belum merespons
    } finally {
      if (!silent && mounted) setState(() => _loadingOrders = false);
    }
  }

  void _openOrder(EscrowOrderModel order, {required bool asProvider}) {
    final status = order.statusKode.toLowerCase();
    final isPrePayment = status == 'requested' ||
        status == 'submitted' ||
        status == 'diajukan' ||
        status == 'negotiating' ||
        status == 'accepted' ||
        status == 'disepakati';

    if (isPrePayment) {
      if (!asProvider && (status == 'accepted' || status == 'disepakati')) {
        Navigator.of(context)
            .pushNamed(AppRoutes.payment, arguments: order)
            .then((_) => _loadOrders());
        return;
      }
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => IncomingOrderPage(
                order: order,
                isProviderView: asProvider,
              ),
            ),
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
    void go(String route, {Object? arguments}) =>
        Navigator.of(context).pushNamed(route, arguments: arguments);

    final hasLiveOrders =
        _customerOrders.isNotEmpty || _providerOrders.isNotEmpty;

    final items = <Widget>[
      const PageHeader(
        'Aktivitas Saya',
        subtitle:
            'Kelola pesanan jasa, pengerjaan proyek, dan barter di satu tempat.',
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
      ListenableBuilder(
        listenable: AccountFinanceStore.instance,
        builder: (context, _) {
          final finance = AccountFinanceStore.instance;
          return WalletSummaryCard(
            balance: finance.availableBalance,
            escrowHeld: finance.escrowHeld,
            activeTransactions: finance.activeOrderCount,
            onWithdraw: () => go(AppRoutes.wallet),
          );
        },
      ),
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
            asProvider: true,
            roleBadge: 'PESANAN MASUK · PENYEDIA JASA',
            actionLabel: _actionTextFor(item, asProvider: true),
            onPrimaryTap: () => _openOrder(item, asProvider: true),
            onChatTap: () => go(AppRoutes.orderChat, arguments: item),
          ),
        for (final item in _customerOrders)
          _LiveOrderCard(
            order: item,
            asProvider: false,
            roleBadge: 'PESANAN SAYA · PELANGGAN',
            actionLabel: _actionTextFor(item, asProvider: false),
            onPrimaryTap: () => _openOrder(item, asProvider: false),
            onChatTap: () => go(AppRoutes.orderChat, arguments: item),
          ),
      ] else
        const SakuCard(
          child: Text(
            'Belum ada pesanan jasa atau transaksi escrow aktif saat ini.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      const SectionLabel('SMART BARTER · TUKAR KEAHLIAN'),
      if (!AppConfig.useMockData) ...[
        if (_liveBarters.isEmpty)
          SakuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                const Text(
                  'Belum ada proyek Smart Barter aktif.\nAjukan pertukaran keahlian Rp 0 langsung dari halaman layanan yang mendukung Barter.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SakuButton(
                  label: 'Ajukan Penawaran Barter',
                  variant: SakuButtonVariant.barter,
                  onPressed: () => go(AppRoutes.proposeBarter),
                ),
              ],
            ),
          )
        else
          for (final barter in _liveBarters)
            _LiveBarterCard(
              barter: barter,
              onOpen: () => go(AppRoutes.barterWorkroom, arguments: barter),
            ),
      ] else
        _DemoBarterPreviewCard(
          onOpen: () => go(AppRoutes.barterWorkroom),
        ),
      const SectionLabel('KELOLA & BANTUAN'),
      SakuCard(
        radius: 22,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              _GroupedMenuItem(
                icon: Icons.design_services_outlined,
                tint: AppColors.primary,
                title: 'Jasa Saya',
                subtitle: 'Kelola layanan yang ditawarkan',
                onTap: () => go(AppRoutes.myServices),
              ),
              const Divider(height: 1, indent: 66),
              _GroupedMenuItem(
                icon: Icons.swap_horiz_rounded,
                tint: AppColors.barter,
                title: 'Kontrak Barter Saya',
                subtitle: 'Lihat riwayat & ketentuan barter',
                onTap: () => go(AppRoutes.barterHistory),
              ),
              const Divider(height: 1, indent: 66),
              _GroupedMenuItem(
                icon: Icons.support_agent_rounded,
                tint: AppColors.escrow,
                title: 'Pusat Bantuan & Panduan',
                subtitle: 'FAQ pengguna & status laporan komplain',
                onTap: () => go(AppRoutes.helpCenter),
              ),
              const Divider(height: 1, indent: 66),
              _GroupedMenuItem(
                icon: Icons.inbox_outlined,
                tint: AppColors.warningText,
                title: _providerOrders.isNotEmpty
                    ? 'Pesanan Masuk (${_providerOrders.length})'
                    : 'Pesanan Masuk',
                subtitle: 'Tinjau permintaan klien',
                onTap: () {
                  if (_providerOrders.isNotEmpty) {
                    _openOrder(_providerOrders.first, asProvider: true);
                  } else {
                    go(AppRoutes.incomingOrders);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 116),
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
    if (s == 'requested' ||
        s == 'submitted' ||
        s == 'diajukan' ||
        s == 'negotiating') {
      return asProvider ? 'Tinjau & Terima Pesanan' : 'Lihat Status Pengajuan';
    }
    if (s == 'accepted' || s == 'disepakati') {
      return asProvider
          ? 'Lihat Detail (Menunggu Bayar)'
          : 'Bayar Sekarang (Escrow)';
    }
    if (s == 'cancelled' || s == 'rejected') {
      return 'Lihat Riwayat Pesanan';
    }
    return asProvider ? 'Buka Ruang Proyek' : 'Pantau Progres Pesanan';
  }
}

class _LiveBarterCard extends StatelessWidget {
  const _LiveBarterCard({
    required this.barter,
    required this.onOpen,
  });

  final BarterAgreementModel barter;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final myId = AuthSession.instance.userId;
    final partnerName = myId == barter.pengajuId
        ? barter.namaPenerima
        : barter.namaPengaju;

    return SakuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          StatusStrip(
            'SMART BARTER · ${barter.status.toUpperCase()}',
            tone: SakuTone.barter,
          ),
          PersonRow(
            name: partnerName.isEmpty ? 'Mitra Barter' : partnerName,
            subtitle:
                '${barter.deskripsiJasaPengaju} ⇄ ${barter.deskripsiJasaPenerima}',
            leading: InitialsAvatar(
              name: partnerName.isEmpty ? 'Mitra' : partnerName,
              size: 40,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MilestoneTag(
                label: 'Setuju 2 Pihak',
                done: barter.setujuPengaju && barter.setujuPenerima,
              ),
              _MilestoneTag(
                label: 'Pengaju Selesai',
                done: barter.konfirmasiSelesaiPengaju,
              ),
              _MilestoneTag(
                label: 'Penerima Selesai',
                done: barter.konfirmasiSelesaiPenerima,
              ),
            ],
          ),
          SakuButton(
            label: 'Buka Ruang Barter',
            variant: SakuButtonVariant.barter,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _DemoBarterPreviewCard extends StatelessWidget {
  const _DemoBarterPreviewCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const barter = DemoData.barter;
    return SakuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          PersonRow(
            name: barter.partner,
            subtitle: '${barter.mySkill} ⇄ ${barter.partnerSkill}',
            leading: InitialsAvatar(name: barter.partner, size: 40),
          ),
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MilestoneTag(label: 'Ketentuan Disepakati', done: true),
              _MilestoneTag(label: 'Pengerjaan Bersama', done: true),
              _MilestoneTag(label: 'Konfirmasi 2 Pihak', done: false),
            ],
          ),
          SakuButton(
            label: 'Buka Ruang Barter',
            variant: SakuButtonVariant.barter,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _MilestoneTag extends StatelessWidget {
  const _MilestoneTag({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final bg = done ? AppColors.barterSurface : AppColors.surfaceSubtle;
    final fg = done ? AppColors.barterText : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillBr,
      ),
      child: Text(
        '${done ? '✓' : '○'} $label',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _GroupedMenuItem extends StatelessWidget {
  const _GroupedMenuItem({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              ClayIconBadge(
                size: 38,
                radius: 12,
                tint: tint,
                icon: icon,
                iconSize: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  const _LiveOrderCard({
    required this.order,
    required this.asProvider,
    required this.roleBadge,
    required this.actionLabel,
    required this.onPrimaryTap,
    required this.onChatTap,
  });

  final EscrowOrderModel order;
  final bool asProvider;
  final String roleBadge;
  final String actionLabel;
  final VoidCallback onPrimaryTap;
  final VoidCallback onChatTap;

  int _milestoneStep() {
    switch (order.statusKode.toLowerCase()) {
      case 'in_progress':
        return 1;
      case 'completion_requested':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  String? _deadlineNotice() {
    final s = order.statusKode.toLowerCase();
    if (s == 'completed' || s == 'cancelled' || s == 'rejected') return null;

    if (s == 'in_progress') {
      final secs = order.detikTersisa;
      if (secs != null && secs > 0) {
        final hours = (secs / 3600).ceil();
        final timeLabel = hours >= 24
            ? 'Sisa ${(hours / 24).ceil()} Hari'
            : 'Sisa $hours Jam';
        return asProvider
            ? '$timeLabel · Segera kirim hasil kerja'
            : '$timeLabel · Proyek sedang dikerjakan penyedia';
      }
      return asProvider
          ? 'Proyek berjalan · Segera selesaikan sesuai tenggat'
          : 'Proyek sedang dikerjakan penyedia';
    }

    if (s == 'completion_requested') {
      return asProvider
          ? 'Hasil terkirim · Menunggu konfirmasi pelanggan'
          : 'Hasil kerja siap diperiksa · Konfirmasi selesai';
    }

    if (s == 'accepted' || s == 'disepakati') {
      return asProvider
          ? 'Menunggu pelanggan menyelesaikan pembayaran Escrow'
          : 'Kesepakatan disetujui · Lanjutkan pembayaran Escrow';
    }

    return asProvider
        ? 'Pesanan baru masuk · Tinjau & terima brief klien'
        : 'Menunggu konfirmasi & kesepakatan penyedia jasa';
  }

  @override
  Widget build(BuildContext context) {
    final s = order.statusKode.toLowerCase();
    final isTerminated = s == 'cancelled' || s == 'rejected';
    final notice = _deadlineNotice();
    final name = order.namaLawanTransaksi ?? 'Pengguna SakuSkill';

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
            name: name,
            subtitle: order.judulLayanan,
            leading: InitialsAvatar(name: name, size: 40),
          ),
          if (!isTerminated) MilestoneSteps(current: _milestoneStep()),
          if (notice != null)
            StatusStrip(
              notice,
              tone: SakuTone.warning,
              bordered: true,
            ),
          SakuButton(label: actionLabel, onPressed: onPrimaryTap),
          SakuButton(
            label: asProvider ? 'Chat Klien' : 'Buka Chat Transaksi',
            variant: SakuButtonVariant.outline,
            onPressed: onChatTap,
          ),
        ],
      ),
    );
  }
}

/// Ringkasan dompet gelap (Figma "Wallet summary"): tersinkron penuh.
class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    super.key,
    required this.onWithdraw,
    required this.balance,
    required this.escrowHeld,
    required this.activeTransactions,
  });

  final VoidCallback onWithdraw;
  final num balance;
  final num escrowHeld;
  final int activeTransactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepCanvas, AppColors.deepForestAccent],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: AppShadows.clayElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL SALDO SAKUSKILL',
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: AppRadius.pillBr,
                ),
                child: const Text(
                  'TERVERIFIKASI',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          CountUpRupiah(
            value: balance,
            style: const TextStyle(
              fontSize: 28,
              height: 36 / 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              fontFeatures: AppTypography.tabular,
              color: Colors.white,
            ),
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      const Text(
                        'Dana Ditahan Escrow',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        formatRupiah(escrowHeld),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTypography.tabular,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      const Text(
                        'Transaksi Berjalan',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '$activeTransactions Order Aktif',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTypography.tabular,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
