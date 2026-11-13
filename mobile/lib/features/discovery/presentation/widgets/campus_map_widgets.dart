import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/service_listing.dart';
import '../pages/service_detail_page.dart';

/// Label keahlian singkat untuk marker, mis. "IT Support", "Jasa Desain".
String shortSkillLabel(ServiceListing l) {
  switch (l.category) {
    case 'Jasa Teknis':
      return 'IT Support';
    case 'Desain':
      return 'Jasa Desain';
    case 'Fotografi':
      return 'Foto & Video';
    case 'Bimbingan Belajar':
      return 'Tutor';
    default:
      return l.category;
  }
}

/// Marker talenta (Figma 02 · Explore): avatar ber-ring hijau + label pill
/// putih "Nama · Keahlian (jarak)".
class TalentMarker extends StatelessWidget {
  const TalentMarker({
    super.key,
    required this.listing,
    required this.selected,
    required this.onTap,
  });

  final ServiceListing listing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstName = listing.providerName.split(' ').first;
    final distance = listing.distanceMeters;
    final label = '$firstName · ${shortSkillLabel(listing)}'
        '${distance != null ? ' (${formatDistance(distance).replaceAll(' ', '')})' : ''}';

    return Semantics(
      button: true,
      selected: selected,
      label: 'Penyedia $label',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: const Duration(milliseconds: 180),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: selected ? AppShadows.emeraldGlow : AppShadows.flat,
                ),
                child: InitialsAvatar(name: listing.providerName, size: 40),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: AppRadius.pillBr,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.borderLight,
                ),
                boxShadow: AppShadows.flat,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label nama kampus di atas peta ("UIN SGD Kampus 1 / Cibiru").
class CampusMapLabel extends StatelessWidget {
  const CampusMapLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Text(
        'UIN SGD Kampus 1\nCibiru',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4D7C4A),
          shadows: [Shadow(color: Colors.white, blurRadius: 6)],
        ),
      ),
    );
  }
}

/// Titik lokasi pengguna / pusat kampus.
class OriginDot extends StatelessWidget {
  const OriginDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.escrow,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x553B82F6), blurRadius: 10, spreadRadius: 4),
        ],
      ),
    );
  }
}

/// Kartu pratinjau talenta terpilih (Figma 02 · Explore campus).
class TalentPreviewCard extends StatelessWidget {
  const TalentPreviewCard({
    super.key,
    required this.listing,
    required this.onOpenDetail,
  });

  final ServiceListing listing;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final distance = listing.distanceMeters;
    final meta = [
      listing.providerMajor?.split('•').first.trim() ?? listing.category,
      if (listing.rating != null)
        '★ ${listing.rating!.toStringAsFixed(1)} (${listing.reviewCount} Ulasan)',
    ].join(' • ');

    return Material(
      color: AppColors.cardSurface,
      elevation: 6,
      shadowColor: const Color(0x1F0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.cardBr,
        side: BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        borderRadius: AppRadius.cardBr,
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(name: listing.providerName, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.providerName,
                          style: AppTypography.subheading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          meta,
                          style: AppTypography.caption
                              .copyWith(fontWeight: FontWeight.w400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (distance != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${formatDistance(distance)}'
                  '${listing.landmark != null ? ' dari ${listing.landmark}' : ''}'
                  ' • Jalan Kaki ~${walkingMinutes(distance)} Menit',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                listing.title,
                style: AppTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              ServiceActionButtons(listing: listing),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol bulat kecil di atas peta (recenter, dll).
class MapCircleButton extends StatelessWidget {
  const MapCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardSurface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x22000000),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
