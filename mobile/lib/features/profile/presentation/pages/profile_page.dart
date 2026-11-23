import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_assets.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';

/// Halaman Profil Pengguna & Pengaturan Akun SakuSkill.
/// Menampilkan identitas mahasiswa, status KTM, saldo dompet, menu navigasi,
/// dan aksi Logout (Keluar Akun) dengan konfirmasi.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loggingOut = false;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar Akun'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun SakuSkill pada perangkat ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AuthSession.instance.clear();
      SakuMotion.tick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda telah berhasil keluar dari akun.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSession.instance;
    final userName = session.userName ?? 'Salma Nur Oktavia';
    final userEmail = session.userEmail ?? 'salma@gmail.com';
    final userRole = session.userRole ?? 'Mahasiswa Dual-Mode';

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: const Text(
          'Profil & Akun',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header Kartu Profil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    PhotoAvatar(
                      name: userName,
                      asset: DemoAssets.salma,
                      size: 64,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              userRole,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'KTM Terverifikasi · UIN Sunan Gunung Djati Bandung',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Ringkasan Dompet & Aktivitas
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.wallet),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Saldo Escrow',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rp 450.000',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PressableScale(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.myServices),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Jasa Ditawarkan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '3 Layanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Menu Navigasi
          const Text(
            'PENGATURAN & LAYANAN',
            style: AppTypography.eyebrow,
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.edit_note_rounded,
                  title: 'Lengkapi & Edit Profil',
                  subtitle: 'Bio, portofolio, keahlian yang ditawarkan',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.profileSetup),
                ),
                const Divider(height: 1, indent: 56),
                _buildMenuItem(
                  icon: Icons.design_services_outlined,
                  title: 'Kelola Jasa Saya',
                  subtitle: 'Katalog jasa, tarif, dan portofolio gig',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.myServices),
                ),
                const Divider(height: 1, indent: 56),
                _buildMenuItem(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Riwayat Smart Barter',
                  subtitle: 'Tukar keahlian tanpa biaya uang',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.barterHistory),
                ),
                const Divider(height: 1, indent: 56),
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Dompet & Transaksi Escrow',
                  subtitle: 'Riwayat pembayaran aman dan pencairan saldo',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.wallet),
                ),
                const Divider(height: 1, indent: 56),
                _buildMenuItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Pusat Bantuan & Pengaduan',
                  subtitle: 'Laporkan kendala transaksi atau joki ilegal',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.complaint),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tombol Keluar Akun (Logout)
          SakuButton(
            key: const Key('profile-logout-button'),
            label: 'Keluar dari Akun',
            variant: SakuButtonVariant.destructive,
            onPressed: _confirmLogout,
          ),

          const SizedBox(height: 12),
          const Center(
            child: Text(
              'SakuSkill v1.0.0 · Platform Escrow Mahasiswa Kampus',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
