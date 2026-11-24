import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../../../auth/data/auth_session.dart';
import '../../data/datasources/barter_remote_data_source.dart';
import '../../data/models/barter_model.dart';
import '../widgets/barter_widgets.dart';

/// Figma "24 · Barter selesai" — verifikasi bilateral + ulasan timbal balik
/// (kedua belah pihak bisa saling memberi rating setelah kontrak completed).
class BarterDonePage extends StatefulWidget {
  const BarterDonePage({super.key, this.barter});

  final BarterAgreementModel? barter;

  @override
  State<BarterDonePage> createState() => _BarterDonePageState();
}

class _BarterDonePageState extends State<BarterDonePage> {
  int _stars = 5;
  bool _submitting = false;
  bool _initialized = false;
  late TextEditingController _reviewCtrl;

  BarterAgreementModel? _resolveBarter(BuildContext context) {
    if (widget.barter != null) return widget.barter;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is BarterAgreementModel ? args : null;
  }

  @override
  void initState() {
    super.initState();
    _reviewCtrl = TextEditingController(
      text: AppConfig.useMockData
          ? 'Hasil editing videonya sangat estetik dan tepat waktu. Kolaborasi barter yang luar biasa!'
          : '',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final b = _resolveBarter(context);
    if (b == null && AppConfig.useMockData && _reviewCtrl.text.isEmpty) {
      _reviewCtrl.text =
          'Hasil editing videonya sangat estetik dan tepat waktu. Kolaborasi barter yang luar biasa!';
    }
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview(BarterAgreementModel? b) async {
    if (_submitting) return;
    SakuMotion.tick();

    if (b == null || b.id.isEmpty || AppConfig.useMockData) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.barterHistory);
      return;
    }

    final comment = _reviewCtrl.text.trim();
    if (comment.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis ulasan singkat min. 3 karakter.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await AppScope.of(context).barterDataSource.createReview(
            b.id,
            rating: _stars,
            comment: comment,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terima kasih! Ulasan $_stars★ untuk mitra terkirim.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.barterHistory);
    } on BarterException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'REVIEW_ALREADY_EXISTS'
          ? 'Anda sudah mengirimkan ulasan untuk mitra pada kontrak barter ini.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.orange.shade800),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim ulasan barter: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _resolveBarter(context);
    final myId = (AuthSession.instance.userId ?? '').trim().toLowerCase();
    final pengaju = b?.namaPengaju.isNotEmpty == true ? b!.namaPengaju : DemoData.me;
    final penerima = b?.namaPenerima.isNotEmpty == true
        ? b!.namaPenerima
        : DemoData.barter.partner;
    final partnerName = b != null
        ? (myId == b.pengajuId.trim().toLowerCase() ? penerima : pengaju)
        : DemoData.barter.partner;

    final codeLabel = b != null
        ? '#${b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase()}'
        : '#BTR-2026-012';

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Barter Selesai'),
        Text(
          codeLabel,
          style: const TextStyle(
              fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
        ),
        SakuCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const SwapGlyph(size: 56),
              const InfoBox(
                text: 'STATUS: BARTER SELESAI & TUNTAS',
                fontWeight: FontWeight.w500,
              ),
              const Center(
                child: Text(
                  'Kedua Belah Pihak Telah Mengonfirmasi Selesai!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    height: 31 / 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '✓ $pengaju mengonfirmasi hasil dari $penerima\n'
                '✓ $penerima mengonfirmasi hasil dari $pengaju',
                style: const TextStyle(
                    fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          'Berikan Rating & Ulasan untuk Mitra\n$partnerName',
          style: const TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        StarRating(value: _stars, onChanged: (v) => setState(() => _stars = v)),
        SakuTextField(
          key: const Key('barter-review-input'),
          controller: _reviewCtrl,
          label: 'Ulasan Anda untuk ${partnerName.split(' ').first}',
          hint: 'Ceritakan kualitas hasil & ketepatan waktu kolaborasi mitra...',
          minLines: 3,
          maxLines: 6,
        ),
        SakuButton(
          key: const Key('barter-done-submit'),
          label: _submitting ? 'Mengirim Ulasan...' : 'Kirim Ulasan & Selesaikan Barter',
          variant: SakuButtonVariant.barter,
          onPressed: _submitting ? null : () => _submitReview(b),
        ),
      ],
    );
  }
}
