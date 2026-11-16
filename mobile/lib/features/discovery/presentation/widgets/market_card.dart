import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../domain/entities/service_listing.dart';
import 'discovery_filters.dart';

/// Kartu feed 2 kolom Beranda (Figma "Two-column marketplace feed"):
/// padding 10, jarak 8, radius 14, foto 82 px radius 10.
///
/// Isi menyesuaikan jenis postingan:
/// - Penawaran berbayar → "Rp 50.000", "300m Cibiru · 4.9 ★", badge Bisa Barter
/// - Penawaran barter → "Tukar Jasa Desain Web", "600m dari Anda", Smart Barter
/// - Kebutuhan Proyek → "Budget Rp 50.000", "Butuh 3 Hari", Chat Langsung
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
    return Semantics(
      button: true,
      label: '${listing.title}, $_byline, $_price',
      child: SakuCard(
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            _Cover(listing: listing),
            Text(
              _byline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 14 / 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
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
              style: const TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (_meta.isNotEmpty)
              Text(
                _meta,
                style: const TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
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

class _Cover extends StatelessWidget {
  const _Cover({required this.listing});

  final ServiceListing listing;

  @override
  Widget build(BuildContext context) {
    final asset = listing.coverAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 82,
        width: double.infinity,
        child: asset != null
            ? Image.asset(asset, fit: BoxFit.cover)
            : ColoredBox(
                color: listing.isRequest
                    ? AppColors.escrowSurface
                    : AppColors.primarySurface,
                child: Icon(
                  categoryIcon(_iconKey(listing.category)),
                  size: 32,
                  color: listing.isRequest
                      ? AppColors.escrow
                      : AppColors.primary,
                ),
              ),
      ),
    );
  }

  static String _iconKey(String category) => switch (category) {
        'Desain' => 'design',
        'Jasa Teknis' => 'tech',
        'Fotografi' => 'photo',
        'Bimbingan Belajar' => 'tutor',
        _ => '',
      };
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary),
            ),
            child: const Text(
              'Chat Langsung',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 15 / 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }
    if (!listing.offerType.acceptsBarter) return const SizedBox.shrink();
    final barterOnly = !listing.offerType.acceptsPayment;
    return InfoBox(
      tone: SakuTone.barter,
      padding: const EdgeInsets.all(10),
      child: Text(
        barterOnly ? 'Smart Barter' : 'Bisa Barter',
        textAlign: barterOnly ? TextAlign.start : TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          height: 15 / 11,
          fontWeight: FontWeight.w600,
          color: AppColors.barterText,
        ),
      ),
    );
  }
}
