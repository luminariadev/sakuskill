import 'package:flutter/material.dart';

import '../../features/activity/presentation/pages/my_services_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/barter/presentation/pages/barter_chat_page.dart';
import '../../features/barter/presentation/pages/barter_done_page.dart';
import '../../features/barter/presentation/pages/barter_history_page.dart';
import '../../features/barter/presentation/pages/barter_incoming_page.dart';
import '../../features/barter/presentation/pages/barter_offer_page.dart';
import '../../features/barter/presentation/pages/barter_propose_page.dart';
import '../../features/barter/presentation/pages/barter_workroom_page.dart';
import '../../features/complaint/presentation/pages/complaint_page.dart';
import '../../features/discovery/domain/entities/discovery_filter.dart';
import '../../features/discovery/domain/entities/service_listing.dart';
import '../../features/discovery/presentation/pages/search_page.dart';
import '../../features/discovery/presentation/pages/service_detail_page.dart';
import '../../features/escrow/presentation/pages/appeal_page.dart';
import '../../features/escrow/presentation/pages/escrow_payment_page.dart';
import '../../features/escrow/presentation/pages/incoming_order_page.dart';
import '../../features/escrow/presentation/pages/late_status_page.dart';
import '../../features/escrow/presentation/pages/order_chat_page.dart';
import '../../features/escrow/presentation/pages/order_create_page.dart';
import '../../features/escrow/presentation/pages/order_done_page.dart';
import '../../features/escrow/presentation/pages/order_tracking_page.dart';
import '../../features/escrow/presentation/pages/review_work_page.dart';
import '../../features/escrow/presentation/pages/submit_work_page.dart';
import '../../features/escrow/presentation/pages/workroom_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../widgets/state_views.dart';
import 'main_shell.dart';

/// Daftar nama rute aplikasi (navigasi terpusat). Nomor di komentar
/// mengacu ke frame Figma "User Design".
abstract final class AppRoutes {
  // ---- Akun (1–4) --------------------------------------------------------
  static const String welcome = '/welcome'; // 1
  static const String login = '/auth/login'; // 2
  static const String register = '/auth/register'; // 3
  static const String profileSetup = '/auth/profile-setup'; // 4

  // ---- Marketplace (5–10) ------------------------------------------------
  static const String shell = '/'; // 5 Beranda · 6 Explore · 8 Chat · 9 Aktivitas
  static const String search = '/discovery/search';
  static const String serviceDetail = '/discovery/service'; // 10
  static const String myServices = '/activity/my-services'; // 9B

  // ---- Pesanan jasa · escrow (11–18) -------------------------------------
  static const String orderService = '/escrow/order'; // 11 (arg: ServiceListing?)
  static const String incomingOrders = '/escrow/incoming'; // 12 + 12B
  static const String orderChat = '/escrow/chat'; // 13
  static const String payment = '/escrow/payment'; // 14
  static const String tracking = '/escrow/tracking'; // 14B + 15C
  static const String workroom = '/escrow/workroom'; // 15 + 15B
  static const String lateStatus = '/escrow/late'; // 15D + 15D-2
  static const String appeal = '/escrow/appeal'; // 15E
  static const String submitWork = '/escrow/submit'; // 16
  static const String reviewWork = '/escrow/review'; // 17
  static const String orderDone = '/escrow/done'; // 18

  /// Chat dari kartu/peta/detail (arg: ServiceListing) → ruang diskusi brief.
  static const String chat = orderChat;

  // ---- Smart Barter (19–24B) ---------------------------------------------
  static const String proposeBarter = '/barter/propose'; // 19
  static const String barterOffer = '/barter/offer'; // 20
  static const String barterIncoming = '/barter/incoming'; // 21 + 21B
  static const String barterChat = '/barter/chat'; // 22
  static const String barterWorkroom = '/barter/workroom'; // 23
  static const String barterDone = '/barter/done'; // 24
  static const String barterHistory = '/barter/history'; // 24B

  // ---- Dompet & bantuan (25–26) ------------------------------------------
  static const String wallet = '/wallet'; // 25
  static const String complaint = '/complaint'; // 26

  /// Anggota 6 (AI Price Estimator).
  static const String priceEstimator = '/ai/price-estimator';
}

abstract final class AppRouter {
  /// Rute tanpa argumen wajib → pembangun halaman.
  static final Map<String, WidgetBuilder> _pages = {
    AppRoutes.welcome: (_) => const WelcomePage(),
    AppRoutes.login: (_) => const LoginPage(),
    AppRoutes.register: (_) => const RegisterPage(),
    AppRoutes.profileSetup: (_) => const ProfileSetupPage(),
    AppRoutes.shell: (_) => const MainShell(),
    AppRoutes.myServices: (_) => const MyServicesPage(),
    AppRoutes.incomingOrders: (_) => const IncomingOrderPage(),
    AppRoutes.orderChat: (_) => const OrderChatPage(),
    AppRoutes.payment: (_) => const EscrowPaymentPage(),
    AppRoutes.tracking: (_) => const OrderTrackingPage(),
    AppRoutes.workroom: (_) => const WorkroomPage(),
    AppRoutes.lateStatus: (_) => const LateStatusPage(),
    AppRoutes.appeal: (_) => const AppealPage(),
    AppRoutes.submitWork: (_) => const SubmitWorkPage(),
    AppRoutes.reviewWork: (_) => const ReviewWorkPage(),
    AppRoutes.orderDone: (_) => const OrderDonePage(),
    AppRoutes.proposeBarter: (_) => const BarterProposePage(),
    AppRoutes.barterOffer: (_) => const BarterOfferPage(),
    AppRoutes.barterIncoming: (_) => const BarterIncomingPage(),
    AppRoutes.barterChat: (_) => const BarterChatPage(),
    AppRoutes.barterWorkroom: (_) => const BarterWorkroomPage(),
    AppRoutes.barterDone: (_) => const BarterDonePage(),
    AppRoutes.barterHistory: (_) => const BarterHistoryPage(),
    AppRoutes.wallet: (_) => const WalletPage(),
    AppRoutes.complaint: (_) => const ComplaintPage(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    final builder = _pages[name];
    if (builder != null) {
      return MaterialPageRoute(settings: settings, builder: builder);
    }

    switch (name) {
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
        final listing = settings.arguments;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => OrderCreatePage(
            listing: listing is ServiceListing ? listing : null,
          ),
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
