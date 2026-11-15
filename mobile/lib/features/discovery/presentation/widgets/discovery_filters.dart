import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/service_category.dart';
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

/// Chip filter Figma "Beranda" / "Explore": tinggi 28, radius pill,
/// teks 10/600. Aktif = #047857 + teks putih.
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
    final (Color bg, Color fg) = switch ((tone, selected)) {
      (FilterChipTone.barter, false) => (
          AppColors.barterSurface,
          AppColors.barterText
        ),
      (FilterChipTone.barter, true) => (AppColors.barter, Colors.white),
      (FilterChipTone.neutral, true) => (AppColors.primaryPressed, Colors.white),
      (FilterChipTone.neutral, false) => (
          AppColors.cardSurface,
          AppColors.textSecondary
        ),
    };

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth, minHeight: 28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Baris chip Beranda: Semua · ⇄ Bisa Barter · Terdekat < radius · 4.8+,
/// lalu kategori dari repository (bisa digeser horizontal).
class HomeFilterChips extends StatelessWidget {
  const HomeFilterChips({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final DiscoveryController controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    final rating = AppConfig.topRatedThreshold.toStringAsFixed(1);
    final chips = <Widget>[
      FilterChipPill(
        key: const Key('category-all'),
        label: 'Semua',
        selected: filter.categoryId == null,
        onTap: () => controller.setCategory(null),
      ),
      FilterChipPill(
        key: const Key('filter-barter'),
        label: '⇄ Bisa Barter',
        tone: FilterChipTone.barter,
        selected: filter.barterOnly,
        onTap: controller.toggleBarterOnly,
      ),
      FilterChipPill(
        key: const Key('filter-radius'),
        label: 'Terdekat < ${radiusLabel(filter.radiusMeters)}',
        onTap: () => showRadiusSheet(context, controller),
      ),
      FilterChipPill(
        key: const Key('filter-rating'),
        label: '$rating+',
        selected: filter.minRating != null,
        onTap: controller.toggleTopRated,
      ),
      for (final c in controller.categories)
        FilterChipPill(
          key: Key('category-${c.id}'),
          label: c.label,
          selected: filter.categoryId == c.id,
          onTap: () => controller
              .setCategory(filter.categoryId == c.id ? null : c.id),
        ),
    ];

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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

/// Pilihan radius Figma "Explore Cibiru": pill terpisah, sama lebar.
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
    final options = AppConfig.radiusOptions;
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: 'Radius ${radiusLabel(options[i])}',
              child: FilterChipPill(
                key: Key('radius-${options[i]}'),
                label: radiusLabel(options[i]),
                selected: options[i] == value,
                onTap: () => onChanged(options[i]),
              ),
            ),
          ),
        ],
      ],
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
