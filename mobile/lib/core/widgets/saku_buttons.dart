import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Varian tombol dari Figma "UI component library":
/// Button / Primary · Button / Outline · Button / Barter.
enum SakuButtonVariant { primary, outline, barter }

/// Tombol teks 12/700, radius 8. Tinggi mengikuti konteks layar
/// (34 di kartu peta, 52 di bar aksi detail layanan).
class SakuButton extends StatelessWidget {
  const SakuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SakuButtonVariant.primary,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final SakuButtonVariant variant;
  final double height;

  static const TextStyle _text = TextStyle(
    fontSize: 12,
    height: 17 / 12,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    final size = WidgetStatePropertyAll(Size(0, height));
    const padding = WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12),
    );
    const shape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.inputBr),
    );

    switch (variant) {
      case SakuButtonVariant.outline:
        return OutlinedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: size,
            padding: padding,
            shape: shape,
            textStyle: const WidgetStatePropertyAll(_text),
            backgroundColor: const WidgetStatePropertyAll(AppColors.cardSurface),
            foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
            side: const WidgetStatePropertyAll(
              BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          child: child,
        );
      case SakuButtonVariant.primary:
      case SakuButtonVariant.barter:
        return FilledButton(
          onPressed: onPressed,
          style: ButtonStyle(
            minimumSize: size,
            padding: padding,
            shape: shape,
            textStyle: const WidgetStatePropertyAll(_text),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            backgroundColor: WidgetStatePropertyAll(
              variant == SakuButtonVariant.barter
                  ? AppColors.barter
                  : AppColors.primary,
            ),
          ),
          child: child,
        );
    }
  }
}
