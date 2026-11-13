import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_views.dart';

/// Placeholder tab Barter — diganti Anggota 4 dengan Smart Barter Hub.
class BarterPlaceholderPage extends StatelessWidget {
  const BarterPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderPage(
      title: 'Smart Barter Hub',
      subtitle: 'Pertukaran Keahlian Bilateral Antar-Mahasiswa',
      icon: Icons.swap_horiz_rounded,
      owner: 'Anggota 4 — Frontend Feature (Smart Barter)',
      accent: AppColors.barter,
    );
  }
}
