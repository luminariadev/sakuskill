import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_pill.dart';

/// Header brand: "sakuskill • UIN SGD" + avatar pengguna.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.userName, this.onAvatarTap});

  final String userName;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'sakuskill',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const SakuPill(label: 'UIN SGD', tone: SakuPillTone.primary),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Profil',
          child: GestureDetector(
            onTap: onAvatarTap,
            child: InitialsAvatar(name: userName),
          ),
        ),
      ],
    );
  }
}

/// Kolom pencarian Home (bertindak sebagai tombol menuju halaman pencarian).
class SearchEntryField extends StatelessWidget {
  const SearchEntryField({
    super.key,
    required this.onTap,
    required this.onLocationTap,
    this.hint = 'Cari jasa, cth: ‘desain poster’...',
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
              const SizedBox(width: 13),
              const Icon(Icons.search_rounded,
                  size: 22, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Lihat peta kampus',
                onPressed: onLocationTap,
                icon: const Icon(
                  Icons.location_on_outlined,
                  size: 22,
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

/// Banner gelap "Rekening Bersama Mahasiswa" (janji escrow kampus).
class EscrowPromiseBanner extends StatelessWidget {
  const EscrowPromiseBanner({super.key});

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
        children: [
          Text(
            'REKENING BERSAMA MAHASISWA',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Transaksi Aman & Terlindungi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Dana dicairkan hanya setelah bukti\npengerjaan disetujui.',
            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFFCBD5E1)),
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
        Expanded(
          child: Text(title, style: AppTypography.subheading.copyWith(fontSize: 17)),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
