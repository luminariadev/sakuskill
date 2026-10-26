import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/app_state_provider.dart';
import '../widgets/category_chips_bar.dart';
import '../widgets/campus_map_widget.dart';
import '../widgets/service_card.dart';
import '../widgets/service_order_sheet.dart';
import '../widgets/barter_proposal_dialog.dart';
import '../../../ai_estimator/presentation/widgets/ai_estimator_sheet.dart';
import '../../../escrow/presentation/pages/escrow_orders_page.dart';
import '../../../barter/presentation/pages/barter_hub_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class HomeDiscoveryPage extends StatefulWidget {
  const HomeDiscoveryPage({super.key});

  @override
  State<HomeDiscoveryPage> createState() => _HomeDiscoveryPageState();
}

class _HomeDiscoveryPageState extends State<HomeDiscoveryPage> {
  int _currentNavIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserSwitcherSheet(BuildContext context, AppStateProvider appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ganti Akun Demo (Uji RBAC)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Pilih peran untuk menguji pembatasan otorisasi & fitur marketplace:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              ...appState.users.map((u) {
                final isCurrent = u.id == appState.currentUser.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppTheme.primarySurface : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? AppTheme.primary : AppTheme.border,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(u.avatar),
                      radius: 18,
                    ),
                    title: Text(
                      u.name,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '${u.major} • ${u.role.name.toUpperCase()}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                        : null,
                    onTap: () {
                      appState.switchUser(u.id);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final activeOrders = appState.activeOrdersCount;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            // Tab 0: Fiverr Home Discovery Feed
            _buildFiverrHomeFeed(context, appState),

            // Tab 1: Interactive Campus Map View (Explore)
            _buildCampusMapView(context, appState),

            // Tab 2: Escrow Orders Ledger
            const EscrowOrdersPage(),

            // Tab 3: Smart Barter Hub
            const BarterHubPage(),

            // Tab 4: Fiverr Profile & Campus Account
            const ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primarySurface,
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (index) => setState(() => _currentNavIndex = index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_filled, color: AppTheme.primary),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore, color: AppTheme.primary),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: activeOrders > 0,
                label: Text('$activeOrders'),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.assignment_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: activeOrders > 0,
                label: Text('$activeOrders'),
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.assignment, color: AppTheme.primary),
              ),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz, color: AppTheme.primary),
              label: 'Barter',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              elevation: 3,
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: const Text(
                'AI Price Estimator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (_) => const AIEstimatorSheet(),
                );
              },
            )
          : null,
    );
  }

  Widget _buildFiverrHomeFeed(BuildContext context, AppStateProvider appState) {
    final currentUser = appState.currentUser;
    final services = appState.filteredServices;
    final popularServices = appState.popularServices;
    final barterServices = appState.barterServices;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Fiverr Top Wordmark Header (Iconic fiverr. logo + Icons)
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // SakuSkill Wordmark with Green Dot
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'sakuskill',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                            ),
                          ),
                          TextSpan(
                            text: '.',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'UIN SGD',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),

                // Right action icons: Notifications, Switch Account, Profile Avatar
                Row(
                  children: [
                    // Wallet Balance Capsule
                    InkWell(
                      onTap: () => appState.topUpBalance(100000),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet, size: 13, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              FormatterUtils.formatIDR(currentUser.walletBalance),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.add, size: 11, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Notification Icon with unread dot
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, size: 22, color: AppTheme.textPrimary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tidak ada notifikasi baru.')),
                            );
                          },
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // User Avatar with Role Switcher
                    GestureDetector(
                      onTap: () => _showUserSwitcherSheet(context, appState),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(currentUser.avatar),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 2. Fiverr Greeting (iOS Large Title style)
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi ${currentUser.name.split(' ').first},',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'What service are you looking for today?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Fiverr Persistent Search Bar (Clean Pill with Map Switch)
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => appState.setSearchQuery(val),
                      style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Search services, e.g. "desain banner"...',
                        hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        appState.setSearchQuery('');
                      },
                    ),
                  Container(
                    height: 22,
                    width: 1,
                    color: AppTheme.border,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map_outlined, size: 20, color: AppTheme.primary),
                    tooltip: 'Lihat di Peta',
                    onPressed: () => setState(() => _currentNavIndex = 1),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),

        // 4. Quick Filter Tags
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('🔄 Smart Barter'),
                    selected: appState.barterOnly,
                    onSelected: (_) => appState.toggleBarterOnly(),
                    selectedColor: const Color(0xFFF3E8FF),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: appState.barterOnly ? AppTheme.accentPurple : AppTheme.border,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: appState.barterOnly ? FontWeight.w700 : FontWeight.w600,
                      color: appState.barterOnly ? AppTheme.accentPurple : AppTheme.textSecondary,
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: Text('📍 < ${appState.maxDistanceKm.toInt()} km'),
                    selected: appState.maxDistanceKm < 3.0,
                    onSelected: (_) {
                      if (appState.maxDistanceKm < 3.0) {
                        appState.setMaxDistanceKm(3.0);
                      } else {
                        appState.setMaxDistanceKm(1.0);
                      }
                    },
                    selectedColor: AppTheme.primarySurface,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: appState.maxDistanceKm < 3.0 ? AppTheme.primary : AppTheme.border,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: appState.maxDistanceKm < 3.0 ? FontWeight.w700 : FontWeight.w600,
                      color: appState.maxDistanceKm < 3.0 ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.shield_outlined, size: 12, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          'Bebas Joki 100%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: Divider(height: 1, color: AppTheme.border),
        ),

        // 5. Fiverr Pro / SakuSkill Campus Hero Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CAMPUS PRO TALENT',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                        ),
                      ),
                      const Icon(Icons.verified, color: AppTheme.primary, size: 16),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Keahlian Terverifikasi Mahasiswa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pesan jasa praktis bergaransi Escrow atau ajukan Smart Barter tanpa uang tunai. Bebas joki akademik.',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 6. Fiverr Category Photo Cards ("Explore Categories")
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text(
                  'Popular Services',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              CategoryChipsBar(
                selectedCategory: appState.selectedCategory,
                onSelected: (cat) => appState.setSelectedCategory(cat),
              ),
            ],
          ),
        ),

        // 7. Horizontal Section: "Populer di Sekitar Kampus" (Fiverr Gig Cards)
        if (popularServices.isNotEmpty && appState.searchQuery.isEmpty && appState.selectedCategory == null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recently Viewed & More',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Text(
                    'See All >',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 275, // Generous height to prevent any RenderFlex overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: popularServices.length,
                itemBuilder: (context, index) {
                  final service = popularServices[index];
                  final provider = appState.users.firstWhere((u) => u.id == service.providerId);
                  final isFav = appState.isFavorite(service.id);

                  return _FiverrHorizontalGigCard(
                    service: service,
                    provider: provider,
                    isFavorite: isFav,
                    onFavoriteTap: () => appState.toggleFavorite(service.id),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => ServiceOrderSheet(service: service, provider: provider, appState: appState),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],

        // 8. Horizontal Section: Smart Barter Spotlight
        if (barterServices.isNotEmpty && appState.searchQuery.isEmpty && appState.selectedCategory == null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.swap_horiz, color: AppTheme.accentPurple, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Smart Barter Opportunities',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'See All >',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 275, // Generous height to prevent any RenderFlex overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: barterServices.length,
                itemBuilder: (context, index) {
                  final service = barterServices[index];
                  final provider = appState.users.firstWhere((u) => u.id == service.providerId);
                  final isFav = appState.isFavorite(service.id);

                  return _FiverrHorizontalGigCard(
                    service: service,
                    provider: provider,
                    isFavorite: isFav,
                    isBarterHighlighted: true,
                    onFavoriteTap: () => appState.toggleFavorite(service.id),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => ServiceOrderSheet(service: service, provider: provider, appState: appState),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],

        // 9. Section Header: All Services / Search Results
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appState.searchQuery.isNotEmpty
                      ? 'Search Results ("${appState.searchQuery}")'
                      : 'Inspired by your browsing history',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  '${services.length} Gigs',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        // 10. Fiverr Vertical Feed of Gigs
        if (services.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 10),
                    Text(
                      'No services found for your search',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final service = services[index];
                  final provider = appState.users.firstWhere((u) => u.id == service.providerId);
                  final isOwner = service.providerId == currentUser.id;
                  final isFav = appState.isFavorite(service.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ServiceCard(
                      service: service,
                      provider: provider,
                      isOwner: isOwner,
                      isFavorite: isFav,
                      onFavoriteTap: () => appState.toggleFavorite(service.id),
                      onOrderTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => ServiceOrderSheet(service: service, provider: provider, appState: appState),
                        );
                      },
                      onBarterTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => BarterProposalDialog(service: service, partner: provider, appState: appState),
                        );
                      },
                    ),
                  );
                },
                childCount: services.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCampusMapView(BuildContext context, AppStateProvider appState) {
    final services = appState.filteredServices;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore Campus Services on Map',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _currentNavIndex = 0),
              ),
            ],
          ),
        ),
        Expanded(
          child: CampusMapWidget(
            services: services,
            maxDistanceKm: appState.maxDistanceKm,
            onServiceSelected: (service) {
              final provider = appState.users.firstWhere((u) => u.id == service.providerId);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => ServiceOrderSheet(service: service, provider: provider, appState: appState),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact Horizontal Gig Card for Fiverr Carousels (Zero-Overflow Layout)
class _FiverrHorizontalGigCard extends StatelessWidget {
  final dynamic service;
  final dynamic provider;
  final bool isFavorite;
  final bool isBarterHighlighted;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _FiverrHorizontalGigCard({
    required this.service,
    required this.provider,
    required this.isFavorite,
    this.isBarterHighlighted = false,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 215,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBarterHighlighted ? AppTheme.accentPurple.withValues(alpha: 0.3) : AppTheme.border,
          width: isBarterHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Stack (Aspect 16:9.5)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9.5,
                    child: Image.network(
                      service.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.border,
                        child: const Icon(Icons.image_not_supported, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: onFavoriteTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isFavorite ? Colors.red : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${service.distanceFromCampusKm} km',
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body with Tight Spacing & No Overflow
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seller Info & Rating
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 8.5,
                        backgroundImage: NetworkImage(provider.avatar),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          provider.name,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star, color: AppTheme.starGold, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        provider.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Gig Title
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isBarterHighlighted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Bisa Barter',
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppTheme.accentPurple),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'STARTING AT',
                            style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.4),
                          ),
                          Text(
                            FormatterUtils.formatIDR(service.price),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
