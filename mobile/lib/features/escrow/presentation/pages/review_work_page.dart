import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_assets.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "17 · Pemeriksaan hasil" (sisi klien).
class ReviewWorkPage extends StatefulWidget {
  const ReviewWorkPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<ReviewWorkPage> createState() => _ReviewWorkPageState();
}

class _ReviewWorkPageState extends State<ReviewWorkPage> {
  EscrowOrderModel? _order;
  bool _initialized = false;
  int _revisionsLeft = 1;
  bool _processing = false;

  // 1. INTEGRASI: Ambil order dari SubmitWorkPage & sinkronkan deliverable dari BE
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _order = widget.order ?? (args is EscrowOrderModel ? args : null);
    if (_order != null) {
      _revisionsLeft = _order!.sisaRevisi;
    }
    _syncLatestDetail();
  }

  Future<void> _syncLatestDetail() async {
    final targetId = _order?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';
    final result =
        await AppScope.of(context).escrowRepository.fetchOrderDetail(targetId);
    if (!mounted) return;
    if (!result.isFallback || _order == null) {
      setState(() {
        _order = result.data;
        _revisionsLeft = result.data.sisaRevisi;
      });
    }
  }

  // 2. INTEGRASI: Konfirmasi selesai -> ubah status dana menjadi Dilepas (Simulasi)
  Future<void> _approveAndRelease() async {
    if (_processing) return;
    setState(() => _processing = true);
    SakuMotion.tick();

    final repo = AppScope.of(context).escrowRepository;
    final orderId = _order?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';

    await repo.releaseFund(orderId);

    final completedOrder = _order?.copyWith(
      statusPesanan: 'Selesai',
      statusEscrow: 'Dilepas (Simulasi)',
      stepperTahap: 4,
    );

    if (!mounted) return;
    setState(() => _processing = false);

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.orderDone,
      arguments: completedOrder,
    );
  }

  // 3. INTEGRASI: Kirim permintaan revisi ke BE via EscrowRepository.requestRevision
  Future<void> _requestRevision(String providerFirstName) async {
    if (_revisionsLeft == 0 || _processing) return;
    setState(() => _processing = true);

    final repo = AppScope.of(context).escrowRepository;
    final orderId = _order?.orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d';

    await repo.requestRevision(
      orderId: orderId,
      catatanRevisi: 'Mohon penyesuaian minor sesuai catatan pada brief.',
    );

    if (!mounted) return;
    setState(() {
      _processing = false;
      _revisionsLeft = (_revisionsLeft - 1).clamp(0, 99);
      if (_order != null) {
        _order = _order!.copyWith(
          statusPesanan: 'Revisi',
          sisaRevisi: _revisionsLeft,
          revisiTerpakai: _order!.revisiTerpakai + 1,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Permintaan revisi ringan dikirim ke $providerFirstName.',
        ),
      ),
    );
  }

  // 4. INTEGRASI: Masuk alur sengketa -> dana tetap ditahan dalam status Dalam Sengketa
  void _openDispute() {
    final disputedOrder = _order?.copyWith(
      statusPesanan: 'Dalam Sengketa',
      statusEscrow: 'Dalam Sengketa',
    );
    Navigator.of(context).pushNamed(
      AppRoutes.complaint,
      arguments: disputedOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentOrder = _order;
    final rawAmount = currentOrder?.harga ?? DemoData.order.amount;
    final amount = formatRupiah(rawAmount);
    final orderCode = currentOrder?.kodePesanan ?? '#SK-2026-091';
    final providerFirstName =
        currentOrder?.namaLawanTransaksi?.split(' ').first ?? 'Salma';
    final driveLink = currentOrder?.tautanBerkas ??
        'https://drive.google.com/salma/spanduk-berkah-cibiru-final.pdf';
    final fileName = Uri.tryParse(driveLink)?.pathSegments.isNotEmpty == true
        ? Uri.parse(driveLink).pathSegments.last
        : 'Spanduk_Katering_Berkah_Final.pdf';
    final providerNote = currentOrder?.catatanPenyedia ??
        'File sudah siap cetak format CMYK 300 DPI Pak Dimas.';

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.canvasLight,
            borderRadius: AppRadius.cardBr,
            border: Border.all(color: AppColors.accent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                '34 MB · PDF siap cetak',
                style: TextStyle(
                  fontSize: 11,
                  height: 15 / 11,
                  color: AppColors.textSecondary,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 112,
                  width: double.infinity,
                  child: Image.asset(DemoAssets.spandukBerkah, fit: BoxFit.cover),
                ),
              ),
              SakuButton(
                label: 'Buka Tautan Google Drive',
                variant: SakuButtonVariant.outline,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Membuka tautan: $driveLink')),
                ),
              ),
              Text(
                'Catatan $providerFirstName',
                style: const TextStyle(
                  fontSize: 11,
                  height: 15 / 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                providerNote,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SakuButton(
          key: const Key('review-approve'),
          label: _processing
              ? 'Melepas Dana Escrow...'
              : 'Konfirmasi Selesai & Lepas Dana Simulasi ($amount)',
          onPressed: _processing ? null : _approveAndRelease,
        ),
        SakuButton(
          label: 'Ajukan Komplain (Masuk Status Sengketa)',
          variant: SakuButtonVariant.destructive,
          onPressed: _processing ? null : _openDispute,
        ),
        Center(
          child: SakuTextLink(
            _revisionsLeft > 0
                ? 'Minta Revisi Ringan (Sisa ${_revisionsLeft}x)'
                : 'Kuota revisi ringan sudah habis',
            fontSize: 13,
            color:
                _revisionsLeft > 0 ? AppColors.primary : AppColors.textSecondary,
            onTap: () => _requestRevision(providerFirstName),
          ),
        ),
        const InfoBox(
          text:
              'Periksa seluruh berkas sebelum menyetujui. Dana baru dilepas setelah '
              'Anda konfirmasi.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}