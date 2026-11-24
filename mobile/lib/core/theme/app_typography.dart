import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Skala tipografi dari Figma "User Design / 00 · Design guide" (03 Type
/// system): Display 32/40/800 · Title 24/30/800 · Heading 1 20/26/700 ·
/// Heading 2 16/22/600 · Body large 14/20/500 · Body 13/18/400 ·
/// Caption 11/16/600. Data/ID memakai JetBrains Mono 12.
///
/// Font utama: **Plus Jakarta Sans** (PRD T-04), dibundel di `assets/fonts/`
/// dan dipasang global lewat `AppTheme`. Data/ID memakai JetBrains Mono 12.
abstract final class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';
  static const String monoFamily = 'JetBrainsMono';

  /// Fitur OpenType tabular agar nominal harga, saldo & timer stabil saat berdetak.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7,
    color: AppColors.textPrimary,
  );
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Judul halaman 26–28/800 (layar auth & alur transaksi).
  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 36 / 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );
  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
    color: AppColors.textPrimary,
  );
  static const TextStyle subheading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Label field form (12/600).
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 17 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  /// Overline hijau "LANGKAH PROFIL" (11/700).
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 15 / 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 13 / 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );
  static const TextStyle mono = TextStyle(
    fontFamily: monoFamily,
    fontFamilyFallback: ['monospace'],
    fontSize: 12,
    height: 17 / 12,
    color: AppColors.primary,
  );

  static TextTheme get textTheme => const TextTheme(
        displaySmall: display,
        headlineMedium: title,
        headlineSmall: heading,
        titleMedium: subheading,
        titleSmall: bodyLarge,
        bodyLarge: bodyLarge,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: caption,
        labelSmall: overline,
      );
}
