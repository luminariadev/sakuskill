import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';

/// Figma "26 · Komplain transaksi" — Pusat Bantuan & Komplain.
class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  static const _reasons = [
    'Keterlambatan Melewati Batas Waktu / Hasil Tidak Sesuai',
    'Penyedia tidak merespons chat',
    'Hasil kerja berbeda dari brief',
    'Lainnya',
  ];
  int _reason = 0;
  int _solution = 0;
  String? _evidence = 'Screenshot chat & brief awal';
  final _chronology = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _chronology.dispose();
    super.dispose();
  }

  Future<void> _pickReason() async {
    var selected = _reason;
    final picked = await showSakuSheet<int>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SakuSheetContent(
          title: 'Alasan Komplain',
          body: [
            RadioOptions(
              options: _reasons,
              selected: selected,
              fontSize: 13,
              onChanged: (i) => setSheet(() => selected = i),
            ),
          ],
          confirmLabel: 'Pilih Alasan',
          onConfirm: () => Navigator.of(ctx).pop(selected),
        ),
      ),
    );
    if (picked != null) setState(() => _reason = picked);
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_chronology.text.trim().length < 10) return;
    SakuMotion.tick();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((r) => r.isFirst);
    messenger.showSnackBar(
      const SnackBar(content: Text('Komplain terkirim. Dana dibekukan & Admin akan memediasi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = formatRupiah(DemoData.order.amount);
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pusat Bantuan\n& Komplain'),
        const Text(
          '#SK-2026-091 · Dimas',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        InfoBox(
          text: 'Mengajukan komplain akan membekukan dana transaksi $amount di '
              'rekening escrow dan perkara akan dimediasi oleh tim Admin SakuSkill.',
          tone: SakuTone.danger,
          fontWeight: FontWeight.w500,
        ),
        SakuTextField(
          key: ValueKey('reason-$_reason'),
          label: 'Alasan Komplain',
          initialValue: '${_reasons[_reason]}  ⌄',
          readOnly: true,
          maxLines: 2,
          onTap: _pickReason,
        ),
        SakuTextField(
          fieldKey: const Key('complaint-chronology'),
          controller: _chronology,
          label: 'Kronologi Kejadian',
          hint: 'Jelaskan detail masalah yang Anda alami, termasuk waktu kejadian '
              'dan hasil yang belum sesuai brief.',
          minLines: 3,
          maxLines: 6,
          errorText: _submitted && _chronology.text.trim().length < 10
              ? 'Ceritakan kronologi minimal 10 karakter'
              : null,
          onChanged: (_) {
            if (_submitted) setState(() {});
          },
        ),
        const Text('Solusi yang Diharapkan', style: AppTypography.label),
        SelectableOption(
          title: 'Kembalikan Dana 100% (Refund)',
          selected: _solution == 0,
          onTap: () => setState(() => _solution = 0),
        ),
        SelectableOption(
          title: 'Mediasi Pembagian Dana Damai 50:50',
          selected: _solution == 1,
          onTap: () => setState(() => _solution = 1),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            const Text('Unggah Bukti Pendukung', style: AppTypography.label),
            SakuDropzone(
              title: 'Unggah screenshot atau dokumen',
              subtitle: 'PNG / JPG / PDF maks 5MB',
              fileName: _evidence == null ? null : '↑ $_evidence',
              onTap: () => setState(() =>
                  _evidence = _evidence == null ? 'Screenshot chat & brief awal' : null),
            ),
          ],
        ),
        SakuButton(
          key: const Key('complaint-submit'),
          label: 'Kirim Komplain ke Admin',
          variant: SakuButtonVariant.destructive,
          onPressed: _submit,
        ),
      ],
    );
  }
}
