import 'dart:async';

import 'package:flutter/material.dart';

import 'incoming_order_page.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/state/account_finance_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../../discovery/domain/entities/service_listing.dart';
import '../../data/datasources/escrow_remote_data_source.dart';

/// Figma "11 · Buat pesanan jasa" (sisi klien).
class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({super.key, this.listing});

  /// Layanan yang dipesan; null = data demo pesanan #SK-091 (widget test).
  final ServiceListing? listing;

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final TextEditingController _notes;
  final _refLink = TextEditingController();

  bool _submitted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    final defaultDays = listing?.deliveryDays ?? DemoData.order.deadlineDays;
    _title = TextEditingController(
      text: listing != null
          ? 'Pesanan: ${listing.title}'
          : 'Desain Spanduk Toko Ukuran 3×1 Meter',
    );
    _duration = TextEditingController(text: '$defaultDays Hari Pengerjaan');
    _notes = TextEditingController(
      text: listing != null
          ? ''
          : 'Warna cerah hijau kuning, tolong cantumkan logo menu '
              'ayam bakar dan no WhatsApp katering.',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _notes.dispose();
    _refLink.dispose();
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
    final formValid = _formKey.currentState?.validate() ?? true;
    if (!formValid || _validateTitle() != null || _submitting) return;

    setState(() => _submitting = true);
    SakuMotion.tick();

    const demoOrder = DemoData.order;
    final listing = widget.listing;
    final price = (listing?.price ?? demoOrder.amount).toInt();
    final repo = AppScope.of(context).escrowRepository;

    final noteParts = <String>[
      if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
      if (_refLink.text.trim().isNotEmpty) 'Referensi: ${_refLink.text.trim()}',
    ];

    try {
      final result = await repo.createOrder(
        listingId: listing?.id ?? 'listing-demo-091',
        deskripsiKebutuhan: _title.text.trim(),
        hargaDisepakati: price,
        durasiHari: _parseDurationDays(),
        catatanKlien: noteParts.isEmpty ? null : noteParts.join('\n'),
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
        unawaited(AccountFinanceStore.instance.refreshLive(escrowRepository: repo));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permintaan pesanan dikirim! Menunggu konfirmasi penyedia jasa.',
            ),
          ),
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => IncomingOrderPage(
            order: result.data,
            isProviderView: result.isFallback ? true : false,
          ),
        ),
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      final pesan = e.code == 'UNAUTHORIZED'
          ? 'Sesi habis atau Anda belum login. Silakan login terlebih dahulu.'
          : e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.red.shade700),
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
    final provider = listing?.providerName.split(' ').first ?? 'Penyedia';
    final price = listing?.price ?? order.amount;
    final clientLabel = listing == null
        ? 'Draf ${order.code} · Klien: ${order.client}'
        : 'Pengajuan Pesanan · Klien: ${AuthSession.instance.userName ?? 'Pengguna'}';

    return Form(
      key: _formKey,
      child: SakuScreen(
        background: AppColors.canvasLight,
        showBack: true,
        children: [
          const PageHeader('Buat Pesanan Jasa'),
          Text(
            clientLabel,
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
                  listing?.title ??
                      'Desain Spanduk Toko Katering Berkah (3×1 m)',
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
            hint: 'Contoh: Install Ulang Windows 11 + Office di Cibiru',
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
            hint:
                'Jelaskan detail spesifikasi kebutuhan, lokasi, atau jadwal yang diinginkan...',
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
          ),
          SakuTextField(
            fieldKey: const Key('order-ref-link'),
            controller: _refLink,
            label: 'Tautan Referensi / Berkas (Opsional)',
            hint: 'https://drive.google.com/...',
            keyboardType: TextInputType.url,
            validator: SakuValidators.optional(SakuValidators.httpsUrl()),
          ),
          SakuButton(
            key: const Key('order-submit'),
            label: _submitting
                ? 'Mengirim Pesanan...'
                : 'Kirim Permintaan ke $provider',
            onPressed: _submitting ? null : _submit,
          ),
          const InfoBox(
            text:
                'Setelah dikirim, Anda langsung masuk ke halaman menunggu konfirmasi & dapat berdiskusi dengan penyedia jasa.',
            tone: SakuTone.escrow,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}
