import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../domain/entities/service_listing.dart';
import 'service_card.dart';

/// Label keahlian singkat untuk marker, mis. "Servis Laptop", "Desain".
String shortSkillLabel(ServiceListing l) {
  switch (l.category) {
    case 'Jasa Teknis':
      return 'Servis Laptop';
    case 'Fotografi':
      return 'Foto & Video';
    case 'Bimbingan Belajar':
      return 'Tutor';
    default:
      return l.category;
  }
}

/// Jarak ringkas tanpa spasi, mis. "600m" / "1.2km".
String compactDistance(double meters) =>
    formatDistance(meters).replaceAll(' ', '');

/// Ukuran marker talenta (Figma: 163 × 41).
const Size talentMarkerSize = Size(163, 41);

/// Marker talenta (Figma "Explore Cibiru"): pill putih ber-border mint,
/// ikon pin + "Nama · Keahlian" + jarak.
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
    final label = '$firstName · ${shortSkillLabel(listing)}';
    final distance = listing.distanceMeters;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Penyedia $label'
          '${distance != null ? ', ${compactDistance(distance)}' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.markerBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? AppShadows.emeraldGlow : AppShadows.flat,
          ),
          child: Row(
            children: [
              const SakuIcon(SakuIcons.pin, size: 20, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 14 / 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (distance != null)
                      Text(
                        compactDistance(distance),
                        style: const TextStyle(
                          fontSize: 9,
                          height: 13 / 9,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label area kampus di atas peta ("KAMPUS UIN SUNAN GUNUNG DJATI").
class CampusMapLabel extends StatelessWidget {
  const CampusMapLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.mapCampus.withValues(alpha: 0.92),
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: const Text(
          'KAMPUS UIN\nSUNAN GUNUNG DJATI',
          style: TextStyle(
            fontSize: 10,
            height: 14 / 10,
            fontWeight: FontWeight.w600,
            color: AppColors.mapCampusLabel,
          ),
        ),
      ),
    );
  }
}

/// Titik biru "Lokasi Anda" (17px, border putih).
class OriginDot extends StatelessWidget {
  const OriginDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.escrow,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x553B82F6), blurRadius: 8, spreadRadius: 3),
        ],
      ),
    );
  }
}

/// Kartu talenta terdekat (Figma "Salma terdekat"): avatar 42, nama 15/700,
/// harga 18/700, meta jarak + rating, tombol Chat Langsung / Lihat Profil &
/// Order.
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
      if (distance != null) '${compactDistance(distance)} dari Anda',
      if (listing.rating != null)
        'Rating ${listing.rating!.toStringAsFixed(1)} ★',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.fromBorderSide(BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: listing.providerName, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 21 / 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 15 / 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PriceLabel(listing: listing, fontSize: 18, color: AppColors.primary),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              meta,
              style: const TextStyle(
                fontSize: 11,
                height: 15 / 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                flex: 146,
                child: SakuButton(
                  key: const Key('map-chat'),
                  label: 'Chat Langsung',
                  variant: SakuButtonVariant.outline,
                  height: 34,
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.chat,
                    arguments: listing,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 171,
                child: SakuButton(
                  key: const Key('map-open-detail'),
                  label: 'Lihat Profil & Order',
                  height: 34,
                  onPressed: onOpenDetail,
                ),
              ),
            ],
          ),
        ],
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
