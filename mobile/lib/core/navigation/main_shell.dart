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
import '../widgets/saku_icon.dart';

/// Urutan tab bottom navigation (sesuai Figma: Beranda · Explore · Orders ·
/// Barter · Profil).
enum MainTab {
  home('Beranda', SakuIcons.home),
  explore('Explore', SakuIcons.compass),
  orders('Orders', SakuIcons.orders),
  barter('Barter', SakuIcons.swap),
  profile('Profil', SakuIcons.user);

  const MainTab(this.label, this.icon);
  final String label;
  final SakuIcons icon;
}

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
        bottomNavigationBar: SakuBottomNav(
          current: _tab,
          onSelected: _select,
        ),
      ),
    );
  }
}

/// Bottom navigation Figma "Navigation / Beranda": putih, garis atas
/// #E2E8F0, tinggi 64, ikon 22px, label 10px. Tab aktif #047857 semibold.
class SakuBottomNav extends StatelessWidget {
  const SakuBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final MainTab current;
  final ValueChanged<MainTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final tab in MainTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: tab == current,
                    onTap: () => onSelected(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final MainTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryPressed : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: InkWell(
        key: Key('nav-${tab.name}'),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            SakuIcon(tab.icon, size: 22, color: color),
            const SizedBox(height: 7),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                height: 14 / 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
