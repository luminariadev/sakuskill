import 'package:flutter/material.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/state/account_finance_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
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
  bool _syncedFinance = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_syncedFinance) {
      _syncedFinance = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AccountFinanceStore.instance.refreshLive(
          escrowRepository: AppScope.of(context).escrowRepository,
        );
      });
    }
  }

  Future<void> _confirmLogout() async {
    if (_loggingOut) return;
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
      final auth = AppScope.of(context).authRepository;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      setState(() => _loggingOut = true);
      try {
        await auth.logout();
        AuthSession.instance.clear();
        AccountFinanceStore.instance.resetForLogout();
        if (!mounted) return;
        SakuMotion.tick();
        messenger.showSnackBar(
          const SnackBar(content: Text('Anda telah berhasil keluar dari akun.')),
        );
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (_) => false,
        );
      } finally {
        if (mounted) setState(() => _loggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSession.instance;
    final userName = session.userName ?? 'Mahasiswa SakuSkill';
    final userEmail = session.userEmail ?? '';
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
          // Header Kartu Profil (Claymorphism + Foto Profil / Avatar Inisial)
          SakuCard(
            radius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.profileSetup),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ValueListenableBuilder<String?>(
                            valueListenable: AuthSession.instance.photoUrlNotifier,
                            builder: (_, photoUrl, __) => InitialsAvatar(
                              name: userName,
                              size: 64,
                              photoUrl: photoUrl,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          if (userEmail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
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
                const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
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

          // Ringkasan Dompet & Aktivitas (tersinkronisasi penuh)
          ListenableBuilder(
            listenable: AccountFinanceStore.instance,
            builder: (context, _) {
              final finance = AccountFinanceStore.instance;
              return Row(
                children: [
                  Expanded(
                    child: SakuCard(
                      radius: 16,
                      padding: const EdgeInsets.all(14),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.wallet),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo Escrow',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatRupiah(finance.availableBalance),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SakuCard(
                      radius: 16,
                      padding: const EdgeInsets.all(14),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.myServices),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jasa Ditawarkan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${finance.myServiceCount} Layanan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Menu Navigasi
          const Text(
            'PENGATURAN & LAYANAN',
            style: AppTypography.eyebrow,
          ),
          const SizedBox(height: 8),

          SakuCard(
            radius: 20,
            padding: EdgeInsets.zero,
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
                  title: 'Pusat Bantuan & Panduan',
                  subtitle: 'Cara transaksi aman & riwayat komplain Anda',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.helpCenter),
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
      leading: ClayIconBadge(
        size: 38,
        radius: 12,
        tint: AppColors.primary,
        icon: icon,
        iconSize: 20,
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
