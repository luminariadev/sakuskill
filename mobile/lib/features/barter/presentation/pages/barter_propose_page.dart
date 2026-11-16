import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "19 · Buat penawaran barter".
class BarterProposePage extends StatefulWidget {
  const BarterProposePage({super.key});

  @override
  State<BarterProposePage> createState() => _BarterProposePageState();
}

class _BarterProposePageState extends State<BarterProposePage> {
  static const _offerOptions = [
    'Desain UI Web / Portofolio Grafis',
    'Desain Feed & Story Instagram',
    'Desain Spanduk Cetak',
  ];
  static const _wantOptions = [
    'Editing Video Teaser Reels / TikTok',
    'Web Frontend (Landing Page)',
    'Fotografi Produk',
  ];
  int _offer = 0;
  int _want = 0;

  Future<void> _pick(String title, List<String> options, int current,
      ValueChanged<int> onPicked) async {
    var selected = current;
    final picked = await showSakuSheet<int>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SakuSheetContent(
          title: title,
          body: [
            RadioOptions(
              options: options,
              selected: selected,
              activeColor: AppColors.barter,
              fontSize: 13,
              onChanged: (i) => setSheet(() => selected = i),
            ),
          ],
          confirmLabel: 'Pilih',
          confirmVariant: SakuButtonVariant.barter,
          onConfirm: () => Navigator.of(ctx).pop(selected),
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      gap: 13,
      children: [
        const PageHeader('Buat Penawaran\nBarter Baru'),
        const Text(
          'Tukar keahlian, tumbuh bersama.',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        SakuTextField(
          key: ValueKey('offer-$_offer'),
          label: 'Jasa yang Saya Tawarkan',
          initialValue: '${_offerOptions[_offer]}  ⌄',
          readOnly: true,
          onTap: () => _pick('Jasa yang Saya Tawarkan', _offerOptions, _offer,
              (i) => setState(() => _offer = i)),
        ),
        SakuTextField(
          key: ValueKey('want-$_want'),
          label: 'Jasa yang Saya Cari / Butuhkan',
          initialValue: '${_wantOptions[_want]}  ⌄',
          readOnly: true,
          onTap: () => _pick('Jasa yang Saya Cari', _wantOptions, _want,
              (i) => setState(() => _want = i)),
        ),
        const SakuTextField(
          label: 'Estimasi Durasi Pengerjaan Bersama',
          initialValue: '4 Hari',
        ),
        const SakuTextField(
          label: 'Deskripsi Rencana Kolaborasi',
          initialValue: 'Saya mencari mitra yang bisa mengedit video teaser 30 detik '
              'untuk portofolio, saya akan membalas dengan mendesain landing page '
              'UI web modern.',
          minLines: 3,
          maxLines: 6,
        ),
        const Text('Lampirkan Portofolio Karya', style: AppTypography.label),
        Row(
          spacing: 11,
          children: [
            for (var i = 0; i < 2; i++)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 100,
                    child: Image.asset(DemoAssets.portfolioWeb, fit: BoxFit.cover),
                  ),
                ),
              ),
          ],
        ),
        SakuButton(
          key: const Key('barter-publish'),
          label: 'Terbitkan Penawaran ke Barter Hub',
          variant: SakuButtonVariant.barter,
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pushReplacementNamed(AppRoutes.barterOffer);
          },
        ),
      ],
    );
  }
}
