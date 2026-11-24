import 'dart:ui';

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
        extendBody: true,
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

/// Floating iPhone-style rounded Glassmorphism bottom dock + 3D Clay Emerald
/// Orb di tengah (+ Buat Baru). Membiarkan feed & peta mengalir lembut
/// di balik permukaan kaca buram.
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: AppRadius.floatingDockBr,
            boxShadow: AppShadows.floatingDock,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.floatingDockBr,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 68,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: AppRadius.floatingDockBr,
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 1.3,
                  ),
                ),
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
      child: PressableScale(
        key: Key('nav-${tab.name}'),
        scale: 0.94,
        onTap: onTap,
        child: AnimatedContainer(
          duration: SakuMotion.base,
          curve: SakuMotion.curve,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: selected
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    width: 1.0,
                  )
                : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14059669),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: SakuMotion.base,
                curve: SakuMotion.curve,
                child: SakuIcon(tab.icon, size: 20, color: color),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: SakuMotion.base,
                style: TextStyle(
                  fontSize: 10,
                  height: 12 / 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primaryPressed],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.34),
                width: 1.2,
              ),
              boxShadow: AppShadows.emeraldGlow,
            ),
            child: const SakuIcon(
              SakuIcons.plus,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
