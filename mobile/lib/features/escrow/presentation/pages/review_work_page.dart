import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
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
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "17 · Pemeriksaan hasil kerja" (sisi klien) + "17B · Ajukan revisi".
class ReviewWorkPage extends StatefulWidget {
  const ReviewWorkPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<ReviewWorkPage> createState() => _ReviewWorkPageState();
}

class _ReviewWorkPageState extends State<ReviewWorkPage> {
  EscrowOrderModel? _order;
  bool _initialized = false;
  bool _processing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _order = widget.order ?? (args is EscrowOrderModel ? args : null);
    _syncLatestDetail();
  }

  Future<void> _syncLatestDetail() async {
    final targetId = _order?.orderId;
    if (targetId == null || targetId.isEmpty) return;

    final result = await AppScope.of(context).escrowRepository
        .fetchOrderDetail(targetId);
    if (!mounted) return;
    if (!result.isFallback || _order == null) {
      setState(() => _order = result.data);
    }
  }

  /// Konfirmasi selesai & lepas dana escrow ke penyedia (POST /orders/:id/complete)
  Future<void> _approveAndRelease() async {
    if (_processing) return;
    setState(() => _processing = true);
    SakuMotion.tick();

    final repo = AppScope.of(context).escrowRepository;
    final orderId = _order?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';

    try {
      await repo.confirmCompletion(orderId);
      final latestRes = await repo.fetchOrderDetail(orderId);
      final completedOrder = latestRes.isFallback
          ? _order?.copyWith(
              statusKode: 'completed',
              statusPesanan: 'Selesai',
              statusEscrow: 'Dana Dilepas ke Penyedia (Simulasi)',
              stepperTahap: 4,
            )
          : latestRes.data;

      if (!mounted) return;
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.orderDone, arguments: completedOrder);
    } on EscrowException catch (e) {
      if (!mounted) return;
      final pesan = e.code == 'INVALID_STATE_TRANSITION'
          ? 'Penyedia jasa belum mengajukan penyelesaian pekerjaan.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.red.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengonfirmasi penyelesaian: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  /// Ajukan revisi hasil kerja (Simulasi Lokal sesuai kontrak v1.3)
  Future<void> _requestRevision(int remainingQuota, String providerName) async {
    if (_processing) return;

    final notes = await showSakuSheet<String>(
      context,
      builder: (_) => _RevisionSheet(
        remainingQuota: remainingQuota,
        providerName: providerName,
      ),
    );

    if (notes == null || !mounted) return;

    setState(() => _processing = true);
    final repo = AppScope.of(context).escrowRepository;
    final orderId = _order?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';

    try {
      await repo.requestRevision(orderId: orderId, catatanRevisi: notes);

      if (!mounted) return;
      setState(() {
        final currentUsed = _order?.revisiTerpakai ?? 0;
        final maxRev = _order?.batasRevisi ?? 2;
        final nextUsed = (currentUsed + 1).clamp(0, maxRev);
        _order = _order?.copyWith(
          statusPesanan: 'Revisi Diajukan (Simulasi)',
          revisiTerpakai: nextUsed,
          sisaRevisi: (maxRev - nextUsed).clamp(0, maxRev),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Catatan revisi terkirim ke $providerName (Simulasi Lokal).',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const demo = DemoData.order;
    final currentOrder = _order;

    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final serviceTitle =
        currentOrder?.judulLayanan ?? 'Desain Spanduk Toko Katering Berkah';
    final amount = currentOrder?.harga ?? demo.amount;
    final providerName = currentOrder?.namaLawanTransaksi ?? demo.provider;
    final providerFirstName = providerName.split(' ').first;
    final deliverableLink =
        currentOrder?.tautanBerkas ??
        'https://drive.google.com/file/d/spanduk-berkah-cmyk-final';
    final providerNotes =
        currentOrder?.catatanPenyedia ??
        'File sudah siap cetak ukuran 3×1 meter (CMYK 300 DPI). Silakan dicek dulu ya!';
    final remainingRevision = currentOrder?.sisaRevisi ?? 2;

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Pemeriksaan Hasil Kerja'),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        InfoBox(
          text: 'DANA DITAHAN AMAN (SIMULASI) · ${formatRupiah(amount)}',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w600,
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                serviceTitle,
                style: const TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              PersonRow(
                name: providerName,
                subtitle: 'Penyedia Jasa',
                asset: demo.providerAsset,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  currentOrder?.mockupUrl ?? DemoAssets.spandukBerkah,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const Text(
                'TAUTAN BERKAS HASIL KERJA',
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              InfoBox(
                text: deliverableLink,
                tone: SakuTone.neutral,
                fontWeight: FontWeight.w500,
              ),
              const Text(
                'CATATAN DARI PENYEDIA',
                style: TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                providerNotes,
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SakuButton(
          key: const Key('review-approve'),
          label: _processing
              ? 'Memproses Pelepasan Dana...'
              : 'Setujui Hasil & Lepas Dana (${formatRupiah(amount)})',
          onPressed: _processing ? null : _approveAndRelease,
        ),
        if (remainingRevision > 0)
          SakuButton(
            key: const Key('review-revision'),
            label: 'Ajukan Revisi (Sisa Kuota: $remainingRevision×)',
            variant: SakuButtonVariant.outline,
            onPressed: _processing
                ? null
                : () => _requestRevision(remainingRevision, providerFirstName),
          ),
        const InfoBox(
          text: 'Pastikan Anda telah memeriksa tautan berkas di atas sebelum melepas dana simulasi.',
          tone: SakuTone.neutral,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}

class _RevisionSheet extends StatefulWidget {
  const _RevisionSheet({
    required this.remainingQuota,
    required this.providerName,
  });

  final int remainingQuota;
  final String providerName;

  @override
  State<_RevisionSheet> createState() => _RevisionSheetState();
}

class _RevisionSheetState extends State<_RevisionSheet> {
  final _notesCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SakuSheetContent(
      title: 'Ajukan Revisi Hasil Kerja',
      message:
          'Sisa kuota revisi Anda: ${widget.remainingQuota}×. Tuliskan bagian yang perlu '
          'diperbaiki oleh ${widget.providerName}:',
      body: [
        SakuTextField(
          controller: _notesCtrl,
          label: 'Detail Catatan Revisi',
          hint: 'Contoh: Tolong perbesar tulisan nomor WhatsApp di bagian bawah...',
          minLines: 3,
          maxLines: 5,
          errorText: _submitted && _notesCtrl.text.trim().isEmpty
              ? 'Catatan revisi wajib diisi'
              : null,
          onChanged: (_) => setState(() {}),
        ),
      ],
      confirmLabel: 'Kirim Permintaan Revisi',
      cancelLabel: 'Batal',
      onConfirm: () {
        setState(() => _submitted = true);
        final text = _notesCtrl.text.trim();
        if (text.isEmpty) return;
        Navigator.of(context).pop(text);
      },
    );
  }
}
