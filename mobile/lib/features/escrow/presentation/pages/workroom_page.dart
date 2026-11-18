import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
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

/// Figma "15 · Ruang pengerjaan" (sisi penyedia) + "15B · Ajukan tambahan waktu".
class WorkroomPage extends StatefulWidget {
  const WorkroomPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<WorkroomPage> createState() => _WorkroomPageState();
}

class _WorkroomPageState extends State<WorkroomPage> {
  EscrowOrderModel? _order;
  bool _initialized = false;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _order = widget.order ?? (args is EscrowOrderModel ? args : null);
    _syncOrderDetail();
  }

  Future<void> _syncOrderDetail() async {
    final id = _order?.orderId;
    if (id == null || id.isEmpty) return;

    final res =
        await AppScope.of(context).escrowRepository.fetchOrderDetail(id);
    if (!mounted) return;
    if (!res.isFallback) {
      setState(() => _order = res.data);
    }
  }

  Future<void> _requestExtension() async {
    final current = _order;
    final clientName = current?.namaLawanTransaksi ?? 'Pelanggan';
    final clientFirst = clientName.split(' ').first;

    final payload = await showSakuSheet<({int hours, String reason})>(
      context,
      builder: (_) => _ExtensionRequestSheet(clientFirstName: clientFirst),
    );
    if (payload == null || !mounted || _submitting) return;

    if (current == null || current.orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permintaan tambahan waktu terkirim ke $clientFirst.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final res =
          await AppScope.of(context).escrowRepository.requestTimeExtension(
                orderId: current.orderId,
                tambahanJam: payload.hours,
                alasan: payload.reason,
                progresPersen: 75,
              );
      if (!mounted) return;
      setState(() => _order = res.data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permintaan tambahan waktu +${payload.hours} jam terkirim ke $clientFirst.',
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
    const demo = DemoData.order;
    final current = _order;

    final orderCode = current?.kodePesanan ?? '#SK-2026-091';
    final amount = current?.harga ?? demo.amount;
    final clientName = current?.namaLawanTransaksi ?? 'Dimas · Katering Berkah';
    final clientFirst = clientName.split(' ').first;
    final serviceTitle =
        current?.judulLayanan ?? 'Desain Spanduk Katering 3×1 m';
    final attachmentInfo =
        current?.lampiranKlien ?? current?.catatanBrief ?? 'File Aset: Foto_Ayam_Bakar.jpg';

    final remainingSeconds = current?.detikTersisa ??
        const Duration(hours: 4, minutes: 32, seconds: 15).inSeconds;
    final remaining = Duration(seconds: remainingSeconds.clamp(0, 31536000));

    final ext = current?.activeTimeExtension;
    final isExtensionPending = ext?.isPending ?? false;
    final isExtensionApproved = ext?.isApproved ?? false;

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Detail Pengerjaan\nProyek'),
        Text(
          orderCode,
          style: AppTypography.mono.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        InfoBox(
          text: (current?.statusEscrow ?? 'DANA DITAHAN SIMULASI').toUpperCase(),
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        CountdownCard(
          label: 'EARLY WARNING DEADLINE PENGERJAAN',
          remaining: remaining,
          color: AppColors.warning,
          fontSize: 23,
          note:
              'Dana ${formatRupiah(amount)} ditahan aman di escrow. Segera '
              'serahkan hasil pengerjaan sebelum deadline.',
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              PersonRow(
                name: clientName,
                subtitle: 'Klien · $orderCode',
                asset: demo.clientAsset,
              ),
              Text(
                serviceTitle,
                style: const TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                attachmentInfo,
                style: const TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: AppColors.textSecondary,
                ),
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
          onPressed: () => Navigator.of(context).pushNamed(
            AppRoutes.submitWork,
            arguments: current,
          ),
        ),
        SakuButton(
          label: _submitting
              ? 'Mengirim Permintaan...'
              : isExtensionPending
                  ? 'Menunggu Konfirmasi $clientFirst (+${ext!.tambahanJam} Jam)'
                  : isExtensionApproved
                      ? 'Tambahan Waktu +${ext!.tambahanJam} Jam Disetujui'
                      : 'Ajukan Perpanjangan Waktu Bersyarat',
          variant: (isExtensionPending || _submitting)
              ? SakuButtonVariant.disabled
              : SakuButtonVariant.warning,
          onPressed:
              (isExtensionPending || _submitting) ? null : _requestExtension,
        ),
      ],
    );
  }
}

class _ExtensionRequestSheet extends StatefulWidget {
  const _ExtensionRequestSheet({required this.clientFirstName});

  final String clientFirstName;

  @override
  State<_ExtensionRequestSheet> createState() => _ExtensionRequestSheetState();
}

class _ExtensionRequestSheetState extends State<_ExtensionRequestSheet> {
  int _choice = 1;
  static const _options = ['+6 Jam', '+12 Jam', '+24 Jam'];
  static const _hoursValues = [6, 12, 24];
  late final TextEditingController _reasonCtrl;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController(
      text:
          'Halo ${widget.clientFirstName}, pengerjaan sudah 75% selesai. Saya butuh waktu tambahan 12 jam untuk penyempurnaan akhir agar hasil maksimal.',
    );
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

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
      message:
          'Ajukan kesepakatan tenggat baru kepada klien sebelum deadline habis:',
      body: [
        InlineChoice(
          options: _options,
          selected: _choice,
          onChanged: (i) {
            setState(() => _choice = i);
            _reasonCtrl.text =
                'Halo ${widget.clientFirstName}, pengerjaan sudah 75% selesai. Saya butuh waktu tambahan ${_hoursValues[i]} jam untuk penyempurnaan akhir agar hasil maksimal.';
          },
        ),
        const Text('Progres Pengerjaan Saat Ini:', style: label),
        const InfoBox(
          text: '75% Selesai (Draf Utama Sudah Ada)',
          fontWeight: FontWeight.w500,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        SakuTextField(
          label: 'Alasan Permintaan Tambahan Waktu',
          controller: _reasonCtrl,
          minLines: 3,
          maxLines: 5,
        ),
        InfoBox(
          text:
              'Ketentuan: Jika ${widget.clientFirstName} menyetujui, batas waktu diperpanjang '
              'otomatis tanpa sanksi. Jika ditolak, timer pengerjaan tetap berjalan '
              'sesuai kesepakatan awal.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ],
      confirmLabel: 'Kirim Permintaan ke ${widget.clientFirstName}',
      cancelLabel: 'Batal / Kembali',
      onConfirm: () => Navigator.of(context).pop((
        hours: _hoursValues[_choice],
        reason: _reasonCtrl.text.trim(),
      )),
    );
  }
}