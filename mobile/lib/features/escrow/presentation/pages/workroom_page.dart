import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';

/// Figma "15 · Ruang pengerjaan" (sisi penyedia) + "15B · Ajukan tambahan
/// waktu".
class WorkroomPage extends StatefulWidget {
  const WorkroomPage({super.key});

  @override
  State<WorkroomPage> createState() => _WorkroomPageState();
}

class _WorkroomPageState extends State<WorkroomPage> {
  bool _extensionSent = false;

  Future<void> _requestExtension() async {
    final sent = await showSakuSheet<bool>(
      context,
      builder: (_) => const _ExtensionRequestSheet(),
    );
    if (sent == true && mounted) {
      setState(() => _extensionSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan tambahan waktu terkirim ke Pak Dimas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const order = DemoData.order;
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Detail Pengerjaan\nProyek'),
        Text('#SK-2026-091',
            style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        const InfoBox(
          text: 'DANA DITAHAN SIMULASI',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        CountdownCard(
          label: 'EARLY WARNING DEADLINE PENGERJAAN',
          remaining: const Duration(hours: 4, minutes: 32, seconds: 15),
          color: AppColors.warning,
          fontSize: 23,
          note: 'Dana ${formatRupiah(order.amount)} ditahan aman di escrow. Segera '
              'serahkan hasil pengerjaan sebelum deadline.',
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              PersonRow(
                name: 'Dimas · Katering Berkah',
                subtitle: 'Klien · ${order.code}',
                asset: order.clientAsset,
              ),
              const Text(
                'Desain Spanduk Katering 3×1 m',
                style: TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'File Aset: Foto_Ayam_Bakar.jpg',
                style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const Text(
          'Progres Saat Ini: 75% Selesai',
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SakuProgressBar(value: 0.75),
        SakuButton(
          key: const Key('workroom-submit'),
          label: 'Kirim Bukti Hasil Kerja (Deliverable)',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.submitWork),
        ),
        SakuButton(
          label: _extensionSent
              ? 'Menunggu Konfirmasi Pak Dimas'
              : 'Ajukan Perpanjangan Waktu Bersyarat',
          variant: _extensionSent
              ? SakuButtonVariant.disabled
              : SakuButtonVariant.warning,
          onPressed: _extensionSent ? null : _requestExtension,
        ),
      ],
    );
  }
}

class _ExtensionRequestSheet extends StatefulWidget {
  const _ExtensionRequestSheet();

  @override
  State<_ExtensionRequestSheet> createState() => _ExtensionRequestSheetState();
}

class _ExtensionRequestSheetState extends State<_ExtensionRequestSheet> {
  int _choice = 1;
  static const _options = ['+6 Jam', '+12 Jam', '+24 Jam'];

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      fontSize: 12,
      height: 17 / 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    return SakuSheetContent(
      title: 'Ajukan Tambahan Waktu',
      message: 'Ajukan kesepakatan tenggat baru kepada klien sebelum deadline habis:',
      body: [
        InlineChoice(
          options: _options,
          selected: _choice,
          onChanged: (i) => setState(() => _choice = i),
        ),
        const Text('Progres Pengerjaan Saat Ini:', style: label),
        const InfoBox(
          text: '75% Selesai (Draf Desain Utama Sudah Ada)',
          fontWeight: FontWeight.w500,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        SakuTextField(
          label: 'Alasan Permintaan Tambahan Waktu',
          initialValue: 'Halo Pak Dimas, konsep spanduk sudah 75% selesai. Saya '
              'butuh waktu tambahan ${_options[_choice].substring(1).toLowerCase()} '
              'untuk render format CMYK 300 DPI agar cetakan tajam dan tidak pecah.',
          minLines: 3,
          maxLines: 5,
        ),
        const InfoBox(
          text: 'Ketentuan: Jika Pak Dimas menyetujui, batas waktu diperpanjang '
              'otomatis tanpa sanksi. Jika ditolak, timer pengerjaan tetap berjalan '
              'sesuai kesepakatan awal.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ],
      confirmLabel: 'Kirim Permintaan ke Pak Dimas',
      cancelLabel: 'Batal / Kembali',
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
