import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../widgets/barter_widgets.dart';

/// Figma "24B · Riwayat barter" — kontrak barter yang sudah tuntas.
class BarterHistoryPage extends StatefulWidget {
  const BarterHistoryPage({super.key});

  @override
  State<BarterHistoryPage> createState() => _BarterHistoryPageState();
}

class _BarterHistoryPageState extends State<BarterHistoryPage> {
  int _filter = 3; // 0 Semua · 1 Berjalan · 2 Menunggu · 3 Selesai

  @override
  Widget build(BuildContext context) {
    const barter = DemoData.barter;
    const filters = [
      'Semua (3)',
      'Sedang Berjalan (1)',
      'Menunggu Konfirmasi (1)',
      '✓ Selesai Barter (1)',
    ];
    Widget filterText(int i) => GestureDetector(
          onTap: () => setState(() => _filter = i),
          child: Text(
            filters[i],
            style: TextStyle(
              fontSize: 11,
              height: 15 / 11,
              fontWeight: i == _filter ? FontWeight.w700 : FontWeight.w500,
              color: i == _filter ? AppColors.barterText : AppColors.textSecondary,
            ),
          ),
        );
    const bold = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Kontrak Barter Saya'),
        const Text(
          'Riwayat pertukaran keahlian tanpa uang tunai',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(children: [filterText(0), const Text('   ·   '), filterText(1)]),
            filterText(2),
            StatusStrip(
              filters[3],
              tone: _filter == 3 ? SakuTone.barter : SakuTone.neutral,
              textColor: AppColors.barterText,
              onTap: () => setState(() => _filter = 3),
            ),
          ],
        ),
        if (_filter == 1 || _filter == 0)
          StatusStrip(
            'Kontrak ${barter.code} · Pengerjaan bersama 75% / 60%  ›',
            tone: SakuTone.barter,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.barterWorkroom),
          ),
        if (_filter == 2 || _filter == 0)
          StatusStrip(
            'Permintaan dari Salma · Menunggu konfirmasi Anda  ›',
            tone: SakuTone.warning,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.barterIncoming),
          ),
        if (_filter == 3 || _filter == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: AppRadius.cardBr,
              border: Border.all(color: AppColors.barterBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                const Text(
                  'KONTRAK #BTR-2026-012',
                  style: TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.barterText,
                  ),
                ),
                const InfoBox(text: '✓ BARTER SELESAI & TUNTAS', fontWeight: FontWeight.w500),
                const Text(
                  '12 November 2026\nVerifikasi Bilateral Berhasil',
                  style: TextStyle(fontSize: 11, height: 15 / 11, color: AppColors.textSecondary),
                ),
                const Text('Desain UI Web Landing Page\n✓ Diterima Rizkia', style: bold),
                const SwapGlyph(size: 28),
                const Text('Editing Video Reels 30 Detik\n✓ Diterima Salma', style: bold),
                InfoBox(
                  tone: SakuTone.neutral,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      PersonRow(
                        name: barter.partner,
                        subtitle: 'Penilaian: ★★★★★ (5.0)',
                        asset: barter.partnerAsset,
                      ),
                      const Text(
                        '“Desain landing page portofolio dari Salma sangat estetik dan '
                        'rapi. Terima kasih banyak!”',
                        style: TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                SakuButton(
                  label: 'Lihat Berkas Video dari Rizkia',
                  variant: SakuButtonVariant.barter,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Membuka berkas video...')),
                  ),
                ),
                SakuButton(
                  label: 'Buka Arsip Chat Diskusi',
                  variant: SakuButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.barterChat),
                ),
              ],
            ),
          ),
        const InfoBox(
          text: 'Seluruh kontrak pada filter ini telah tuntas disepakati kedua pihak '
              'tanpa melibatkan uang tunai (100% barter skill murni).',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}
