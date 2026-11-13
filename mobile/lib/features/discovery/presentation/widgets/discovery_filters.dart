import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_pill.dart';
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

/// Baris filter cepat Home: Smart Barter · Radius · Bebas Joki.
class QuickFilterBar extends StatelessWidget {
  const QuickFilterBar({super.key, required this.controller});

  final DiscoveryController controller;

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SakuPill(
            key: const Key('filter-barter'),
            label: 'Smart Barter',
            icon: Icons.swap_horiz_rounded,
            tone: SakuPillTone.barter,
            selected: filter.barterOnly,
            onTap: controller.toggleBarterOnly,
          ),
          const SizedBox(width: 6),
          SakuPill(
            key: const Key('filter-radius'),
            label:
                '< ${radiusLabel(filter.radiusMeters)} ${AppConfig.campusLabel}',
            tone: SakuPillTone.primary,
            trailingIcon: Icons.expand_more_rounded,
            onTap: () => showRadiusSheet(context, controller),
          ),
          const SizedBox(width: 6),
          const SakuPill(
            label: 'Bebas Joki 100%',
            icon: Icons.verified_outlined,
            tone: SakuPillTone.integrity,
          ),
        ],
      ),
    );
  }
}

/// Chip kategori horizontal ("Semua" + kategori dari repository).
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
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return SakuPill(
              label: 'Semua',
              icon: Icons.apps_rounded,
              selected: selectedId == null,
              onTap: () => onSelected(null),
            );
          }
          final c = categories[i - 1];
          return SakuPill(
            key: Key('category-${c.id}'),
            label: c.label,
            icon: categoryIcon(c.iconKey),
            selected: selectedId == c.id,
            onTap: () => onSelected(selectedId == c.id ? null : c.id),
          );
        },
      ),
    );
  }
}

/// Segmented control radius (500m · 1 km · 2 km · 3 km) — gaya Figma Explore.
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
            color: selected ? AppColors.primary : Colors.transparent,
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

/// Bottom sheet pemilih radius untuk Home.
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
