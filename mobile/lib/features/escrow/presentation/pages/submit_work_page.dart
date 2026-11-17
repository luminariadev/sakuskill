import 'package:flutter/material.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "16 · Kirim hasil kerja" (sisi penyedia).
///
/// Tautan divalidasi seperti URL Sanitizer modul Anggota 6: wajib https.
class SubmitWorkPage extends StatefulWidget {
  const SubmitWorkPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<SubmitWorkPage> createState() => _SubmitWorkPageState();
}

class _SubmitWorkPageState extends State<SubmitWorkPage> {
  final _link = TextEditingController(
    text: 'https://drive.google.com/salma/spanduk-berkah-cibiru-final.pdf',
  );
  // 2. INTEGRASI: Controller untuk catatan penyelesaian penyedia
  final _notes = TextEditingController(
    text: 'Halo Pak Dimas, desain spanduk 3×1 m sudah selesai format '
        'CMYK siap cetak. Nomor WhatsApp dan foto menu sudah disesuaikan.',
  );
  bool _confirmed = true;
  bool _submitting = false;

  @override
  void dispose() {
    _link.dispose();
    _notes.dispose();
    super.dispose();
  }

  // 1. INTEGRASI: Ambil objek order dari parameter atau argumen navigasi
  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (widget.order != null) return widget.order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  bool get _linkValid {
    final uri = Uri.tryParse(_link.text.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  // 3. INTEGRASI: Kirim hasil kerja ke BE via EscrowRepository.deliverWork
  Future<void> _submitDeliverable(EscrowOrderModel? currentOrder) async {
    if (!_linkValid || !_confirmed || _submitting) return;

    setState(() => _submitting = true);
    SakuMotion.tick();

    final repo = AppScope.of(context).escrowRepository;
    final orderId =
        currentOrder?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
    final cleanLink = _link.text.trim();
    final cleanNotes = _notes.text.trim();

    await repo.requestCompletion(
      orderId: orderId,
      tautanBerkas: cleanLink,
      catatanPenyedia: cleanNotes,
    );

    // 4. INTEGRASI: Perbarui model & teruskan ke halaman review klien
    final updatedOrder = currentOrder?.copyWith(
      statusPesanan: 'Menunggu Review',
      statusEscrow: 'Ditahan (Simulasi)',
      stepperTahap: 3,
      tautanBerkas: cleanLink,
      catatanPenyedia: cleanNotes,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.reviewWork,
      arguments: updatedOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final valid = _linkValid;
    final currentOrder = _resolveOrder(context);
    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Kirim Hasil Pengerjaan'),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
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
        SakuTextField(
          controller: _notes,
          label: 'Catatan Penyelesaian',
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
          label: _submitting
              ? 'Mengirim Hasil Kerja...'
              : 'Ajukan Penyelesaian & Minta Pencairan Dana',
          onPressed: valid && _confirmed && !_submitting
              ? () => _submitDeliverable(currentOrder)
              : null,
        ),
      ],
    );
  }
}