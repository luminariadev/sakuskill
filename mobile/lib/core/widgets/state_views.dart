import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// Tampilan kosong / error yang konsisten antar-modul.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTypography.subheading, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: AppTypography.body, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Banner kecil: data berasal dari data contoh karena API tidak terjangkau.
class OfflineDataBanner extends StatelessWidget {
  const OfflineDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.integritySurface,
        borderRadius: AppRadius.inputBr,
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Server belum terhubung — menampilkan data contoh sekitar kampus.',
              style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Halaman sementara untuk tab yang dikerjakan anggota tim lain.
class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.owner,
    this.accent = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String owner;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(title, style: AppTypography.display.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.body),
          const SizedBox(height: 48),
          Icon(icon, size: 56, color: accent),
          const SizedBox(height: 16),
          const Text(
            'Modul sedang dikembangkan',
            style: AppTypography.subheading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Penanggung jawab: $owner',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
