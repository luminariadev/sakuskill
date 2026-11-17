import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../discovery/domain/entities/service_listing.dart';
import '../../data/datasources/escrow_remote_data_source.dart';

/// Figma "11 · Buat pesanan jasa" (sisi klien).
class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({super.key, this.listing});

  /// Layanan yang dipesan; null = data demo pesanan #SK-091.
  final ServiceListing? listing;

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  final _title = TextEditingController(
    text: 'Desain Spanduk Toko Ukuran 3×1 Meter',
  );
  late final TextEditingController _duration;
  final _notes = TextEditingController(
    text: 'Warna cerah hijau kuning, tolong cantumkan logo menu '
        'ayam bakar dan no WhatsApp katering.',
  );

  String? _file = 'Foto_Ayam_Bakar.jpg (3 MB)';
  bool _submitted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final defaultDays =
        widget.listing?.deliveryDays ?? DemoData.order.deadlineDays;
    _duration = TextEditingController(text: '$defaultDays Hari Pengerjaan');
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  int _parseDurationDays() {
    final match = RegExp(r'\d+').firstMatch(_duration.text);
    final parsed = match != null ? int.tryParse(match.group(0)!) : null;
    if (parsed != null && parsed > 0) return parsed;
    return widget.listing?.deliveryDays ?? DemoData.order.deadlineDays;
  }

  String? _validateTitle() {
    if (!_submitted) return null;
    final text = _title.text.trim();
    if (text.isEmpty) return 'Judul kebutuhan wajib diisi';
    if (text.length < 10) return 'Judul kebutuhan minimal 10 karakter';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_validateTitle() != null || _submitting) return;

    setState(() => _submitting = true);
    SakuMotion.tick();

    const demoOrder = DemoData.order;
    final listing = widget.listing;
    final price = (listing?.price ?? demoOrder.amount).toInt();
    final repo = AppScope.of(context).escrowRepository;

    try {
      final result = await repo.createOrder(
        listingId: listing?.id ?? 'listing-demo-091',
        deskripsiKebutuhan: _title.text.trim(),
        hargaDisepakati: price,
        durasiHari: _parseDurationDays(),
        catatanKlien: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );

      if (!mounted) return;

      if (result.isFallback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mode demo: Pesanan dibuat menggunakan data simulasi lokal.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dikirim ke penyedia jasa!'),
          ),
        );
      }

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.incomingOrders,
        arguments: result.data,
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      final pesan = e.code == 'UNAUTHORIZED'
          ? 'Sesi habis atau Anda belum login. Silakan login terlebih dahulu.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan tak terduga: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const order = DemoData.order;
    final listing = widget.listing;
    final provider = listing?.providerName.split(' ').first ?? 'Salma';
    final price = listing?.price ?? order.amount;

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Buat Pesanan Jasa'),
        Text(
          'Draf ${order.code} · Klien: ${order.client}',
          style: const TextStyle(
            fontSize: 11,
            height: 15 / 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SakuCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                listing?.title ?? 'Desain Spanduk Toko Katering Berkah (3×1 m)',
                style: const TextStyle(
                  fontSize: 15,
                  height: 21 / 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tarif ${formatRupiah(price)}',
                style: const TextStyle(
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        SakuTextField(
          fieldKey: const Key('order-title'),
          controller: _title,
          label: 'Judul Kebutuhan',
          errorText: _validateTitle(),
          onChanged: (_) => setState(() {}),
        ),
        SakuTextField(
          controller: _duration,
          label: 'Tenggat Waktu Diinginkan',
        ),
        SakuTextField(
          controller: _notes,
          label: 'Catatan Brief Detail',
          minLines: 3,
          maxLines: 6,
          maxLength: 500,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            const Text(
              'Unggah Berkas Aset',
              style: TextStyle(
                fontSize: 12,
                height: 17 / 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SakuDropzone(
              title: 'Unggah foto / logo referensi',
              subtitle: 'JPG / PNG / PDF maks 5MB',
              fileName: _file == null ? null : '↑ $_file',
              onTap: () => setState(
                () =>
                    _file = _file == null ? 'Foto_Ayam_Bakar.jpg (3 MB)' : null,
              ),
            ),
          ],
        ),
        SakuButton(
          key: const Key('order-submit'),
          label: _submitting ? 'Mengirim Pesanan...' : 'Kirim Pesanan ke $provider',
          onPressed: _submitting ? null : _submit,
        ),
        const InfoBox(
          text:
              'Pesanan akan masuk ke penyedia jasa untuk ditinjau dan disetujui.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}