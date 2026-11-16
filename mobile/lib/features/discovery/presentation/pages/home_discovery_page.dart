import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/navigation/main_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/service_listing.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/discovery_scope.dart';
import '../widgets/discovery_filters.dart';
import '../widgets/home_sections.dart';
import '../widgets/market_card.dart';
import '../widgets/service_card.dart';

/// Figma "5 · Beranda marketplace".
class HomeDiscoveryPage extends StatelessWidget {
  const HomeDiscoveryPage({super.key});

  // TODO(anggota-5): ganti dengan data pengguna & saldo dari sesi login.
  static const String _demoUserName = 'Salma Nur Oktavia';
  static const num _demoBalance = 250000;

  @override
  Widget build(BuildContext context) {
    final controller = DiscoveryScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                sliver: SliverList.list(
                  children: [
                    MarketplaceHeader(
                      userName: _demoUserName,
                      balance: _demoBalance,
                      avatarAsset: DemoAssets.salma,
                      onBalanceTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.wallet),
                      onAvatarTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.profileSetup),
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
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
