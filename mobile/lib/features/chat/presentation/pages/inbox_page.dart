import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../discovery/presentation/widgets/discovery_filters.dart';
import '../../../escrow/data/models/escrow_order_model.dart';

/// Figma "8 · Pesan & diskusi" — tab Chat.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  ConversationKind? _filter;
  List<EscrowOrderModel> _liveOrders = const [];
  bool _loading = false;
  bool _initialized = false;
  Timer? _pollTimer;
  Timer? _clockTimer;
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
    _loadConversations();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadConversations(silent: true),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final repo = AppScope.of(context).escrowRepository;
      final res = await repo.fetchMyOrders();
      if (!mounted) return;
      if (!res.isFallback) {
        setState(() => _liveOrders = res.data);
      }
    } catch (_) {
      // Tetap gunakan fallback demo bila offline
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  List<_InboxItem> _buildItems() {
    final items = <_InboxItem>[];
    final now = DateTime.now();

    // 1. Masukkan semua transaksi Escrow aktif dari backend
    for (final order in _liveOrders) {
      final opponentName = (order.namaLawanTransaksi != null &&
              order.namaLawanTransaksi!.trim().isNotEmpty)
          ? order.namaLawanTransaksi!.trim()
          : 'Lawan Transaksi';
      final roleLabel = order.peranLawanTransaksi ?? 'Transaksi Escrow';

      items.add(
        _InboxItem(
          kind: ConversationKind.escrow,
          name: opponentName,
          subtitle: '$roleLabel · ${order.kodePesanan}',
          contextLabel: '${order.judulLayanan} · ${order.statusPesanan}',
          lastMessage: order.deskripsiBrief?.isNotEmpty == true
              ? order.deskripsiBrief!
              : 'Ketuk untuk membuka ruang diskusi & kesepakatan pesanan.',
          time: order.statusPesanan,
          unread: 0,
          liveOrder: order,
        ),
      );
    }

    // 2. Tambahkan percakapan non-escrow (Smart Barter & Support) atau demo jika belum ada order
    for (final c in DemoData.conversations) {
      if (c.kind == ConversationKind.escrow && _liveOrders.isNotEmpty) {
        continue;
      }
      String dynamicTime;
      if (c.kind == ConversationKind.escrow) {
        dynamicTime = formatRelativeTime(now.subtract(const Duration(minutes: 8)));
      } else if (c.kind == ConversationKind.barter) {
        dynamicTime = formatRelativeTime(now.subtract(const Duration(hours: 3)));
      } else {
        dynamicTime = formatRelativeTime(now.subtract(const Duration(days: 2)));
      }

      items.add(
        _InboxItem(
          kind: c.kind,
          name: c.name,
          subtitle: c.subtitle,
          asset: c.asset,
          contextLabel: c.contextLabel,
          lastMessage: c.lastMessage,
          time: dynamicTime,
          unread: c.unread,
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final all = _buildItems();
    int count(ConversationKind k) => all.where((c) => c.kind == k).length;
    final visible =
        _filter == null ? all : all.where((c) => c.kind == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadConversations,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PageHeader(
                          'Pesan & Diskusi',
                          subtitle: 'Diskusi lancar, kolaborasi lebih dekat.',
                        ),
                        const SizedBox(height: 4),
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
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Segarkan daftar chat',
                    onPressed: _loading ? null : () => _loadConversations(),
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 8,
                  children: [
                    FilterChipPill(
                      label: 'Semua (${all.length})',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    FilterChipPill(
                      key: const Key('inbox-escrow'),
                      label:
                          'Pesanan Escrow (${count(ConversationKind.escrow)})',
                      selected: _filter == ConversationKind.escrow,
                      onTap: () =>
                          setState(() => _filter = ConversationKind.escrow),
                    ),
                    FilterChipPill(
                      label:
                          'Smart Barter (${count(ConversationKind.barter)})',
                      selected: _filter == ConversationKind.barter,
                      onTap: () =>
                          setState(() => _filter = ConversationKind.barter),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading && _liveOrders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                AnimatedSwitcher(
                  duration: SakuMotion.base,
                  child: Column(
                    key: ValueKey('${_filter}_${_liveOrders.length}'),
                    spacing: 16,
                    children: [
                      for (var i = 0; i < visible.length; i++)
                        FadeSlideIn(
                          index: i,
                          child: _ConversationCard(
                            item: visible[i],
                            onReturned: _loadConversations,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxItem {
  const _InboxItem({
    required this.kind,
    required this.name,
    required this.subtitle,
    required this.lastMessage,
    required this.time,
    this.asset,
    this.contextLabel,
    this.unread = 0,
    this.liveOrder,
  });

  final ConversationKind kind;
  final String name;
  final String subtitle;
  final String? asset;
  final String? contextLabel;
  final String lastMessage;
  final String time;
  final int unread;
  final EscrowOrderModel? liveOrder;
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.item,
    required this.onReturned,
  });

  final _InboxItem item;
  final VoidCallback onReturned;

  @override
  Widget build(BuildContext context) {
    final route = switch (item.kind) {
      ConversationKind.escrow => AppRoutes.orderChat,
      ConversationKind.barter => AppRoutes.barterChat,
      ConversationKind.support => AppRoutes.complaint,
    };

    return SakuCard(
      padding: const EdgeInsets.all(14),
      onTap: () async {
        await Navigator.of(context).pushNamed(
          route,
          arguments: item.liveOrder,
        );
        onReturned();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          PersonRow(
            name: item.name,
            subtitle: item.subtitle,
            asset: item.asset,
            leading: item.kind == ConversationKind.support
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: SakuIcon(
                      SakuIcons.shield,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          if (item.contextLabel != null)
            StatusStrip(
              item.contextLabel!,
              tone: item.kind == ConversationKind.barter
                  ? SakuTone.barter
                  : SakuTone.escrow,
            ),
          Text(
            item.lastMessage,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            item.unread > 0
                ? '${item.time}   ● ${item.unread} pesan baru'
                : item.time,
            style: TextStyle(
              fontSize: 10,
              height: 14 / 10,
              fontWeight: FontWeight.w600,
              color:
                  item.unread > 0 ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}