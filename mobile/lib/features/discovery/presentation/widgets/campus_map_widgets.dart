import 'package:flutter/material.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../escrow/data/datasources/escrow_remote_data_source.dart';
import '../../../escrow/data/models/escrow_order_model.dart';
import '../../domain/entities/service_listing.dart';
import 'service_card.dart';

/// Membuka ruang chat order asli berdasarkan [listing]:
/// 1. Cari order aktif milik pengguna untuk `listing.id` (atau nama penyedia).
/// 2. Jika belum ada, buat pesanan awal (`requested`) di backend agar room chat tersimpan.
Future<void> openDirectOrderChat(
  BuildContext context,
  ServiceListing listing,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final repo = AppScope.of(context).escrowRepository;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  EscrowOrderModel? targetOrder;
  try {
    final ordersRes = await repo.fetchMyOrders(peran: 'pelanggan');
    const terminalStatuses = {'completed', 'rejected', 'cancelled'};

    for (final o in ordersRes.data) {
      if (terminalStatuses.contains(o.statusKode)) continue;
      final sameListing = o.listingId != null && o.listingId == listing.id;
      final sameProvider = (o.namaLawanTransaksi ?? '').toLowerCase() ==
          listing.providerName.toLowerCase();
      if (sameListing || sameProvider) {
        targetOrder = o;
        break;
      }
    }

    if (targetOrder == null && listing.id.isNotEmpty) {
      final createdRes = await repo.createOrder(
        listingId: listing.id,
        deskripsiKebutuhan: 'Diskusi brief awal: ${listing.title}',
        hargaDisepakati: listing.price?.round() ?? 50000,
        durasiHari: listing.deliveryDays ?? 3,
        catatanKlien: 'Memulai diskusi melalui Chat Langsung.',
      );
      if (!createdRes.isFallback) {
        targetOrder = createdRes.data;
      }
    }
  } on EscrowException catch (e) {
    if (navigator.canPop()) navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return;
  } catch (_) {
    // Bila mode demo / offline, lanjut ke fallback
  }

  if (navigator.canPop()) navigator.pop();
  navigator.pushNamed(
    AppRoutes.orderChat,
    arguments: targetOrder ?? listing,
  );
}

/// Jarak ringkas tanpa spasi, mis. "600m" / "1.2km".
String compactDistance(double meters) =>
    formatDistance(meters).replaceAll(' ', '');

/// Ukuran marker talenta (Figma "Salma · 300m": 128 × 34).
const Size talentMarkerSize = Size(128, 34);

/// Marker pill di peta (Figma "6 · Explore Cibiru"): hijau untuk penyedia
/// jasa, biru untuk permintaan kebutuhan; teks putih 11/700 "Nama · jarak".
/// Marker terpilih sedikit membesar dengan bayangan.
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
    final d = listing.distanceMeters;
    final label = d != null ? '$firstName · ${compactDistance(d)}' : firstName;
    final color = listing.isRequest ? AppColors.escrow : AppColors.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: '${listing.isRequest ? 'Permintaan' : 'Penyedia'} $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          SakuMotion.tick();
          onTap();
        },
        child: AnimatedScale(
          scale: selected ? 1.06 : 1,
          duration: SakuMotion.base,
          curve: SakuMotion.curve,
          child: AnimatedContainer(
            duration: SakuMotion.base,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? Colors.white : color,
                width: selected ? 2 : 0,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : AppShadows.flat,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 15 / 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label area kampus di atas peta ("UIN SUNAN GUNUNG DJATI").
class CampusMapLabel extends StatelessWidget {
  const CampusMapLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: Text(
          'UIN SUNAN GUNUNG DJATI',
          style: TextStyle(
            fontSize: 10,
            height: 14 / 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            shadows: [Shadow(color: Colors.white, blurRadius: 6)],
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

/// Kartu talenta terpilih (Figma "Selected talent card"): padding 16,
/// radius 14, avatar 40, harga 16/700, tombol 42 px.
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
    final d = listing.distanceMeters;
    final meta = [
      if (d != null) '${compactDistance(d)} dari lokasi Anda',
      if (listing.rating != null)
        '${listing.rating!.toStringAsFixed(1)} ★ (${listing.reviewCount} Ulasan)',
    ].join(' · ');

    return SakuCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            children: [
              PhotoAvatar(
                name: listing.providerName,
                asset: DemoAssets.portraitFor(listing.providerName),
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(
                      listing.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
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
          if (listing.isRequest)
            Text(
              listing.price != null
                  ? 'Budget ${formatRupiah(listing.price!)}'
                  : 'Budget nego',
              style: const TextStyle(
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            )
          else
            PriceLabel(listing: listing, fontSize: 16, color: AppColors.primary),
          if (meta.isNotEmpty)
            Text(
              meta,
              style: const TextStyle(
                fontSize: 11,
                height: 15 / 11,
                color: AppColors.textSecondary,
              ),
            ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: SakuButton(
                  key: const Key('map-chat'),
                  label: 'Chat Langsung',
                  variant: SakuButtonVariant.outline,
                  height: 42,
                  onPressed: () => openDirectOrderChat(context, listing),
                ),
              ),
              Expanded(
                child: SakuButton(
                  key: const Key('map-open-detail'),
                  label: listing.isRequest ? 'Lihat Kebutuhan' : 'Lihat Detail Jasa',
                  height: 42,
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