import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../discovery/domain/entities/service_listing.dart';

/// Figma "11 · Buat pesanan jasa" (sisi klien).
class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({super.key, this.listing});

  /// Layanan yang dipesan; null = data demo pesanan #SK-091.
  final ServiceListing? listing;

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  final _title = TextEditingController(text: 'Desain Spanduk Toko Ukuran 3×1 Meter');
  String? _file = 'Foto_Ayam_Bakar.jpg (3 MB)';
  bool _submitted = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_title.text.trim().isEmpty) return;
    SakuMotion.tick();
    Navigator.of(context).pushReplacementNamed(AppRoutes.incomingOrders);
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
          errorText: _submitted && _title.text.trim().isEmpty
              ? 'Judul kebutuhan wajib diisi'
              : null,
          onChanged: (_) => setState(() {}),
        ),
        SakuTextField(
          label: 'Tenggat Waktu Diinginkan',
          initialValue: '${listing?.deliveryDays ?? order.deadlineDays} Hari Pengerjaan',
        ),
        const SakuTextField(
          label: 'Catatan Brief Detail',
          initialValue: 'Warna cerah hijau kuning, tolong cantumkan logo menu '
              'ayam bakar dan no WhatsApp katering.',
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
                () => _file = _file == null ? 'Foto_Ayam_Bakar.jpg (3 MB)' : null,
              ),
            ),
          ],
        ),
        SakuButton(
          key: const Key('order-submit'),
          label: 'Kirim Pesanan ke $provider',
          onPressed: _submit,
        ),
        const InfoBox(
          text: 'Pesanan akan masuk ke penyedia jasa untuk ditinjau dan disetujui.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}
