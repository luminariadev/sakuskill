import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/navigation/main_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/discovery_scope.dart';
import '../widgets/discovery_filters.dart';
import '../widgets/home_sections.dart';
import '../widgets/service_card.dart';

/// Figma "Beranda" (section Menu).
class HomeDiscoveryPage extends StatelessWidget {
  const HomeDiscoveryPage({super.key});

  // TODO(anggota-5): ganti dengan data pengguna dari sesi autentikasi.
  static const String _demoUserName = 'Salma';
  static const String _demoLocation = 'Cibiru, Bandung';
  static const num _demoBalance = 150000;

  /// Padding horizontal konten atas Beranda (Figma: 24).
  static const EdgeInsets _pad = EdgeInsets.symmetric(horizontal: 24);

  @override
  Widget build(BuildContext context) {
    final controller = DiscoveryScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      floatingActionButton: AiEstimatorButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.priceEstimator),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 10, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: BrandHeader(
                    userName: _demoUserName,
                    onAvatarTap: () => MainShell.goTo(context, MainTab.profile),
                    onNotificationsTap: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Belum ada notifikasi baru.')),
                    ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 8, 17, 0),
                sliver: SliverToBoxAdapter(
                  child: LocationBalanceRow(
                    locationLabel: _demoLocation,
                    balance: _demoBalance,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 25, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: SearchEntryField(
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.search,
                      arguments: controller.filter.copyWith(query: ''),
                    ),
                    onLocationTap: () =>
                        MainShell.goTo(context, MainTab.explore),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: HomeFilterChips(controller: controller)),
              SliverPadding(
                padding: _pad.copyWith(top: 23),
                sliver: SliverList.list(
                  children: [
                    const EscrowPromiseBanner(),
                    const SizedBox(height: 25),
                    SectionHeader(
                      title: 'Keahlian di sekitarmu',
                      actionLabel: 'Lihat semua',
                      onAction: () => Navigator.of(context).pushNamed(
                        AppRoutes.search,
                        arguments: controller.filter,
                      ),
                    ),
                    if (controller.isFallback) ...[
                      const SizedBox(height: 8),
                      const OfflineDataBanner(),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              _FeedSliver(controller: controller),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
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
        padding: AppSpacing.screen,
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
          title: 'Belum ada jasa di radius ini',
          message:
              'Coba perluas jangkauan atau ubah kategori, rating & filter Smart Barter.',
          actionLabel: 'Perluas radius',
          onAction: () => showRadiusSheet(context, controller),
        ),
      );
    }

    // Kartu feed memakai inset 16 (Figma: x=16, lebar 361).
    return SliverPadding(
      padding: AppSpacing.screen,
      sliver: SliverList.separated(
        itemCount: listings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final listing = listings[i];
          return ServiceCard(
            key: ValueKey('service-${listing.id}'),
            listing: listing,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.serviceDetail,
              arguments: listing,
            ),
          );
        },
      ),
    );
  }
}
