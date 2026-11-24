import 'package:flutter/material.dart';

import '../../features/activity/presentation/pages/activity_page.dart';
import '../../features/chat/presentation/pages/inbox_page.dart';
import '../../features/discovery/presentation/controllers/discovery_controller.dart';
import '../../features/discovery/presentation/controllers/discovery_scope.dart';
import '../../features/discovery/presentation/pages/campus_map_page.dart';
import '../../features/discovery/presentation/pages/home_discovery_page.dart';
import '../di/app_dependencies.dart';
import '../motion/saku_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../widgets/saku_icon.dart';
import 'quick_action_sheet.dart';

/// Tab bottom navigation (Figma "SakuSkill / Bottom navigation"):
/// Beranda · Explore · [+ Buat Baru] · Chat · Aktivitas.
/// "Buat Baru" bukan tab — membuka sheet aksi cepat (Figma "7 · Menu aksi
/// cepat").
enum MainTab {
  home('Beranda', SakuIcons.home),
  explore('Explore', SakuIcons.compass),
  chat('Chat', SakuIcons.chat),
  activity('Aktivitas', SakuIcons.briefcase);

  const MainTab(this.label, this.icon);
  final String label;
  final SakuIcons icon;
}

/// Kerangka navigasi utama: 4 tab dengan [IndexedStack] agar state tiap tab
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
    SakuMotion.tick();
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  /// Tab dibangun saat pertama kali dikunjungi (lazy) — peta & tile OSM
  /// tidak dimuat sebelum pengguna membuka Explore.
  Widget _page(MainTab tab) {
    if (!_visited.contains(tab)) return const SizedBox.shrink();
    return switch (tab) {
      MainTab.home => const HomeDiscoveryPage(),
      MainTab.explore => const CampusMapPage(),
      MainTab.chat => const InboxPage(),
      MainTab.activity => const ActivityPage(),
    };
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
          onCreate: () => showQuickActionSheet(context),
        ),
      ),
    );
  }
}

/// Bottom navigation: putih, garis atas #E2E8F0, tinggi 80 (termasuk area
/// indikator), ikon 22, label 10. Aktif = emerald bold. Tombol tengah
/// bulat 42 emerald dengan ikon plus.
///
/// Micro-interaction: ikon aktif sedikit membesar (1.08) & warna memudar
/// 200 ms; tombol + mengecil saat ditekan.
class SakuBottomNav extends StatelessWidget {
  const SakuBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
    required this.onCreate,
  });

  final MainTab current;
  final ValueChanged<MainTab> onSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    Widget item(MainTab tab) => Expanded(
          child: _NavItem(
            tab: tab,
            selected: tab == current,
            onTap: () => onSelected(tab),
          ),
        );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: AppShadows.navBar,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              item(MainTab.home),
              item(MainTab.explore),
              Expanded(child: _CreateItem(onTap: onCreate)),
              item(MainTab.chat),
              item(MainTab.activity),
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
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        key: Key('nav-${tab.name}'),
        onTap: onTap,
        radius: 32,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            AnimatedContainer(
              duration: SakuMotion.base,
              curve: SakuMotion.curve,
              width: selected ? 20 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 7),
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: SakuMotion.base,
              curve: SakuMotion.curve,
              child: SakuIcon(tab.icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            AnimatedDefaultTextStyle(
              duration: SakuMotion.base,
              style: TextStyle(
                fontSize: 10,
                height: 14 / 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateItem extends StatelessWidget {
  const _CreateItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buat Baru',
      excludeSemantics: true,
      child: PressableScale(
        key: const Key('nav-create'),
        scale: 0.92,
        onTap: onTap,
        child: Column(
          children: [
            const SizedBox(height: 3),
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.emeraldGlow,
              ),
              child: const SakuIcon(SakuIcons.plus, size: 22, color: Colors.white),
            ),
            const SizedBox(height: 1),
            const Text(
              'Buat Baru',
              style: TextStyle(
                fontSize: 10,
                height: 14 / 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
