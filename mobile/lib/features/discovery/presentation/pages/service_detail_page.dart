import 'package:flutter/material.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../domain/entities/service_listing.dart';
import '../widgets/campus_map_widgets.dart';
import '../widgets/discovery_filters.dart';

/// Figma "Detail layanan" (section Proses Layanan) — titik masuk ke alur
/// Chat & Nego, Smart Barter, dan Order via Escrow (Anggota 4).
class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key, required this.listing});

  final ServiceListing listing;

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature segera hadir.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = listing.distanceMeters;
    final providerMeta = [
      if (listing.rating != null)
        '${listing.rating!.toStringAsFixed(1)} ★ (${listing.reviewCount} Ulasan)',
      if (distance != null) '${compactDistance(distance)} dari Anda',
    ].join(' · ');

    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const SakuIcon(
                      SakuIcons.back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Bagikan',
                    onPressed: () => _soon(context, 'Bagikan layanan'),
                    icon: const SakuIcon(
                      SakuIcons.share,
                      color: AppColors.textBody,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Simpan',
                    onPressed: () => _soon(context, 'Simpan layanan'),
                    icon: const SakuIcon(
                      SakuIcons.bookmark,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                children: [
                  ServiceMediaBanner(listing: listing),
                  const SizedBox(height: 23),
                  Text(listing.title, style: AppTypography.title),
                  const SizedBox(height: 12),
                  _PriceRow(listing: listing),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      InitialsAvatar(name: listing.providerName, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.providerName,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (providerMeta.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                providerMeta,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 15 / 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Tentang layanan',
                    style: TextStyle(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    listing.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 18 / 13,
                      color: AppColors.textBody,
                    ),
                  ),
                  if (listing.offerType.acceptsBarter) ...[
                    const SizedBox(height: 26),
                    const _BarterInfoBox(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _DetailActionBar(listing: listing),
        ),
      ),
    );
  }
}

/// Banner media layanan (194px, radius 12). Selama backend belum
/// menyediakan foto portofolio, tampil sebagai sampul tipografis dari
/// nama keahlian & kategori.
class ServiceMediaBanner extends StatelessWidget {
  const ServiceMediaBanner({super.key, required this.listing});

  final ServiceListing listing;

  static String _iconKey(String category) => switch (category) {
        'Desain' => 'design',
        'Jasa Teknis' => 'tech',
        'Fotografi' => 'photo',
        'Bimbingan Belajar' => 'tutor',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 194,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.mediaGreen,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(
              categoryIcon(_iconKey(listing.category)),
              size: 170,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    listing.skillName.toUpperCase(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 30 / 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mediaHighlight,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  listing.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    height: 11 / 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primarySurface,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  listing.providerName,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 14 / 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.listing});

  final ServiceListing listing;

  @override
  Widget build(BuildContext context) {
    final price = listing.price;
    if (price == null || !listing.offerType.acceptsPayment) {
      return const Text(
        'Tukar keahlian',
        style: TextStyle(
          fontSize: 24,
          height: 34 / 24,
          fontWeight: FontWeight.w700,
          color: AppColors.barterText,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatRupiah(price),
          style: const TextStyle(
            fontSize: 24,
            height: 34 / 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '/ Proyek',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Kotak ungu "Menerima Barter".
class _BarterInfoBox extends StatelessWidget {
  const _BarterInfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 14),
      decoration: BoxDecoration(
        color: AppColors.barterSurface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: AppColors.barterBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SakuIcon(SakuIcons.swap, size: 20, color: AppColors.barter),
              SizedBox(width: 10),
              Text(
                'Menerima Barter',
                style: TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.barterText,
                ),
              ),
            ],
          ),
          SizedBox(height: 11),
          Text(
            'Penyedia bersedia menukar jasa ini dengan keahlianmu\n'
            'melalui Smart Barter.',
            style: TextStyle(
              fontSize: 11,
              height: 15 / 11,
              color: AppColors.barterText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar aksi bawah: Chat & Nego · Ajak Barter · Order via Escrow (tinggi 52).
class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({required this.listing});

  final ServiceListing listing;

  @override
  Widget build(BuildContext context) {
    final price = listing.price;
    final canPay = listing.offerType.acceptsPayment && price != null;
    void go(String route) =>
        Navigator.of(context).pushNamed(route, arguments: listing);

    return Row(
      children: [
        Expanded(
          flex: 106,
          child: SakuButton(
            key: const Key('detail-chat'),
            label: 'Chat & Nego',
            variant: SakuButtonVariant.outline,
            height: 52,
            onPressed: () => go(AppRoutes.chat),
          ),
        ),
        if (listing.offerType.acceptsBarter) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 100,
            child: SakuButton(
              key: const Key('detail-barter'),
              label: 'Ajak Barter',
              variant: SakuButtonVariant.barter,
              height: 52,
              onPressed: () => go(AppRoutes.proposeBarter),
            ),
          ),
        ],
        if (canPay) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 139,
            child: SakuButton(
              key: const Key('detail-order'),
              label: 'Order via Escrow\n${formatRupiah(price)}',
              height: 52,
              onPressed: () => go(AppRoutes.orderService),
            ),
          ),
        ],
      ],
    );
  }
}
