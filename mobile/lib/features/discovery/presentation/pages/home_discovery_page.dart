import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/navigation/main_shell.dart';
import '../../../../core/state/account_finance_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/data/auth_session.dart';
import '../../domain/entities/service_listing.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/discovery_scope.dart';
import '../widgets/discovery_filters.dart';
import '../widgets/home_sections.dart';
import '../widgets/market_card.dart';
import '../widgets/service_card.dart';

/// Figma "5 · Beranda marketplace".
class HomeDiscoveryPage extends StatefulWidget {
  const HomeDiscoveryPage({super.key});

  @override
  State<HomeDiscoveryPage> createState() => _HomeDiscoveryPageState();
}

class _HomeDiscoveryPageState extends State<HomeDiscoveryPage> {
  static const String _fallbackUserName = 'Pengguna SakuSkill';
  bool _syncedFinance = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_syncedFinance) {
      _syncedFinance = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AccountFinanceStore.instance.refreshLive(
          escrowRepository: AppScope.of(context).escrowRepository,
        );
        _hydrateProfilePhoto();
      });
    }
  }

  Future<void> _hydrateProfilePhoto() async {
    if (AppConfig.useMockData) return;
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;
    if (AuthSession.instance.photoUrl != null &&
        AuthSession.instance.photoUrl!.isNotEmpty) {
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.networkTimeout);
      if (!mounted || res.statusCode < 200 || res.statusCode >= 300) return;
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      final data = json is Map<String, dynamic> ? json['data'] : null;
      if (data is Map<String, dynamic>) {
        final photo =
            (data['foto_profil'] ?? data['foto_url'] ?? '').toString().trim();
        if (photo.isNotEmpty) {
          AuthSession.instance.updatePhotoUrl(photo);
        }
      }
    } catch (_) {}
  }

  Future<void> _handleRefresh(DiscoveryController controller) async {
    await Future.wait([
      controller.refresh(),
      AccountFinanceStore.instance.refreshLive(
        escrowRepository: AppScope.of(context).escrowRepository,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final controller = DiscoveryScope.of(context);
    final activeUserName = AuthSession.instance.userName ?? _fallbackUserName;

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _handleRefresh(controller),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                sliver: SliverList.list(
                  children: [
                    ListenableBuilder(
                      listenable: AccountFinanceStore.instance,
                      builder: (context, _) => MarketplaceHeader(
                        userName: activeUserName,
                        balance: AccountFinanceStore.instance.availableBalance,
                        onBalanceTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.wallet),
                        onAvatarTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.profile),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SearchPill(
                      hint: 'Cari jasa desain, video, les, servis...',
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.search,
                        arguments: controller.filter.copyWith(query: ''),
                      ),
                      onMapTap: () => MainShell.goTo(context, MainTab.explore),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: HomeFilterChips(controller: controller)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                sliver: SliverList.list(
                  children: [
                    const EscrowSecurityBanner(),
                    const SizedBox(height: 16),
                    const SectionTitle('Temukan keahlian di sekitarmu'),
                    if (controller.isFallback) ...[
                      const SizedBox(height: 8),
                      const OfflineDataBanner(),
                    ],
                  ],
                ),
              ),
              _FeedSliver(controller: controller),
              const SliverToBoxAdapter(child: SizedBox(height: 116)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedSliver extends StatelessWidget {
  const _FeedSliver({required this.controller});

  final DiscoveryController controller;

  @override
  Widget build(BuildContext context) {
    final listings = controller.listings;

    if (controller.status == DiscoveryStatus.initial ||
        (controller.isLoading && listings.isEmpty)) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, __) => const ServiceCardSkeleton(),
        ),
      );
    }

    if (controller.status == DiscoveryStatus.failure) {
      return SliverToBoxAdapter(
        child: EmptyStateView(
          icon: Icons.wifi_off_rounded,
          title: 'Ups, ada kendala',
          message: controller.errorMessage ?? 'Gagal memuat data.',
          actionLabel: 'Coba lagi',
          onAction: controller.refresh,
        ),
      );
    }

    if (listings.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyStateView(
          icon: Icons.travel_explore_rounded,
          title: 'Belum ada yang cocok di radius ini',
          message: 'Coba perluas jangkauan atau ubah filter jenis & Smart Barter.',
          actionLabel: 'Perluas radius',
          onAction: () => showRadiusSheet(context, controller),
        ),
      );
    }

    // Feed 2 kolom ala masonry: item genap kiri, ganjil kanan (Figma: kolom
    // 170 px, jarak 13). Tiap kartu muncul bertahap.
    Widget column(int parity) => Expanded(
          child: Column(
            spacing: 14,
            children: [
              for (var i = parity; i < listings.length; i += 2)
                FadeSlideIn(
                  key: ValueKey('feed-${listings[i].id}'),
                  index: i,
                  child: _card(context, listings[i]),
                ),
            ],
          ),
        );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 13,
          children: [column(0), column(1)],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, ServiceListing listing) => MarketCard(
        key: ValueKey('service-${listing.id}'),
        listing: listing,
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.serviceDetail,
          arguments: listing,
        ),
        onChat: () => Navigator.of(context).pushNamed(
          AppRoutes.chat,
          arguments: listing,
        ),
      );
}
