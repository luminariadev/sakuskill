import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../../barter/data/models/barter_model.dart';
import '../../../discovery/presentation/widgets/discovery_filters.dart';
import '../../../escrow/data/models/escrow_order_model.dart';

/// Figma "8 · Pesan & diskusi" — tab Chat.
/// Mengelompokkan pesan per lawan transaksi (1 nama = 1 entri inbox) lengkap
/// dengan gelembung jumlah pesan di sisi kanan, dan tanpa riwayat palsu pada
/// akun baru di mode live.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  ConversationKind? _filter;
  List<EscrowOrderModel> _liveOrders = const [];
  List<BarterAgreementModel> _liveBarters = const [];
  final Map<String, int> _messageCountByOrder = {};
  final Map<String, String> _lastMessageByOrder = {};
  final Map<String, int> _messageCountByBarter = {};
  final Map<String, String> _lastMessageByBarter = {};
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
    if (AppConfig.useMockData) return;
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    if (!silent && mounted) setState(() => _loading = true);
    try {
      final deps = AppScope.of(context);
      final repo = deps.escrowRepository;
      final results = await Future.wait([
        repo.fetchMyOrders(peran: 'pelanggan'),
        repo.fetchMyOrders(peran: 'penyedia'),
        deps.barterDataSource
            .listMyBarters()
            .catchError((_) => const <BarterAgreementModel>[]),
      ]);

      final custRes = results[0] as dynamic;
      final provRes = results[1] as dynamic;
      final barters = results[2] as List<BarterAgreementModel>;
      if (!mounted) return;

      if (!custRes.isFallback && !provRes.isFallback) {
        final seen = <String>{};
        final combined = <EscrowOrderModel>[];
        for (final order in [...custRes.data, ...provRes.data]) {
          if (seen.add(order.orderId)) {
            combined.add(order);
          }
        }

        // Ambil jumlah pesan & cuplikan pesan terbaru untuk tiap order & barter aktif
        final msgEntries = await Future.wait(
          combined.take(25).map((o) async {
            try {
              final msgRes = await repo.fetchOrderMessages(o.orderId);
              if (!msgRes.isFallback) {
                return MapEntry(o.orderId, msgRes.data);
              }
            } catch (_) {}
            return MapEntry(o.orderId, const <Map<String, dynamic>>[]);
          }),
        );

        final barterMsgEntries = await Future.wait(
          barters.take(15).map((b) async {
            try {
              final msgs = await deps.barterDataSource.listMessages(b.id);
              return MapEntry(b.id, msgs);
            } catch (_) {}
            return MapEntry(b.id, const <Map<String, dynamic>>[]);
          }),
        );

        if (!mounted) return;
        setState(() {
          _liveOrders = combined;
          _liveBarters = barters;
          for (final entry in msgEntries) {
            _messageCountByOrder[entry.key] = entry.value.length;
            if (entry.value.isNotEmpty) {
              final lastText =
                  (entry.value.last['isi_pesan'] ?? '').toString().trim();
              if (lastText.isNotEmpty) {
                _lastMessageByOrder[entry.key] = lastText;
              }
            }
          }
          for (final entry in barterMsgEntries) {
            _messageCountByBarter[entry.key] = entry.value.length;
            if (entry.value.isNotEmpty) {
              final lastText =
                  (entry.value.last['isi_pesan'] ?? '').toString().trim();
              if (lastText.isNotEmpty) {
                _lastMessageByBarter[entry.key] = lastText;
              }
            }
          }
        });
      }
    } catch (_) {
      // Pertahankan state terakhir jika offline
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  String _opponentKeyFor(EscrowOrderModel order) {
    final myId = AuthSession.instance.userId?.trim();
    if (myId != null && myId.isNotEmpty) {
      if (order.pelangganId == myId &&
          (order.penyediaId?.trim().isNotEmpty ?? false)) {
        return order.penyediaId!.trim();
      }
      if (order.penyediaId == myId &&
          (order.pelangganId?.trim().isNotEmpty ?? false)) {
        return order.pelangganId!.trim();
      }
    }
    final nameKey = (order.namaLawanTransaksi ?? '').trim().toLowerCase();
    return nameKey.isNotEmpty ? nameKey : order.orderId;
  }

  List<_InboxItem> _buildItems() {
    final items = <_InboxItem>[];
    final now = DateTime.now();

    // 1. Kelompokkan semua order real berdasarkan lawan transaksi (1 nama = 1 baris)
    final grouped = <String, List<EscrowOrderModel>>{};
    for (final order in _liveOrders) {
      final key = _opponentKeyFor(order);
      grouped.putIfAbsent(key, () => []).add(order);
    }

    for (final orders in grouped.values) {
      final latest = orders.first;
      final opponentName = (latest.namaLawanTransaksi != null &&
              latest.namaLawanTransaksi!.trim().isNotEmpty)
          ? latest.namaLawanTransaksi!.trim()
          : 'Pengguna SakuSkill';
      final roleLabel = latest.peranLawanTransaksi ?? 'Transaksi Escrow';

      var totalMessages = 0;
      for (final o in orders) {
        totalMessages += _messageCountByOrder[o.orderId] ?? 0;
      }

      final latestSnippet = _lastMessageByOrder[latest.orderId] ??
          (latest.deskripsiBrief?.isNotEmpty == true
              ? latest.deskripsiBrief!
              : 'Ketuk untuk membuka ruang diskusi & kesepakatan pesanan.');

      items.add(
        _InboxItem(
          kind: ConversationKind.escrow,
          name: opponentName,
          subtitle: orders.length > 1
              ? '${orders.length} Transaksi · ${latest.kodePesanan}'
              : '$roleLabel · ${latest.kodePesanan}',
          contextLabel: orders.length > 1
              ? '${latest.judulLayanan} (+${orders.length - 1} lainnya)'
              : '${latest.judulLayanan} · ${latest.statusPesanan}',
          lastMessage: latestSnippet,
          time: latest.statusPesanan,
          messageCount: totalMessages,
          orders: orders,
        ),
      );
    }

    // 1b. Kontrak Smart Barter real
    final myId = (AuthSession.instance.userId ?? '').trim().toLowerCase();
    for (final b in _liveBarters) {
      final isInitiator = myId == b.pengajuId.trim().toLowerCase();
      final partner = isInitiator ? b.namaPenerima : b.namaPengaju;
      final partnerName =
          partner.trim().isNotEmpty ? partner.trim() : 'Mitra Barter';
      final shortId =
          b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase();
      final count = _messageCountByBarter[b.id] ?? 0;
      final lastMsg = _lastMessageByBarter[b.id] ??
          'Ketuk untuk membuka ruang diskusi Smart Barter.';

      items.add(
        _InboxItem(
          kind: ConversationKind.barter,
          name: partnerName,
          subtitle: 'Smart Barter · #BTR-$shortId',
          contextLabel:
              '${b.deskripsiJasaPengaju} ⇄ ${b.deskripsiJasaPenerima}',
          lastMessage: lastMsg,
          time: b.status,
          messageCount: count,
          barter: b,
        ),
      );
    }

    // 2. Demo data HANYA ditampilkan pada mode mock/unit test (`AppConfig.useMockData`),
    // tidak pernah ditampilkan kepada akun nyata pada mode live.
    if (AppConfig.useMockData) {
      for (final c in DemoData.conversations) {
        if (c.kind == ConversationKind.escrow && _liveOrders.isNotEmpty) {
          continue;
        }
        String dynamicTime;
        if (c.kind == ConversationKind.escrow) {
          dynamicTime =
              formatRelativeTime(now.subtract(const Duration(minutes: 8)));
        } else if (c.kind == ConversationKind.barter) {
          dynamicTime =
              formatRelativeTime(now.subtract(const Duration(hours: 3)));
        } else {
          dynamicTime =
              formatRelativeTime(now.subtract(const Duration(days: 2)));
        }

        items.add(
          _InboxItem(
            kind: c.kind,
            name: c.name,
            subtitle: c.subtitle,
            contextLabel: c.contextLabel,
            lastMessage: c.lastMessage,
            time: dynamicTime,
            messageCount: c.unread,
          ),
        );
      }
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 116),
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
              else if (visible.isEmpty)
                const SakuCard(
                  child: Text(
                    'Belum ada percakapan. Mulai diskusi langsung dari halaman Detail Layanan atau ajukan pesanan terlebih dahulu.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                AnimatedSwitcher(
                  duration: SakuMotion.base,
                  child: Column(
                    key: ValueKey('${_filter}_${_liveOrders.length}_${all.length}'),
                    spacing: 14,
                    children: [
                      for (var i = 0; i < visible.length; i++)
                        FadeSlideIn(
                          index: i,
                          child: _ConversationCard(
                            item: visible[i],
                            messageCountByOrder: _messageCountByOrder,
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
    this.contextLabel,
    this.messageCount = 0,
    this.orders = const [],
    this.barter,
  });

  final ConversationKind kind;
  final String name;
  final String subtitle;
  final String? contextLabel;
  final String lastMessage;
  final String time;
  final int messageCount;
  final List<EscrowOrderModel> orders;
  final BarterAgreementModel? barter;
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.item,
    required this.messageCountByOrder,
    required this.onReturned,
  });

  final _InboxItem item;
  final Map<String, int> messageCountByOrder;
  final VoidCallback onReturned;

  Future<void> _openConversation(BuildContext context) async {
    if (item.orders.length > 1) {
      final selectedOrder = await showSakuSheet<EscrowOrderModel>(
        context,
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(
              'Pilih Transaksi dengan ${item.name}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            for (final o in item.orders)
              SakuCard(
                padding: const EdgeInsets.all(12),
                onTap: () => Navigator.of(ctx).pop(o),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3,
                        children: [
                          Text(
                            o.judulLayanan,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${o.kodePesanan} · ${o.statusPesanan}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((messageCountByOrder[o.orderId] ?? 0) > 0)
                      _NumericBubble(count: messageCountByOrder[o.orderId]!),
                  ],
                ),
              ),
          ],
        ),
      );

      if (selectedOrder != null && context.mounted) {
        await Navigator.of(context).pushNamed(
          AppRoutes.orderChat,
          arguments: selectedOrder,
        );
        onReturned();
      }
      return;
    }

    final route = switch (item.kind) {
      ConversationKind.escrow => AppRoutes.orderChat,
      ConversationKind.barter => AppRoutes.barterChat,
      ConversationKind.support => AppRoutes.helpCenter,
    };

    final args = switch (item.kind) {
      ConversationKind.escrow =>
        item.orders.isNotEmpty ? item.orders.first : null,
      ConversationKind.barter => item.barter,
      ConversationKind.support => null,
    };

    await Navigator.of(context).pushNamed(
      route,
      arguments: args,
    );
    onReturned();
  }

  @override
  Widget build(BuildContext context) {
    final isBarter = item.kind == ConversationKind.barter;
    final tagBg = isBarter ? AppColors.barterSurface : AppColors.escrowSurface;
    final tagFg = isBarter ? AppColors.barterText : AppColors.escrowText;

    return SakuCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _openConversation(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          PersonRow(
            name: item.name,
            subtitle: item.subtitle,
            leading: item.kind == ConversationKind.support
                ? const ClayIconBadge(
                    size: 40,
                    radius: 12,
                    tint: AppColors.primary,
                    child: SakuIcon(
                      SakuIcons.shield,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  )
                : InitialsAvatar(name: item.name, size: 42),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 5,
              children: [
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 14 / 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTypography.tabular,
                    color: item.messageCount > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                if (item.messageCount > 0)
                  _NumericBubble(count: item.messageCount),
              ],
            ),
          ),
          if (item.contextLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: tagBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.contextLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w700,
                  color: tagFg,
                ),
              ),
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
        ],
      ),
    );
  }
}

class _NumericBubble extends StatelessWidget {
  const _NumericBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: AppRadius.pillBr,
        boxShadow: AppShadows.flat,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          height: 13 / 11,
          fontWeight: FontWeight.w800,
          fontFeatures: AppTypography.tabular,
          color: Colors.white,
        ),
      ),
    );
  }
}
