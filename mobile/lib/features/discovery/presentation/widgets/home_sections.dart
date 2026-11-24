import 'package:flutter/material.dart';

import '../../../auth/data/auth_session.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Header Beranda: "sakuskill." 23/800 · pill saldo clay emerald · clay avatar 38.
class MarketplaceHeader extends StatelessWidget {
  const MarketplaceHeader({
    super.key,
    required this.userName,
    required this.balance,
    this.onBalanceTap,
    this.onAvatarTap,
  });

  final String userName;
  final num balance;
  final VoidCallback? onBalanceTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF0FDF8), Color(0xFFDDFBE9)],
                  ),
                  borderRadius: AppRadius.pillBr,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18059669),
                      offset: Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
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
              child: ValueListenableBuilder<String?>(
                valueListenable: AuthSession.instance.photoUrlNotifier,
                builder: (_, photoUrl, __) => InitialsAvatar(
                  name: userName,
                  size: 38,
                  photoUrl: photoUrl,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolom pencarian kapsul frosted glass-clay dengan tombol peta clay medallion.
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
        child: SakuGlassContainer(
          radius: 999,
          blur: 16,
          tint: AppColors.glassFill,
          borderColor: border ? AppColors.glassBorder : Colors.transparent,
          padding: const EdgeInsets.only(left: 15, right: 6),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SakuIcon(
                  SakuIcons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 16 / 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (onMapTap != null)
                  Tooltip(
                    message: 'Lihat peta Cibiru',
                    child: InkResponse(
                      onTap: onMapTap,
                      radius: 22,
                      child: const ClayIconBadge(
                        size: 34,
                        radius: 17,
                        tint: AppColors.primary,
                        child: SakuIcon(
                          SakuIcons.pin,
                          size: 17,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner gelap clay-glass "Dana Aman Rekening Bersama Escrow".
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
        borderRadius: AppRadius.clayCardBr,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: AppShadows.clayElevated,
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
