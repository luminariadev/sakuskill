import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../domain/entities/service_listing.dart';
import '../widgets/campus_map_widgets.dart';
import '../widgets/discovery_filters.dart';

/// Figma "10 · Detail layanan" — titik masuk ke Chat Diskusi dan
/// Buat Pesanan (escrow) / Ajukan Barter.
class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key, required this.listing});

  final ServiceListing listing;

  String get _priceText {
    final price = listing.price;
    if (listing.isRequest) {
      return price != null ? 'Budget ${formatRupiah(price)}' : 'Budget nego';
    }
    if (price == null || !listing.offerType.acceptsPayment) {
      return 'Tukar Keahlian';
    }
    return '${formatRupiah(price)} / Proyek';
  }

  @override
  Widget build(BuildContext context) {
    final d = listing.distanceMeters;
    final meta = [
      if (listing.rating != null)
        '${listing.rating!.toStringAsFixed(1)} ★ (${listing.reviewCount} Ulasan)',
      if (d != null) '${compactDistance(d)} dari Anda',
    ].join(' · ');
    final scope = listing.scopeItems.isNotEmpty
        ? listing.scopeItems
        : [
            listing.description,
            if (listing.deliveryDays != null)
              'Estimasi pengerjaan: ${listing.deliveryDays} Hari',
          ];

    return SakuScreen(
      showBack: true,
      bottomBar: _ActionBar(listing: listing),
      children: [
        Text(
          listing.isRequest ? 'Detail Kebutuhan Proyek' : 'Detail Layanan Jasa',
          style: const TextStyle(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        _ServiceClayHero(listing: listing),
        Text(
          listing.title,
          style: const TextStyle(
            fontSize: 21,
            height: 28 / 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.35,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          _priceText,
          style: TextStyle(
            fontSize: 23,
            height: 30 / 23,
            fontWeight: FontWeight.w800,
            fontFeatures: AppTypography.tabular,
            color: !listing.isRequest && !listing.offerType.acceptsPayment
                ? AppColors.barterText
                : AppColors.primary,
          ),
        ),
        SakuCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              InitialsAvatar(
                name: listing.providerName,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            listing.providerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 18 / 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
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
        ),
        const Text(
          'Deskripsi & Cakupan Brief',
          style: TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          scope.map((s) => '• $s').join('\n'),
          style: const TextStyle(
            fontSize: 13,
            height: 18 / 13,
            color: AppColors.textSecondary,
          ),
        ),
        if (!listing.isRequest && listing.offerType.acceptsBarter)
          InfoBox(
            tone: SakuTone.barter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  listing.barterWant != null
                      ? 'Menerima Barter dengan Jasa ${listing.barterWant}'
                      : 'Menerima Barter dengan keahlian Anda (tanpa uang tunai)',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 17 / 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.barterText,
                  ),
                ),
                if (listing.offerType.acceptsPayment)
                  SakuButton(
                    key: const Key('detail-barter'),
                    label: 'Ajukan Barter (Rp 0)',
                    variant: SakuButtonVariant.barter,
                    height: 42,
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.proposeBarter,
                      arguments: listing,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Ringkasan hero claymorphism kategori layanan (tanpa foto/gambar eksternal).
class _ServiceClayHero extends StatelessWidget {
  const _ServiceClayHero({required this.listing});

  final ServiceListing listing;

  Color _accentColor() {
    if (!listing.isRequest && !listing.offerType.acceptsPayment) {
      return AppColors.barter;
    }
    if (listing.isRequest) return AppColors.escrow;
    return switch (listing.category) {
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
    final tint = _accentColor();
    final modeLabel = listing.isRequest
        ? 'Kebutuhan Proyek'
        : !listing.offerType.acceptsPayment
            ? 'Smart Barter Rp 0'
            : 'Escrow Terproteksi';
    final d = listing.distanceMeters;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, Colors.white, 0.90)!,
            Color.lerp(tint, Colors.white, 0.80)!,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 1.5,
        ),
        boxShadow: AppShadows.clayElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              ClayIconBadge(
                size: 54,
                radius: 18,
                tint: tint,
                icon: categoryIcon(_iconKey(listing.category)),
                iconSize: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HeroGlassPill(label: modeLabel, tint: tint),
                    _HeroGlassPill(
                      label: listing.category,
                      tint: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (listing.deliveryDays != null)
                _HeroGlassPill(
                  icon: Icons.schedule_rounded,
                  label: 'Estimasi ${listing.deliveryDays} Hari',
                  tint: tint,
                ),
              if (d != null)
                _HeroGlassPill(
                  icon: Icons.location_on_outlined,
                  label: '${compactDistance(d)} Cibiru',
                  tint: AppColors.textSecondary,
                ),
              if (listing.rating != null)
                _HeroGlassPill(
                  icon: Icons.star_rounded,
                  label: '${listing.rating!.toStringAsFixed(1)} (${listing.reviewCount})',
                  tint: AppColors.warningText,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroGlassPill extends StatelessWidget {
  const _HeroGlassPill({
    required this.label,
    required this.tint,
    this.icon,
  });

  final String label;
  final Color tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: AppRadius.pillBr,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.94),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Sticky service actions": Chat Diskusi (120) + aksi utama (223).
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.listing});

  final ServiceListing listing;

  @override
  Widget build(BuildContext context) {
    void go(String route) =>
        Navigator.of(context).pushNamed(route, arguments: listing);
    final price = listing.price;
    final canPay =
        !listing.isRequest && listing.offerType.acceptsPayment && price != null;

    final (label, variant, route) = listing.isRequest
        ? ('Kirim Penawaran Jasa', SakuButtonVariant.primary, AppRoutes.chat)
        : canPay
            ? (
                'Buat Pesanan (${formatRupiah(price)})',
                SakuButtonVariant.primary,
                AppRoutes.orderService,
              )
            : (
                'Ajukan Tawaran Barter',
                SakuButtonVariant.barter,
                AppRoutes.proposeBarter,
              );

    return StickyActionBar(
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            flex: 120,
            child: SakuButton(
              key: const Key('detail-chat'),
              label: 'Chat Diskusi',
              variant: SakuButtonVariant.outline,
              onPressed: () => openDirectOrderChat(context, listing),
            ),
          ),
          Expanded(
            flex: 223,
            child: SakuButton(
              key: const Key('detail-order'),
              label: label,
              variant: variant,
              onPressed: () {
                if (listing.isRequest) {
                  openDirectOrderChat(context, listing);
                } else {
                  go(route);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}