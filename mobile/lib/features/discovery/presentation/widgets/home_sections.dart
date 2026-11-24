import 'package:flutter/material.dart';

import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Header Beranda (Figma "5 · Beranda marketplace / Marketplace header"):
/// "sakuskill." 23/800 · pill saldo emerald · avatar foto 36.
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
      height: 42,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'sakuskill.',
              style: TextStyle(
                fontSize: 23,
                height: 30 / 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
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
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadius.pillBr,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SakuIcon(
                      SakuIcons.wallet,
                      size: 14,
                      color: AppColors.primaryPressed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatRupiah(balance),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: AppTypography.tabular,
                        color: AppColors.primaryPressed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppRadius.pillBr,
            border: border ? Border.all(color: AppColors.borderLight) : null,
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              const SakuIcon(SakuIcons.search, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (onMapTap != null)
                IconButton(
                  tooltip: 'Lihat peta Cibiru',
                  onPressed: onMapTap,
                  icon: const SakuIcon(SakuIcons.pin, size: 20, color: AppColors.primary),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepCanvas, AppColors.deepForestAccent],
        ),
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: const SakuIcon(
                  SakuIcons.shield,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: AppRadius.pillBr,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Text(
                  'ESCROW TERPROTEKSI',
                  style: TextStyle(
                    fontSize: 9.5,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const Text(
            'Dana Aman Rekening Bersama Escrow',
            style: TextStyle(
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
          ),
          const Text(
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
