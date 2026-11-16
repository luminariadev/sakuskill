import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../domain/entities/service_listing.dart';

/// Kartu layanan pada feed "Keahlian di sekitarmu"
/// (Figma "Ahmad Fauzi service": padding 14, jarak antar-baris 10).
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.listing, this.onTap});

  final ServiceListing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // TODO(anggota-5): pakai foto profil bila backend menyediakan.
                  InitialsAvatar(name: listing.providerName, size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.providerName,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          listing.providerMajor ?? listing.category,
                          style: const TextStyle(
                            fontSize: 9,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (listing.distanceMeters != null) ...[
                    const SizedBox(width: 8),
                    DistanceLabel(meters: listing.distanceMeters!),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                listing.title,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: PriceLabel(listing: listing)),
                  if (listing.offerType.acceptsBarter) ...[
                    const SizedBox(width: 8),
                    const BarterBadge(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge ungu "Bisa Barter" (padding 7, teks 10/600 #7E22CE).
class BarterBadge extends StatelessWidget {
  const BarterBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(
        color: AppColors.barterSurface,
        borderRadius: AppRadius.pillBr,
      ),
      child: const Text(
        'Bisa Barter',
        style: TextStyle(
          fontSize: 10,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.barterText,
        ),
      ),
    );
  }
}

/// "0.3 km / Cibiru" di kanan atas kartu.
class DistanceLabel extends StatelessWidget {
  const DistanceLabel({super.key, required this.meters});

  final double meters;

  @override
  Widget build(BuildContext context) {
    return Text(
      // Figma menampilkan km satu desimal, mis. "0.3 km".
      '${(meters / 1000).toStringAsFixed(1)} km\n${AppConfig.campusLabel}',
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 9,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryPressed,
      ),
    );
  }
}

/// "Mulai Rp 35.000" — atau "Tukar keahlian" untuk listing murni barter.
class PriceLabel extends StatelessWidget {
  const PriceLabel({
    super.key,
    required this.listing,
    this.fontSize = 13,
    this.color = AppColors.primaryPressed,
  });

  final ServiceListing listing;
  final double fontSize;

  /// Warna harga berbayar (kartu feed #047857, kartu peta #059669).
  final Color color;

  @override
  Widget build(BuildContext context) {
    final price = listing.price;
    final barterOnly = price == null || !listing.offerType.acceptsPayment;
    return Text(
      barterOnly ? 'Tukar keahlian' : 'Mulai ${formatRupiah(price)}',
      style: TextStyle(
        fontSize: fontSize,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: barterOnly ? AppColors.barterText : color,
      ),
    );
  }
}

/// Skeleton saat memuat.
class ServiceCardSkeleton extends StatelessWidget {
  const ServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: const BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: AppRadius.tagBr,
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.borderLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                bar(120, 12),
              ],
            ),
            const SizedBox(height: 14),
            bar(240, 14),
            const SizedBox(height: 14),
            bar(110, 14),
          ],
        ),
      ),
    );
  }
}
