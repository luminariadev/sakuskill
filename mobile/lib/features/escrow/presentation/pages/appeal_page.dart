import 'package:material_ui/material_ui.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "15E · Banding kompensasi" (sisi penyedia setelah dibatalkan).
class AppealPage extends StatefulWidget {
  const AppealPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<AppealPage> createState() => _AppealPageState();
}

class _AppealPageState extends State<AppealPage> {
  final _progressCtrl = TextEditingController(
    text: '80% Selesai (Draf Utama Siap Pakai)',
  );
  final _linkCtrl = TextEditingController(
    text: 'https://drive.google.com/salma/draf-spanduk-80percent.pdf',
  );
  final _chronologyCtrl = TextEditingController(
    text: 'Saya sudah menyelesaikan 80% desain sebelum pembatalan '
        'terjadi. File sudah dapat digunakan klien. Mohon pembagian '
        'kompensasi 50:50.',
  );

  bool _submitting = false;

  @override
  void dispose() {
    _progressCtrl.dispose();
    _linkCtrl.dispose();
    _chronologyCtrl.dispose();
    super.dispose();
  }

  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (widget.order != null) return widget.order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  int _parseProgressPercent() {
    final match = RegExp(r'\d+').firstMatch(_progressCtrl.text);
    final parsed = match != null ? int.tryParse(match.group(0)!) : null;
    if (parsed != null && parsed >= 0 && parsed <= 100) return parsed;
    return 80;
  }

  Future<void> _submitAppeal(EscrowOrderModel? currentOrder) async {
    if (_submitting) return;
    if (_chronologyCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kronologi banding minimal 5 karakter.')),
      );
      return;
    }

    final orderId = currentOrder?.orderId;
    if (orderId == null || orderId.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Simulasi: Banding terkirim (Status: Dalam Sengketa). Admin Mediasi akan meninjau.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    SakuMotion.tick();

    try {
      await AppScope.of(context).escrowRepository.submitAppeal(
            orderId: orderId,
            alasan: _chronologyCtrl.text.trim(),
            progresPersen: _parseProgressPercent(),
            tautanBukti: _linkCtrl.text.trim(),
          );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Banding terkirim (Status: Dalam Sengketa). Admin Mediasi akan meninjau.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentOrder = _resolveOrder(context);
    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Banding Pembatalan\nPesanan'),
        Text(
          orderCode,
          style: const TextStyle(
            fontSize: 11,
            height: 15 / 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        InfoBox(
          text:
              'Pesanan $orderCode dibatalkan klien karena keterlambatan. Jika Anda '
              'telah mengerjakan > 70% pekerjaan, Anda berhak mengajukan banding ke '
              'Admin untuk kompensasi damai 50:50.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        SakuTextField(
          controller: _progressCtrl,
          label: 'Estimasi Progres Kerja',
        ),
        SakuTextField(
          controller: _linkCtrl,
          label: 'Tautan Berkas Kerja',
          keyboardType: TextInputType.url,
          maxLines: 3,
        ),
        const Text(
          'Unggah Screenshot Layer Kerja',
          style: TextStyle(
            fontSize: 12,
            height: 17 / 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Row(
          spacing: 9,
          children: [
            Expanded(child: _LayerScreenshot()),
            Expanded(child: _LayerScreenshot()),
          ],
        ),
        SakuTextField(
          controller: _chronologyCtrl,
          label: 'Kronologi',
          minLines: 3,
          maxLines: 6,
        ),
        SakuButton(
          key: const Key('appeal-submit'),
          label: _submitting
              ? 'Mengirim Banding...'
              : 'Kirim Permohonan Banding 50:50 ke Admin',
          onPressed: _submitting ? null : () => _submitAppeal(currentOrder),
        ),
      ],
    );
  }
}

class _LayerScreenshot extends StatelessWidget {
  const _LayerScreenshot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Screenshot layer kerja spanduk Katering Berkah',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 112,
          color: AppColors.cardSlate,
          child: Column(
            children: [
              Container(height: 14, color: AppColors.borderSlate),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 9, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        spacing: 8,
                        children: [
                          for (var i = 0; i < 4; i++)
                            Container(
                              width: 42,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.fromLTRB(8, 12, 4, 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'KATERING\nBERKAH',
                            style: TextStyle(
                              fontSize: 11,
                              height: 15 / 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}