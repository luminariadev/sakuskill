import 'package:flutter/material.dart';

import '../motion/saku_motion.dart';
import '../theme/app_colors.dart';

/// Varian tombol dari Figma "00B · Component library / SakuSkill / Button":
/// Primary · Outline · Warning · Destructive · Barter · Disabled.
enum SakuButtonVariant { primary, outline, warning, destructive, barter, disabled }

/// Tombol teks 13/700, radius 8, tinggi default 48.
/// Micro-interaction: skala 0.97 saat ditekan + transisi warna 200 ms.
class SakuButton extends StatelessWidget {
  const SakuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SakuButtonVariant.primary,
    this.height = 48,
    this.fontSize = 13,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final SakuButtonVariant variant;
  final double height;
  final double fontSize;

  /// Lebar penuh (default) atau seukuran konten.
  final bool expand;

  (Color bg, Color fg, Color? border) _colors(bool enabled) {
    if (!enabled) {
      return (AppColors.borderLight, AppColors.textSecondary, null);
    }
    return switch (variant) {
      SakuButtonVariant.primary => (AppColors.primary, Colors.white, null),
      SakuButtonVariant.outline => (
          AppColors.cardSurface,
          AppColors.primary,
          AppColors.primary
        ),
      SakuButtonVariant.warning => (
          AppColors.warningSurface,
          AppColors.warningText,
          AppColors.warningText
        ),
      SakuButtonVariant.destructive => (AppColors.danger, Colors.white, null),
      SakuButtonVariant.barter => (AppColors.barter, Colors.white, null),
      SakuButtonVariant.disabled => (
          AppColors.borderLight,
          AppColors.textSecondary,
          null
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        onPressed != null && variant != SakuButtonVariant.disabled;
    final (bg, fg, border) = _colors(enabled);
    final List<BoxShadow>? buttonShadow = !enabled
        ? null
        : switch (variant) {
            SakuButtonVariant.primary => const [
                BoxShadow(
                  color: Color(0x28059669),
                  offset: Offset(0, 3),
                  blurRadius: 10,
                ),
              ],
            SakuButtonVariant.barter => const [
                BoxShadow(
                  color: Color(0x288B5CF6),
                  offset: Offset(0, 3),
                  blurRadius: 10,
                ),
              ],
            _ => null,
          };

    final body = AnimatedContainer(
      duration: SakuMotion.base,
      curve: SakuMotion.curve,
      height: height,
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: border == null ? null : Border.all(color: border, width: 1.5),
        boxShadow: buttonShadow,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          height: 18 / 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: PressableScale(
        enabled: enabled,
        onTap: enabled ? onPressed : null,
        child: MouseRegion(
          cursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: body,
        ),
      ),
    );
  }
}

/// Tautan teks hijau 12/600 ("Lupa Kata Sandi?", "Masuk di sini").
class SakuTextLink extends StatelessWidget {
  const SakuTextLink(
    this.label, {
    super.key,
    required this.onTap,
    this.color = AppColors.primary,
    this.fontSize = 12,
    this.align = TextAlign.start,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final double fontSize;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: PressableScale(
        onTap: onTap,
        scale: 0.98,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            textAlign: align,
            style: TextStyle(
              fontSize: fontSize,
              height: 17 / 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
