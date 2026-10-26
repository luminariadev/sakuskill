import 'package:flutter/material.dart';
import '../../../../core/constants/campus_constants.dart';
import '../../../../core/theme/app_theme.dart';

class CategoryChipsBar extends StatelessWidget {
  final ServiceCategory? selectedCategory;
  final ValueChanged<ServiceCategory?> onSelected;

  const CategoryChipsBar({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  String _getCategoryImageUrl(ServiceCategory? cat) {
    switch (cat) {
      case null:
        return 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=300&q=80';
      case ServiceCategory.itSupport:
        return 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?auto=format&fit=crop&w=300&q=80';
      case ServiceCategory.creativeDesign:
        return 'https://images.unsplash.com/photo-1626785774573-4b799315345d?auto=format&fit=crop&w=300&q=80';
      case ServiceCategory.photography:
        return 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=300&q=80';
      case ServiceCategory.tutoring:
        return 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=300&q=80';
      case ServiceCategory.eventSupport:
        return 'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=300&q=80';
    }
  }

  IconData _getCategoryIcon(ServiceCategory? cat) {
    switch (cat) {
      case null:
        return Icons.grid_view_rounded;
      case ServiceCategory.itSupport:
        return Icons.laptop_chromebook_rounded;
      case ServiceCategory.creativeDesign:
        return Icons.brush_rounded;
      case ServiceCategory.photography:
        return Icons.photo_camera_rounded;
      case ServiceCategory.tutoring:
        return Icons.school_rounded;
      case ServiceCategory.eventSupport:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All category tile
          _buildCategoryCard(
            label: 'Semua',
            category: null,
            isSelected: selectedCategory == null,
            onTap: () => onSelected(null),
          ),
          ...ServiceCategory.values.map((cat) {
            final isSelected = selectedCategory == cat;
            final meta = CategoryMeta.info[cat]!;
            return _buildCategoryCard(
              label: meta.label,
              category: cat,
              isSelected: isSelected,
              onTap: () => onSelected(cat),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String label,
    required ServiceCategory? category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final imageUrl = _getCategoryImageUrl(category);
    final icon = _getCategoryIcon(category);

    return Container(
      width: 108,
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo background
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isSelected ? AppTheme.primary : const Color(0xFF334155),
                  child: Center(
                    child: Icon(icon, color: Colors.white70, size: 28),
                  ),
                ),
              ),

              // Dark gradient overlay for text readability (Fiverr visual pattern)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),

              // Active indicator badge
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),

              // Icon on top-left
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
              ),

              // Title at bottom (Fiverr style)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.2,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                  maxLines: 2,
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
