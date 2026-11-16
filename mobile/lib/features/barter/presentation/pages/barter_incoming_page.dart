import 'package:flutter/material.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../widgets/barter_widgets.dart';

/// Figma "21 · Permintaan barter masuk" (sisi mitra) + "21B · Tolak barter".
class BarterIncomingPage extends StatelessWidget {
  const BarterIncomingPage({super.key});

  Future<void> _reject(BuildContext context) async {
    final rejected = await showSakuSheet<bool>(
      context,
      builder: (_) => const _RejectBarterSheet(),
    );
    if (rejected == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Tawaran barter ditolak. Salma sudah diberi tahu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const big = TextStyle(
      fontSize: 19,
      height: 27 / 19,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Permintaan Barter\nMasuk'),
        const Text(
          '#BTR-2026-012',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        const SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              PersonRow(
                name: 'Salma Nur Oktavia',
                subtitle: 'Desainer Grafis · Cibiru',
                asset: DemoAssets.salma,
              ),
              Text('Desain UI Web Portofolio', style: big),
              SwapGlyph(size: 28),
              Text('Editing Video Reels Anda', style: big),
              InfoBox(
                text: 'Halo Rizkia, mari kita tukar karya untuk portofolio bersama.',
                tone: SakuTone.neutral,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
        SakuButton(
          key: const Key('barter-accept'),
          label: 'Terima Permintaan Barter',
          variant: SakuButtonVariant.barter,
          onPressed: () {
            SakuMotion.tick();
            Navigator.of(context).pushReplacementNamed(AppRoutes.barterChat);
          },
        ),
        SakuButton(
          label: 'Tolak Permintaan',
          variant: SakuButtonVariant.destructive,
          onPressed: () => _reject(context),
        ),
        const InfoBox(
          text: 'Barter hanya dimulai setelah ruang lingkup dan tenggat disepakati '
              'kedua pihak.',
          tone: SakuTone.barter,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}

class _RejectBarterSheet extends StatefulWidget {
  const _RejectBarterSheet();

  @override
  State<_RejectBarterSheet> createState() => _RejectBarterSheetState();
}

class _RejectBarterSheetState extends State<_RejectBarterSheet> {
  int _reason = 0;

  @override
  Widget build(BuildContext context) {
    return SakuSheetContent(
      title: 'Tolak Tawaran Barter Ini?',
      message: 'Beri tahu Salma alasan Anda belum dapat bertukar keahlian saat ini:',
      body: [
        RadioOptions(
          options: const [
            'Saat ini saya sedang tidak membutuhkan jasa desain UI web',
            'Kapasitas editing video saya sudah penuh minggu ini',
            'Portofolio yang ditawarkan belum sesuai kebutuhan saya',
            'Lainnya...',
          ],
          selected: _reason,
          onChanged: (i) => setState(() => _reason = i),
        ),
        const SakuTextField(
          label: 'Pesan opsional',
          hint: 'Pesan opsional untuk Salma...',
          minLines: 2,
          maxLines: 4,
        ),
      ],
      confirmLabel: 'Konfirmasi Tolak Barter',
      confirmVariant: SakuButtonVariant.destructive,
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
