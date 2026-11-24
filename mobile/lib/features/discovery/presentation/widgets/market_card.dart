import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../domain/entities/service_listing.dart';
import 'discovery_filters.dart';

/// Kartu feed 2 kolom Beranda bergaya Claymorphism murni (tanpa ketergantungan
/// foto): medallion kategori clay + badge jenis + info penyedia & tarif/barter.
class MarketCard extends StatelessWidget {
  const MarketCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onChat,
  });

  final ServiceListing listing;
  final VoidCallback onTap;
  final VoidCallback? onChat;

  String get _price {
    final price = listing.price;
    if (listing.isRequest) {
      return price != null ? 'Budget ${formatRupiah(price)}' : 'Budget nego';
    }
    if (price == null || !listing.offerType.acceptsPayment) {
      return listing.barterWant ?? 'Tukar keahlian';
    }
    return formatRupiah(price);
  }

  String get _meta {
    final d = listing.distanceMeters;
    final dist = d == null ? null : formatDistance(d).replaceAll(' ', '');
    if (listing.isRequest) {
      final days = listing.deliveryDays;
      return days != null ? 'Butuh $days Hari' : (dist ?? '');
    }
    if (!listing.offerType.acceptsPayment) {
      return dist != null ? '$dist dari Anda' : '';
    }
    return [
      if (dist != null) '$dist ${AppConfig.campusLabel}',
      if (listing.rating != null) '${listing.rating!.toStringAsFixed(1)} ★',
    ].join(' · ');
  }

  String get _byline => listing.isRequest && listing.providerMajor != null
      ? '${listing.providerName} · ${listing.providerMajor}'
      : listing.providerName;

  @override
  Widget build(BuildContext context) {
    final barterOnly =
        !listing.isRequest && !listing.offerType.acceptsPayment;
    return Semantics(
      button: true,
      label: '${listing.title}, $_byline, $_price',
      child: SakuCard(
        onTap: onTap,
        radius: 18,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            _ClayCategoryHeader(listing: listing),
            Row(
              children: [
                InitialsAvatar(name: listing.providerName, size: 22),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _byline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 14 / 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              listing.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _price,
              style: TextStyle(
                fontSize: 13.5,
                height: 18 / 13.5,
                fontWeight: FontWeight.w800,
                fontFeatures: AppTypography.tabular,
                color: barterOnly ? AppColors.barterText : AppColors.primary,
              ),
            ),
            if (_meta.isNotEmpty)
              Text(
                _meta,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 14 / 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            _StatusBox(listing: listing, onChat: onChat),
          ],
        ),
      ),
    );
  }
}

class _ClayCategoryHeader extends StatelessWidget {
  const _ClayCategoryHeader({required this.listing});

  final ServiceListing listing;

  Color _accentFor(ServiceListing item) {
    if (!item.isRequest && !item.offerType.acceptsPayment) {
      return AppColors.barter;
    }
    if (item.isRequest) return AppColors.escrow;
    return switch (item.category) {
      'Desain' => AppColors.primary,
      'Jasa Teknis' => AppColors.escrow,
      'Fotografi' => AppColors.warningText,
      'Bimbingan Belajar' => const Color(0xFF0D9488),
      _ => AppColors.primary,
    };
  }

  static String _iconKey(String category) => switch (category) {
        'Desain' => 'design',
        'Jasa Teknis' => 'tech',
        'Fotografi' => 'photo',
        'Bimbingan Belajar' => 'tutor',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final tint = _accentFor(listing);
    final label = listing.isRequest ? 'Kebutuhan' : listing.category;

    return Row(
      children: [
        ClayIconBadge(
          size: 38,
          radius: 13,
          tint: tint,
          icon: categoryIcon(_iconKey(listing.category)),
          iconSize: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                borderRadius: AppRadius.pillBr,
                border: Border.all(
                  color: tint.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 12 / 9.5,
                  fontWeight: FontWeight.w700,
                  color: tint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.listing, this.onChat});

  final ServiceListing listing;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    if (listing.isRequest) {
      return Semantics(
        button: true,
        child: GestureDetector(
          onTap: onChat,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: const Text(
              'Chat Langsung',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 15 / 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPressed,
              ),
            ),
          ),
        ),
      );
    }
    if (!listing.offerType.acceptsBarter) return const SizedBox.shrink();
    final barterOnly = !listing.offerType.acceptsPayment;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.barterSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.barterBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.swap_horiz_rounded,
            size: 13,
            color: AppColors.barterText,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              barterOnly ? 'Smart Barter' : 'Bisa Barter',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                height: 14 / 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.barterText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
