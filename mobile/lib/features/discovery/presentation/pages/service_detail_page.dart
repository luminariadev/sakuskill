import 'package:flutter/material.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../domain/entities/service_listing.dart';
import '../widgets/campus_map_widgets.dart';
import '../widgets/discovery_filters.dart';

/// Figma "10 · Detail layanan" — titik masuk ke Chat Diskusi dan
/// Buat Pesanan (escrow) / Ajukan Barter.
class ServiceDetailPage extends StatefulWidget {
  const ServiceDetailPage({super.key, required this.listing});

  final ServiceListing listing;

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  bool _saved = false;

  ServiceListing get listing => widget.listing;

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
        Row(
          spacing: 10,
          children: [
            _MetaAction(
              icon: Icons.share_outlined,
              label: 'Bagikan',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tautan layanan disalin.')),
              ),
            ),
            _MetaAction(
              key: const Key('detail-save'),
              icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              label: _saved ? 'Tersimpan' : 'Simpan',
              color: _saved ? AppColors.primary : AppColors.textSecondary,
              selected: _saved,
              onTap: () {
                SakuMotion.tick();
                setState(() => _saved = !_saved);
              },
            ),
          ],
        ),
        _Gallery(listing: listing),
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PhotoAvatar(
                name: listing.providerName,
                asset: DemoAssets.portraitFor(listing.providerName),
                size: 42,
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
            child: Text(
              listing.barterWant != null
                  ? 'Menerima Barter dengan Jasa ${listing.barterWant}'
                  : 'Menerima Barter dengan keahlian Anda',
              style: const TextStyle(
                fontSize: 12,
                height: 17 / 12,
                fontWeight: FontWeight.w500,
                color: AppColors.barterText,
              ),
            ),
          ),
      ],
    );
  }
}

class _MetaAction extends StatelessWidget {
  const _MetaAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SakuMotion.base,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.cardSurface,
          borderRadius: AppRadius.pillBr,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                height: 15 / 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slider portofolio 176 px beradius 14 + indikator titik (● ○ ○) yang bergeser halus.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.listing});

  final ServiceListing listing;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.listing.galleryAssets.isNotEmpty
        ? widget.listing.galleryAssets
        : [if (widget.listing.coverAsset != null) widget.listing.coverAsset!];

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: AppRadius.cardBr,
        child: Container(
          height: 176,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.mediaGreen, AppColors.deepCanvas],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -28,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 18,
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    categoryIcon(''),
                    size: 32,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: AppRadius.pillBr,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Text(
                    widget.listing.category,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      spacing: 12,
      children: [
        ClipRRect(
          borderRadius: AppRadius.cardBr,
          child: SizedBox(
            height: 176,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Semantics(
                image: true,
                label: 'Foto portofolio ${i + 1} dari ${images.length}',
                child: Image.asset(images[i], fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              for (var i = 0; i < images.length; i++)
                AnimatedContainer(
                  duration: SakuMotion.base,
                  curve: SakuMotion.curve,
                  width: i == _page ? 16 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary, width: 1.2),
                  ),
                ),
            ],
          ),
      ],
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