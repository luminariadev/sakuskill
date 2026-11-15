import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_icon.dart';

/// Header Beranda (Figma "Beranda"): wordmark "sakuskill." + lonceng
/// notifikasi + avatar pengguna 36px.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.userName,
    this.onAvatarTap,
    this.onNotificationsTap,
  });

  final String userName;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SakuWordmark()),
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: onNotificationsTap,
          icon: const SakuIcon(
            SakuIcons.bell,
            size: 22,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: 'Profil',
          child: GestureDetector(
            onTap: onAvatarTap,
            // TODO(anggota-5): ganti dengan foto profil dari sesi autentikasi.
            child: InitialsAvatar(name: userName, size: 36),
          ),
        ),
      ],
    );
  }
}

/// Wordmark "sakuskill." — huruf "l" terakhir berwarna emerald (26/800).
class SakuWordmark extends StatelessWidget {
  const SakuWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'sakuskill',
      excludeSemantics: true,
      child: const Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 26,
            height: 36 / 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          children: [
            TextSpan(text: 'sakuskil'),
            TextSpan(text: 'l', style: TextStyle(color: AppColors.primary)),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

/// Baris lokasi pengguna + saldo dompet di bawah header.
class LocationBalanceRow extends StatelessWidget {
  const LocationBalanceRow({
    super.key,
    required this.locationLabel,
    required this.balance,
  });

  final String locationLabel;
  final num balance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SakuIcon(SakuIcons.pin, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            locationLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 15 / 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          'Saldo ${formatRupiah(balance)}',
          style: const TextStyle(
            fontSize: 11,
            height: 15 / 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Kolom pencarian Beranda (bertindak sebagai tombol menuju halaman
/// pencarian). Ikon pin di kanan membuka peta kampus.
class SearchEntryField extends StatelessWidget {
  const SearchEntryField({
    super.key,
    required this.onTap,
    required this.onLocationTap,
    this.hint = 'Cari jasa desain, servis, editing video...',
  });

  final VoidCallback onTap;
  final VoidCallback onLocationTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.inputBr,
        side: BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        key: const Key('home-search-field'),
        borderRadius: AppRadius.inputBr,
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Row(
            children: [
              const SizedBox(width: 11),
              const SakuIcon(
                SakuIcons.search,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Lihat peta kampus',
                onPressed: onLocationTap,
                icon: const SakuIcon(
                  SakuIcons.pin,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner gelap "Rekening bersama" (janji escrow) — Figma "Beranda".
class EscrowPromiseBanner extends StatelessWidget {
  const EscrowPromiseBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.deepCanvas,
        borderRadius: AppRadius.cardBr,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 3),
                child: SakuIcon(
                  SakuIcons.shield,
                  size: 26,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Aman dari awal\nsampai hasil disetujui.',
                  style: TextStyle(
                    fontSize: 18,
                    height: 25 / 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Text(
            'Pembayaran ditampung sistem melalui\nRekening Bersama (Escrow).',
            style: TextStyle(
              fontSize: 11,
              height: 15 / 11,
              color: AppColors.bannerBody,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.heading)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// Tombol mengambang "AI Price Estimator" (modul Anggota 6).
class AiEstimatorButton extends StatelessWidget {
  const AiEstimatorButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.pillBr,
        boxShadow: AppShadows.emeraldGlow,
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
        label: const Text('AI Price Estimator'),
      ),
    );
  }
}
