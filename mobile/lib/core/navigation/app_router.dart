import 'package:flutter/material.dart';

import '../../features/discovery/domain/entities/discovery_filter.dart';
import '../../features/discovery/domain/entities/service_listing.dart';
import '../../features/discovery/presentation/pages/search_page.dart';
import '../../features/discovery/presentation/pages/service_detail_page.dart';
import '../theme/app_colors.dart';
import '../widgets/state_views.dart';
import 'main_shell.dart';

/// Daftar nama rute aplikasi. Modul lain menambahkan rutenya di sini agar
/// navigasi tetap terpusat.
abstract final class AppRoutes {
  static const String shell = '/';
  static const String search = '/discovery/search';
  static const String serviceDetail = '/discovery/service';

  // ---- Rute yang dicadangkan untuk modul anggota lain --------------------
  /// Anggota 4 (Escrow): argumen = [ServiceListing].
  static const String orderService = '/escrow/order';

  /// Anggota 4 (Smart Barter): argumen = [ServiceListing].
  static const String proposeBarter = '/barter/propose';

  /// Anggota 6 (AI Price Estimator).
  static const String priceEstimator = '/ai/price-estimator';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.shell:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainShell(),
        );

      case AppRoutes.search:
        final filter = settings.arguments is DiscoveryFilter
            ? settings.arguments as DiscoveryFilter
            : const DiscoveryFilter();
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SearchPage(initialFilter: filter),
        );

      case AppRoutes.serviceDetail:
        final listing = settings.arguments;
        if (listing is! ServiceListing) return _notFound(settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ServiceDetailPage(listing: listing),
        );

      case AppRoutes.orderService:
        return _placeholder(
          settings,
          title: 'Pesan Jasa',
          subtitle: 'Alur Escrow Orders',
          icon: Icons.verified_user_outlined,
          owner: 'Anggota 4 — Frontend Feature (Escrow)',
          accent: AppColors.escrow,
        );

      case AppRoutes.proposeBarter:
        return _placeholder(
          settings,
          title: 'Ajak Barter',
          subtitle: 'Smart Barter — persetujuan bilateral',
          icon: Icons.swap_horiz_rounded,
          owner: 'Anggota 4 — Frontend Feature (Smart Barter)',
          accent: AppColors.barter,
        );

      case AppRoutes.priceEstimator:
        return _placeholder(
          settings,
          title: 'AI Price Estimator',
          subtitle: 'Rekomendasi tarif wajar mahasiswa',
          icon: Icons.auto_awesome_outlined,
          owner: 'Anggota 6 — AI & Security Engineer',
        );
    }
    return _notFound(settings);
  }

  static Route<dynamic> _placeholder(
    RouteSettings settings, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String owner,
    Color accent = AppColors.primary,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(),
        body: ModulePlaceholderPage(
          title: title,
          subtitle: subtitle,
          icon: icon,
          owner: owner,
          accent: accent,
        ),
      ),
    );
  }

  static Route<dynamic> _notFound(RouteSettings settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Halaman tidak ditemukan')),
        ),
      );
}
