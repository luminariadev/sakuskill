import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Skala tipografi dari Figma "Panduan visual":
/// Display 28/800 · Heading 20/700 · Subheading 16/600 · Body 14/500 ·
/// Body 13/400 · Caption 11/600 · Badge 9.
///
/// Font desain: Plus Jakarta Sans. Selama file font belum ditambahkan ke
/// `assets/fonts/` + `pubspec.yaml`, Flutter memakai font default platform
/// (fallback aman — layout tetap sama).
abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';

  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const TextStyle heading = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    height: 13 / 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  static TextTheme get textTheme => const TextTheme(
        displaySmall: display,
        headlineSmall: heading,
        titleMedium: subheading,
        titleSmall: bodyLarge,
        bodyLarge: bodyLarge,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: caption,
        labelSmall: overline,
      );
}
