import 'package:material_ui/material_ui.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_pill.dart';
import '../../domain/entities/service_listing.dart';
import '../widgets/service_card.dart';

/// Detail layanan — titik masuk ke alur Escrow / Smart Barter (Anggota 4).
class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key, required this.listing});

  final ServiceListing listing;

  @override
  Widget build(BuildContext context) {
    final distance = listing.distanceMeters;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Jasa')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              InitialsAvatar(name: listing.providerName, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.providerName, style: AppTypography.subheading),
                    Text(
                      [
                        listing.providerMajor ?? listing.category,
                        if (listing.rating != null)
                          '★ ${listing.rating!.toStringAsFixed(1)} '
                              '(${listing.reviewCount} Ulasan)',
                      ].join(' • '),
                      style: AppTypography.caption
                          .copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(listing.title, style: AppTypography.heading),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              SakuPill(label: listing.category, tone: SakuPillTone.primary),
              if (listing.offerType.acceptsBarter)
                const SakuPill(
                  label: 'Bisa Barter',
                  icon: Icons.swap_horiz_rounded,
                  tone: SakuPillTone.barter,
                ),
              const SakuPill(
                label: 'Bebas Joki',
                icon: Icons.verified_outlined,
                tone: SakuPillTone.integrity,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            listing.description,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (distance != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.inputBr,
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_walk_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${formatDistance(distance)} dari pusat kampus '
                      '${AppConfig.campusLabel}'
                      '${listing.landmark != null ? ' • dekat ${listing.landmark}' : ''}'
                      ' • jalan kaki ~${walkingMinutes(distance)} menit',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryPressed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          PriceLabel(listing: listing, fontSize: 20),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ServiceActionButtons(listing: listing),
        ),
      ),
    );
  }
}

/// Tombol aksi "Ajak Barter" + "Pesan Jasa" — dipakai di detail & peta.
class ServiceActionButtons extends StatelessWidget {
  const ServiceActionButtons({super.key, required this.listing});

  final ServiceListing listing;

  @override
  Widget build(BuildContext context) {
    final price = listing.price;
    final canPay = listing.offerType.acceptsPayment && price != null;

    final barterButton = OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.barter,
        side: const BorderSide(color: AppColors.barter),
      ),
      onPressed: () => Navigator.of(context).pushNamed(
        AppRoutes.proposeBarter,
        arguments: listing,
      ),
      child: const Text('Ajak Barter'),
    );

    return Row(
      children: [
        if (listing.offerType.acceptsBarter)
          canPay ? barterButton : Expanded(child: barterButton),
        if (listing.offerType.acceptsBarter && canPay) const SizedBox(width: 8),
        if (canPay)
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.orderService,
                arguments: listing,
              ),
              child: Text('Pesan Jasa (${formatRupiah(price)})'),
            ),
          ),
      ],
    );
  }
}
