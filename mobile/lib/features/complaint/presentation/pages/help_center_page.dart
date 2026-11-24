import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';

/// Pusat Bantuan pengguna akhir (FAQ & riwayat komplain milik akun aktif).
/// Komplain transaksi spesifik diajukan langsung dari halaman transaksi terkait.
class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  static const List<_FaqItem> _faqs = [
    _FaqItem(
      title: 'Bagaimana cara kerja Rekening Bersama Escrow?',
      body:
          'Dana yang dibayarkan klien ditahan sistem sementara selama pengerjaan jasa. '
          'Penyedia menerima saldo hanya setelah klien memeriksa dan menyetujui hasil pekerjaan.',
    ),
    _FaqItem(
      title: 'Kapan pembayaran Escrow dibuka?',
      body:
          'Setelah klien mengirim pesanan, penyedia jasa harus meninjau dan menekan "Terima & Sepakati Pesanan" terlebih dahulu. '
          'Setelah disetujui, tombol pembayaran Escrow otomatis aktif di halaman Klien.',
    ),
    _FaqItem(
      title: 'Bagaimana alur & aturan Smart Barter (Rp 0)?',
      body:
          '1. Pilih layanan bertanda "Bisa Barter" atau cari kecocokan di Smart Barter.\n'
          '2. Kedua pihak menyepakati keahlian masing-masing & tenggat bersama.\n'
          '3. Pengerjaan dimulai setelah kedua pihak setuju.\n'
          '4. Barter tuntas apabila KEDUA pihak mengonfirmasi selesai, lalu keduanya dapat saling memberi rating.',
    ),
    _FaqItem(
      title: 'Bagaimana cara mengajukan komplain atau sengketa?',
      body:
          'Jika terjadi kendala pada pesanan aktif atau yang baru selesai (misalnya hasil tidak sesuai brief atau melewati batas waktu), '
          'buka transaksi tersebut di tab Aktivitas Saya lalu ketuk "Ajukan Komplain Transaksi".',
    ),
  ];

  bool _loading = false;
  List<Map<String, dynamic>> _reports = const [];
  int _expandedFaq = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (AppConfig.useMockData) return;
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/reports'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.networkTimeout);

      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        if (json is Map<String, dynamic> && json['data'] is List) {
          setState(() {
            _reports = (json['data'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
          });
        }
      }
    } catch (_) {
      // Abaikan kegagalan jaringan sementara
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader(
          'Pusat Bantuan\n& Panduan Pengguna',
          subtitle: 'Jawaban cepat penggunaan layanan SakuSkill dan status laporan Anda.',
        ),
        const InfoBox(
          text:
              'Mengalami kendala pada pesanan jasa atau Smart Barter? Buka detail pesanan atau proyek barter di tab Aktivitas Saya, lalu ketuk "Ajukan Komplain Transaksi".',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        ),
        const SectionLabel('PERTANYAAN UMUM (FAQ)'),
        SakuCard(
          radius: 20,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _faqs.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                InkWell(
                  onTap: () => setState(
                    () => _expandedFaq = _expandedFaq == i ? -1 : i,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _faqs[i].title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              _expandedFaq == i
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                        if (_expandedFaq == i) ...[
                          const SizedBox(height: 8),
                          Text(
                            _faqs[i].body,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 18 / 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('RIWAYAT KOMPLAIN & LAPORAN SAYA'),
            GestureDetector(
              onTap: _loadReports,
              child: const Text(
                'Segarkan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_reports.isEmpty)
          const SakuCard(
            child: Text(
              'Belum ada laporan atau komplain transaksi yang Anda ajukan.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          for (final report in _reports)
            SakuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${report['target_tipe'] ?? 'Transaksi'}',
                        style: AppTypography.eyebrow.copyWith(
                          color: AppColors.escrowText,
                        ),
                      ),
                      Text(
                        '${report['status_penanganan'] ?? 'Baru'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${report['alasan'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${report['keterangan'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 18 / 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if ((report['keputusan'] ?? '').toString().trim().isNotEmpty)
                    InfoBox(
                      text: 'Keputusan Admin: ${report['keputusan']}',
                      tone: SakuTone.success,
                      fontWeight: FontWeight.w500,
                    ),
                ],
              ),
            ),
        SakuButton(
          label: 'Buka Aktivitas Transaksi Saya',
          variant: SakuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.shell,
            (r) => false,
          ),
        ),
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.title, required this.body});
  final String title;
  final String body;
}
