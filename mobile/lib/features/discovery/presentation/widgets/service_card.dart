import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_pill.dart';
import '../../domain/entities/service_listing.dart';

/// Kartu layanan pada feed "Keahlian di sekitarmu" (Figma 01 · Home).
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
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(name: listing.providerName),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.providerName,
                          style: AppTypography.bodyLarge
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          listing.providerMajor ?? listing.category,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (listing.distanceMeters != null)
                    DistanceLabel(meters: listing.distanceMeters!),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                listing.title,
                style: AppTypography.subheading.copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: PriceLabel(listing: listing)),
                  if (listing.offerType.acceptsBarter)
                    const SakuPill(
                      label: 'Bisa Barter',
                      tone: SakuPillTone.barter,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DistanceLabel extends StatelessWidget {
  const DistanceLabel({super.key, required this.meters});

  final double meters;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${formatDistance(meters)}\n${AppConfig.campusLabel}',
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 10,
        height: 13 / 10,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }
}

class PriceLabel extends StatelessWidget {
  const PriceLabel({super.key, required this.listing, this.fontSize = 15});

  final ServiceListing listing;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final price = listing.price;
    final text = (price == null || !listing.offerType.acceptsPayment)
        ? 'Tukar keahlian'
        : 'Mulai ${formatRupiah(price)}';
    final color = (price == null || !listing.offerType.acceptsPayment)
        ? AppColors.barter
        : AppColors.primary;
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
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
        padding: const EdgeInsets.all(15),
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
