import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_listing.dart';
import '../controllers/discovery_controller.dart';

IconData categoryIcon(String iconKey) {
  switch (iconKey) {
    case 'design':
      return Icons.brush_outlined;
    case 'tech':
      return Icons.laptop_mac_outlined;
    case 'photo':
      return Icons.photo_camera_outlined;
    case 'tutor':
      return Icons.menu_book_outlined;
    default:
      return Icons.work_outline_rounded;
  }
}

String radiusLabel(int meters) => meters < 1000
    ? '${meters}m'
    : '${(meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1)} km';

enum FilterChipTone { neutral, barter }

/// Chip filter Figma "Scrollable filters": tinggi 32, radius pill, border
/// 1 #E2E8F0, teks 11/600. Aktif = emerald penuh + teks putih.
/// Transisi warna 160 ms + skala tekan halus.
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.tone = FilterChipTone.neutral,
    this.minWidth = 0,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final FilterChipTone tone;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        tone == FilterChipTone.barter ? AppColors.barter : AppColors.primary;
    final bg = selected ? activeColor : AppColors.cardSurface;
    final border = selected ? activeColor : AppColors.borderLight;
    final fg = selected ? Colors.white : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: PressableScale(
        scale: 0.95,
        onTap: () {
          SakuMotion.tick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: SakuMotion.curve,
          height: 32,
          constraints: BoxConstraints(minWidth: minWidth),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.pillBr,
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 15 / 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris chip Beranda: Semua · Jasa Tersedia · Kebutuhan Proyek ·
/// Smart Barter · < 2 km Cibiru (bisa digeser horizontal).
class HomeFilterChips extends StatelessWidget {
  const HomeFilterChips({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final DiscoveryController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    final all = filter.kind == null && !filter.barterOnly;
    final chips = <Widget>[
      FilterChipPill(
        key: const Key('filter-all'),
        label: 'Semua',
        selected: all,
        onTap: () {
          controller.setKind(null);
          controller.setBarterOnly(false);
        },
      ),
      FilterChipPill(
        key: const Key('filter-offer'),
        label: 'Jasa Tersedia',
        selected: filter.kind == ListingKind.offer,
        onTap: () => controller.setKind(
          filter.kind == ListingKind.offer ? null : ListingKind.offer,
        ),
      ),
      FilterChipPill(
        key: const Key('filter-request'),
        label: 'Kebutuhan Proyek',
        selected: filter.kind == ListingKind.request,
        onTap: () => controller.setKind(
          filter.kind == ListingKind.request ? null : ListingKind.request,
        ),
      ),
      FilterChipPill(
        key: const Key('filter-barter'),
        label: 'Smart Barter',
        selected: filter.barterOnly,
        tone: FilterChipTone.barter,
        onTap: controller.toggleBarterOnly,
      ),
      FilterChipPill(
        key: const Key('filter-radius'),
        label: '< ${radiusLabel(filter.radiusMeters)} ${AppConfig.campusLabel}',
        onTap: () => showRadiusSheet(context, controller),
      ),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }
}

/// Chip kategori horizontal ("Semua" + kategori) — dipakai halaman pencarian.
class CategoryChipsRow extends StatelessWidget {
  const CategoryChipsRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ServiceCategory> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return FilterChipPill(
              label: 'Semua',
              selected: selectedId == null,
              onTap: () => onSelected(null),
            );
          }
          final c = categories[i - 1];
          return FilterChipPill(
            key: Key('category-${c.id}'),
            label: c.label,
            selected: selectedId == c.id,
            onTap: () => onSelected(selectedId == c.id ? null : c.id),
          );
        },
      ),
    );
  }
}

/// Pilihan radius Figma "6 · Explore Cibiru": chip 32 px lebar 65.
class RadiusPills extends StatelessWidget {
  const RadiusPills({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          for (final r in AppConfig.radiusOptions)
            FilterChipPill(
              key: Key('radius-$r'),
              label: radiusLabel(r),
              minWidth: 65,
              selected: r == value,
              onTap: () => onChanged(r),
            ),
        ],
      ),
    );
  }
}

/// Segmented control radius (500m · 1 km · 2 km · 3 km) — halaman pencarian.
class RadiusSegmented extends StatelessWidget {
  const RadiusSegmented({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.pillBr,
        boxShadow: AppShadows.flat,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in AppConfig.radiusOptions)
            _RadiusOption(
              label: radiusLabel(r),
              selected: r == value,
              onTap: () => onChanged(r),
            ),
        ],
      ),
    );
  }
}

class _RadiusOption extends StatelessWidget {
  const _RadiusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Radius $label',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryPressed : Colors.transparent,
            borderRadius: AppRadius.pillBr,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet pemilih radius untuk Beranda.
Future<void> showRadiusSheet(
  BuildContext context,
  DiscoveryController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jangkauan pencarian', style: AppTypography.subheading),
              const SizedBox(height: 4),
              const Text(
                'Jarak dihitung dari UIN SGD Kampus 1 Cibiru (rumus Haversine).',
                style: AppTypography.body,
              ),
              const SizedBox(height: 12),
              for (final r in AppConfig.radiusOptions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.radar_rounded,
                    color: AppColors.textSecondary,
                  ),
                  title: Text('Dalam radius ${radiusLabel(r)}'),
                  trailing: r == controller.filter.radiusMeters
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    controller.setRadius(r);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
