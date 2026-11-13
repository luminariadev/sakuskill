import 'package:material_ui/material_ui.dart';

import '../../features/auth/presentation/profile_placeholder_page.dart';
import '../../features/barter/presentation/barter_placeholder_page.dart';
import '../../features/discovery/presentation/controllers/discovery_controller.dart';
import '../../features/discovery/presentation/controllers/discovery_scope.dart';
import '../../features/discovery/presentation/pages/campus_map_page.dart';
import '../../features/discovery/presentation/pages/home_discovery_page.dart';
import '../../features/escrow/presentation/orders_placeholder_page.dart';
import '../di/app_dependencies.dart';
import '../theme/app_colors.dart';

/// Urutan tab bottom navigation (sesuai Figma: Home · Explore · Orders ·
/// Barter · Profil).
enum MainTab { home, explore, orders, barter, profile }

/// Kerangka navigasi utama: 5 tab dengan [IndexedStack] agar state tiap tab
/// (scroll, posisi peta) tidak hilang saat berpindah tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialTab = MainTab.home});

  final MainTab initialTab;

  /// Pindah tab dari halaman mana pun di bawah shell,
  /// mis. `MainShell.goTo(context, MainTab.explore)`.
  static void goTo(BuildContext context, MainTab tab) {
    context.findAncestorStateOfType<_MainShellState>()?._select(tab);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late MainTab _tab = widget.initialTab;
  late final Set<MainTab> _visited = {widget.initialTab};
  DiscoveryController? _discovery;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _discovery ??= AppScope.of(context).createDiscoveryController()..init();
  }

  @override
  void dispose() {
    _discovery?.dispose();
    super.dispose();
  }

  void _select(MainTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  /// Tab dibangun saat pertama kali dikunjungi (lazy) — peta & tile OSM
  /// tidak dimuat sebelum pengguna membuka Explore.
  Widget _page(MainTab tab) {
    if (!_visited.contains(tab)) return const SizedBox.shrink();
    switch (tab) {
      case MainTab.home:
        return const HomeDiscoveryPage();
      case MainTab.explore:
        return const CampusMapPage();
      case MainTab.orders:
        return const OrdersPlaceholderPage();
      case MainTab.barter:
        return const BarterPlaceholderPage();
      case MainTab.profile:
        return const ProfilePlaceholderPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DiscoveryScope(
      controller: _discovery!,
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: [for (final tab in MainTab.values) _page(tab)],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: NavigationBar(
            selectedIndex: _tab.index,
            onDestinationSelected: (i) => _select(MainTab.values[i]),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_rounded),
                label: 'Barter',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
