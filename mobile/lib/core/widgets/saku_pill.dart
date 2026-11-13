import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Varian warna pill sesuai bahasa visual fitur.
enum SakuPillTone { primary, barter, integrity, escrow, dispute, neutral, dark }

/// Pill/badge/filter chip bulat (radius pill dari design system).
/// Bila [onTap] diisi, pill bertindak sebagai tombol filter.
class SakuPill extends StatelessWidget {
  const SakuPill({
    super.key,
    required this.label,
    this.tone = SakuPillTone.neutral,
    this.icon,
    this.selected = false,
    this.onTap,
    this.dense = false,
    this.trailingIcon,
  });

  final String label;
  final SakuPillTone tone;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool selected;
  final bool dense;
  final VoidCallback? onTap;

  (Color bg, Color fg, Color border) _colors() {
    switch (tone) {
      case SakuPillTone.primary:
        return selected
            ? (AppColors.primary, Colors.white, AppColors.primary)
            : (AppColors.primarySurface, AppColors.primaryPressed,
                AppColors.primarySurface);
      case SakuPillTone.barter:
        return selected
            ? (AppColors.barter, Colors.white, AppColors.barter)
            : (AppColors.barterSurface, AppColors.barter,
                AppColors.barterSurface);
      case SakuPillTone.integrity:
        return (AppColors.integritySurface, const Color(0xFFB45309),
            AppColors.integritySurface);
      case SakuPillTone.escrow:
        return (AppColors.escrowSurface, AppColors.escrow,
            AppColors.escrowSurface);
      case SakuPillTone.dispute:
        return (AppColors.disputeSurface, AppColors.dispute,
            AppColors.disputeSurface);
      case SakuPillTone.dark:
        return (AppColors.deepCanvas, Colors.white, AppColors.deepCanvas);
      case SakuPillTone.neutral:
        return selected
            ? (AppColors.primary, Colors.white, AppColors.primary)
            : (AppColors.cardSurface, AppColors.textPrimary,
                AppColors.borderLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors();
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 7);

    final content = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 10 : 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 2),
            Icon(trailingIcon, size: 14, color: fg),
          ],
        ],
      ),
    );

    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: border),
      ),
      child: content,
    );

    if (onTap == null) return decorated;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: onTap,
          child: decorated,
        ),
      ),
    );
  }
}
