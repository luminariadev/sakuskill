import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "16 · Kirim hasil kerja" (sisi penyedia).
///
/// Tautan divalidasi seperti URL Sanitizer modul Anggota 6: wajib https.
class SubmitWorkPage extends StatefulWidget {
  const SubmitWorkPage({super.key});

  @override
  State<SubmitWorkPage> createState() => _SubmitWorkPageState();
}

class _SubmitWorkPageState extends State<SubmitWorkPage> {
  final _link = TextEditingController(
    text: 'https://drive.google.com/salma/spanduk-berkah-cibiru-final.pdf',
  );
  bool _confirmed = true;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  bool get _linkValid {
    final uri = Uri.tryParse(_link.text.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final valid = _linkValid;
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Kirim Hasil Pengerjaan'),
        Text('#SK-2026-091',
            style: AppTypography.mono.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        SakuTextField(
          fieldKey: const Key('submit-link'),
          controller: _link,
          label: 'Tautan Berkas Akhir (Google Drive)',
          keyboardType: TextInputType.url,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        ),
        AnimatedSwitcher(
          duration: SakuMotion.base,
          child: InfoBox(
            key: ValueKey(valid),
            text: valid
                ? '✓ Tautan Valid'
                : 'Tautan harus diawali https:// dan mengarah ke berkas yang bisa dibuka klien.',
            tone: valid ? SakuTone.success : SakuTone.danger,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SakuTextField(
          label: 'Catatan Penyelesaian',
          initialValue: 'Halo Pak Dimas, desain spanduk 3×1 m sudah selesai format '
              'CMYK siap cetak. Nomor WhatsApp dan foto menu sudah disesuaikan.',
          minLines: 3,
          maxLines: 6,
        ),
        const Text('Unggah Mockup Screenshot', style: AppTypography.label),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 118,
            width: double.infinity,
            child: Image.asset(DemoAssets.spandukBerkah, fit: BoxFit.cover),
          ),
        ),
        SakuCheckRow(
          value: _confirmed,
          onChanged: (v) => setState(() => _confirmed = v),
          label: 'Saya telah memeriksa hasil pekerjaan dan menyelesaikannya sesuai '
              'instruksi brief.',
          fontSize: 12,
        ),
        SakuButton(
          key: const Key('submit-work'),
          label: 'Ajukan Penyelesaian & Minta Pencairan Dana',
          onPressed: valid && _confirmed
              ? () {
                  SakuMotion.tick();
                  Navigator.of(context).pushReplacementNamed(AppRoutes.reviewWork);
                }
              : null,
        ),
      ],
    );
  }
}
