import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';

/// Placeholder tab Orders — diganti Anggota 4 dengan halaman Escrow Ledger.
class OrdersPlaceholderPage extends StatelessWidget {
  const OrdersPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderPage(
      title: 'Escrow Ledger',
      subtitle: 'Sistem Rekening Bersama Mahasiswa',
      icon: Icons.verified_user_outlined,
      owner: 'Anggota 4 — Frontend Feature (Escrow)',
      accent: AppColors.escrow,
    );
  }
}
