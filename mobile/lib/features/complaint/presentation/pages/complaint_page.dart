import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
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
import '../../../auth/data/auth_session.dart';
import '../../../barter/data/models/barter_model.dart';
import '../../../escrow/data/models/escrow_order_model.dart';

/// Figma "26 · Komplain transaksi" — pengajuan komplain terikat langsung ke
/// transaksi nyata (`EscrowOrderModel` atau `BarterAgreementModel`).
class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key, this.target});

  final Object? target;

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  static const _reasons = [
    'Keterlambatan Melewati Batas Waktu / Hasil Tidak Sesuai',
    'Mitra tidak merespons chat dalam waktu wajar',
    'Hasil pekerjaan berbeda dari kesepakatan brief',
    'Lainnya',
  ];

  final _formKey = GlobalKey<FormState>();
  final _chronology = TextEditingController();
  final _evidenceUrl = TextEditingController();
  int _reason = 0;
  int _solution = 0;
  bool _submitted = false;
  bool _submitting = false;

  Object? _resolveTarget(BuildContext context) {
    if (widget.target != null) return widget.target;
    return ModalRoute.of(context)?.settings.arguments;
  }

  @override
  void dispose() {
    _chronology.dispose();
    _evidenceUrl.dispose();
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

  Future<void> _submit({
    required String targetType,
    required String? targetId,
    required bool isBarter,
  }) async {
    setState(() => _submitted = true);
    final validForm = _formKey.currentState?.validate() ?? true;
    final text = _chronology.text.trim();
    if (!validForm || text.length < 10 || _submitting) return;

    SakuMotion.tick();

    final link = _evidenceUrl.text.trim();
    final solutionText = isBarter
        ? 'Mediasi penyelesaian/pembatalan kontrak barter oleh Admin'
        : (_solution == 0
            ? 'Kembalikan Dana 100% (Refund)'
            : 'Mediasi Pembagian Dana Damai 50:50');
    final fullDetails = [
      text,
      'Solusi diharapkan: $solutionText',
      if (link.isNotEmpty) 'Tautan bukti: $link',
    ].join('\n');

    final token = AuthSession.instance.accessToken;
    if (token != null &&
        token.isNotEmpty &&
        targetId != null &&
        targetId.isNotEmpty &&
        !AppConfig.useMockData) {
      setState(() => _submitting = true);
      try {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/reports');
        final res = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'target_tipe': targetType,
                'target_id': targetId,
                'alasan': _reasons[_reason],
                'keterangan': fullDetails,
              }),
            )
            .timeout(AppConfig.networkTimeout);

        if (!mounted) return;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          String errMsg = 'Gagal mengirim komplain (HTTP ${res.statusCode}).';
          try {
            final parsed = jsonDecode(utf8.decode(res.bodyBytes));
            if (parsed is Map && parsed['message'] is String) {
              errMsg = parsed['message'] as String;
            }
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg), backgroundColor: Colors.red.shade700),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim komplain: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isBarter
              ? 'Laporan kendala barter terkirim ke Admin SakuSkill.'
              : 'Komplain terkirim. Dana dibekukan & Admin akan memediasi.',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = _resolveTarget(context);

    if (target == null && !AppConfig.useMockData) {
      return SakuScreen(
        background: AppColors.canvasLight,
        showBack: true,
        children: [
          const PageHeader('Komplain Transaksi'),
          const InfoBox(
            text:
                'Untuk mengajukan komplain atau sengketa, buka pesanan jasa atau proyek Smart Barter terkait di menu Aktivitas Saya, lalu tekan "Ajukan Komplain Transaksi".',
            tone: SakuTone.escrow,
            fontWeight: FontWeight.w500,
          ),
          SakuButton(
            label: 'Kembali',
            variant: SakuButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    final isOrder = target is EscrowOrderModel;
    final isBarter = target is BarterAgreementModel;
    final EscrowOrderModel? order = isOrder ? target : null;
    final BarterAgreementModel? barter = isBarter ? target : null;

    final String headerSubtitle;
    final String bannerText;
    final String targetType;
    final String? targetId;

    if (order != null) {
      final partner = order.namaLawanTransaksi?.isNotEmpty == true
          ? order.namaLawanTransaksi!
          : 'Mitra Transaksi';
      headerSubtitle = '${order.kodePesanan} · $partner';
      bannerText =
          'Mengajukan komplain akan membekukan dana transaksi ${formatRupiah(order.harga)} '
          'di rekening escrow untuk dimediasi Admin SakuSkill.';
      targetType = 'Pesanan';
      targetId = order.orderId;
    } else if (barter != null) {
      final myId = (AuthSession.instance.userId ?? '').trim().toLowerCase();
      final partner = myId == barter.pengajuId.trim().toLowerCase()
          ? barter.namaPenerima
          : barter.namaPengaju;
      final shortId = barter.id
          .substring(0, barter.id.length > 8 ? 8 : barter.id.length)
          .toUpperCase();
      headerSubtitle = '#BTR-$shortId · ${partner.isEmpty ? 'Mitra Barter' : partner}';
      bannerText =
          'Mengajukan laporan sengketa Smart Barter (Rp 0) untuk ditinjau & dimediasi tim Admin SakuSkill.';
      targetType = 'Barter';
      targetId = barter.id;
    } else {
      final amount = formatRupiah(DemoData.order.amount);
      headerSubtitle = '${DemoData.order.code} · ${DemoData.order.client.split(' ').first}';
      bannerText =
          'Mengajukan komplain akan membekukan dana transaksi $amount di '
          'rekening escrow dan perkara akan dimediasi oleh tim Admin SakuSkill.';
      targetType = 'Pesanan';
      targetId = null;
    }

    return Form(
      key: _formKey,
      child: SakuScreen(
        background: AppColors.canvasLight,
        showBack: true,
        children: [
          const PageHeader('Ajukan Komplain\nTransaksi'),
          Text(
            headerSubtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 17 / 12,
              color: AppColors.textSecondary,
            ),
          ),
          InfoBox(
            text: bannerText,
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
            hint:
                'Jelaskan detail kendala yang Anda alami, termasuk waktu kejadian '
                'dan ketidaksesuaian dengan brief/kesepakatan.',
            minLines: 3,
            maxLines: 6,
            errorText: _submitted && _chronology.text.trim().length < 10
                ? 'Ceritakan kronologi minimal 10 karakter'
                : null,
            onChanged: (_) {
              if (_submitted) setState(() {});
            },
          ),
          if (!isBarter) ...[
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
          ],
          SakuTextField(
            key: const Key('complaint-evidence-link'),
            controller: _evidenceUrl,
            label: 'Tautan Bukti Pendukung (Opsional)',
            hint: 'https://drive.google.com/... (screenshot chat / hasil kerja)',
            keyboardType: TextInputType.url,
            validator: SakuValidators.optional(SakuValidators.httpsUrl()),
          ),
          SakuButton(
            key: const Key('complaint-submit'),
            label: _submitting ? 'Mengirim Komplain...' : 'Kirim Komplain ke Admin',
            variant: SakuButtonVariant.destructive,
            onPressed: _submitting
                ? null
                : () => _submit(
                      targetType: targetType,
                      targetId: targetId,
                      isBarter: isBarter,
                    ),
          ),
        ],
      ),
    );
  }
}
