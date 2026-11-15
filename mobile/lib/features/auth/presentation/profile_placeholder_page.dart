import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';

/// Placeholder tab Profil — diganti Anggota 5 (autentikasi & RBAC).
class ProfilePlaceholderPage extends StatelessWidget {
  const ProfilePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderPage(
      title: 'Profil & Akses',
      subtitle: 'Verifikasi mahasiswa & peran RBAC',
      icon: Icons.badge_outlined,
      owner: 'Anggota 5 — Backend & Data (Auth/RBAC)',
    );
  }
}
