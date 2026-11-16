import 'package:material_ui/material_ui.dart';

import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Header Beranda (Figma "5 · Beranda marketplace / Marketplace header"):
/// "sakuskill." 23/800 · saldo 12/700 emerald · avatar foto 36.
class MarketplaceHeader extends StatelessWidget {
  const MarketplaceHeader({
    super.key,
    required this.userName,
    required this.balance,
    this.avatarAsset,
    this.onBalanceTap,
    this.onAvatarTap,
  });

  final String userName;
  final num balance;
  final String? avatarAsset;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'sakuskill.',
              style: TextStyle(
                fontSize: 23,
                height: 32 / 23,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Saldo dompet ${formatRupiah(balance)}',
            excludeSemantics: true,
            child: PressableScale(
              key: const Key('home-balance'),
              onTap: onBalanceTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  formatRupiah(balance),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 17 / 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 30),
          Semantics(
            button: true,
            label: 'Profil $userName',
            excludeSemantics: true,
            child: PressableScale(
              scale: 0.94,
              onTap: onAvatarTap,
              child: PhotoAvatar(name: userName, asset: avatarAsset, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolom pencarian pill (Figma "Search with map"): putih, border, tinggi 46,
/// ikon cari 22 kiri, ikon pin emerald kanan (membuka peta).
class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    required this.hint,
    required this.onTap,
    this.onMapTap,
    this.border = true,
  });

  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onMapTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hint,
      child: PressableScale(
        scale: 0.985,
        key: const Key('home-search-field'),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.only(left: 13, right: 4),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppRadius.pillBr,
            border: border ? Border.all(color: AppColors.borderLight) : null,
            boxShadow: border ? null : AppShadows.flat,
          ),
          child: Row(
            children: [
              const SakuIcon(SakuIcons.search, size: 22, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (onMapTap != null)
                IconButton(
                  tooltip: 'Lihat peta Cibiru',
                  onPressed: onMapTap,
                  icon: const SakuIcon(SakuIcons.pin, size: 22, color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner gelap "Dana Aman Rekening Bersama Escrow".
class EscrowSecurityBanner extends StatelessWidget {
  const EscrowSecurityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.deepCanvas,
        borderRadius: AppRadius.cardBr,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          SakuIcon(SakuIcons.shield, size: 26, color: AppColors.accent),
          Text(
            'Dana Aman Rekening Bersama Escrow',
            style: TextStyle(
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            'Uang Anda ditahan sistem secara aman dan HANYA dicairkan setelah '
            'hasil pekerjaan disetujui.',
            style: TextStyle(
              fontSize: 12,
              height: 17 / 12,
              color: AppColors.bannerBody,
            ),
          ),
        ],
      ),
    );
  }
}

/// Judul bagian 18/700 ("Temukan keahlian di sekitarmu").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              height: 25 / 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
