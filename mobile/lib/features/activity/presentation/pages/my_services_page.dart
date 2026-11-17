import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_assets.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../../discovery/presentation/widgets/discovery_filters.dart';

class _ServiceItem {
  _ServiceItem({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.days,
    required this.stats,
    required this.cover,
    required this.active,
    this.barter = false,
    this.isRemote = false,
  });

  final String id;
  final String title;
  final String priceLabel;
  final int days;
  final String stats;
  final String cover;
  bool active;
  final bool barter;
  final bool isRemote;
}

/// Figma "9B · Jasa saya" — katalog layanan milik pengguna.
class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  List<_ServiceItem> _items = [];
  bool _loading = false;
  int _tab = 0; // 0 Semua · 1 Aktif · 2 Draf · 3 Nonaktif

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final token = AuthSession.instance.accessToken;
    if (token != null && !AppConfig.useMockData) {
      try {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}/listings/me');
        final res = await http.get(uri, headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final list = decoded['data'] as List<dynamic>? ?? [];
          if (list.isNotEmpty && mounted) {
            setState(() {
              _items = list.map((item) {
                final harga = double.tryParse(item['harga']?.toString() ?? '0') ?? 0;
                final active = item['status'] == 'Aktif';
                final isBarter = item['tipe_penawaran'] == 'Barter' ||
                    item['tipe_penawaran'] == 'Berbayar dan Barter';
                return _ServiceItem(
                  id: item['listing_id']?.toString() ?? '',
                  title: item['judul']?.toString() ?? 'Layanan',
                  priceLabel: formatRupiah(harga),
                  days: 3,
                  stats: '0 Pesanan · 5.0 ★ (0 ulasan)',
                  cover: DemoAssets.portfolioWeb,
                  active: active,
                  barter: isBarter,
                  isRemote: true,
                );
              }).toList();
            });
            return;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _items = [
          for (final s in DemoData.myServices)
            _ServiceItem(
              id: s.title,
              title: s.title,
              priceLabel: s.priceLabel,
              days: s.days,
              stats: s.stats,
              cover: s.cover,
              active: true,
              barter: s.barter,
              isRemote: false,
            ),
        ];
      });
    }
  }

  Future<void> _toggleService(_ServiceItem item) async {
    SakuMotion.tick();
    final nextStatus = !item.active;
    setState(() => item.active = nextStatus);

    if (item.isRemote) {
      final token = AuthSession.instance.accessToken;
      if (token != null) {
        try {
          final uri = Uri.parse('${AppConfig.apiBaseUrl}/listings/${item.id}/status');
          await http.patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'status': nextStatus ? 'Aktif' : 'Nonaktif',
            }),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _createServiceDialog() async {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '50000');
    final descCtrl = TextEditingController();
    String category = 'Desain';

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buka Jasa Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SakuTextField(
                  controller: titleCtrl,
                  label: 'Judul Jasa / Layanan',
                  hint: 'mis. Desain Logo & Banner Portofolio',
                ),
                const SizedBox(height: 10),
                SakuTextField(
                  controller: priceCtrl,
                  label: 'Harga (Rp)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                SakuTextField(
                  controller: descCtrl,
                  label: 'Deskripsi Layanan (min. 20 karakter)',
                  hint: 'Jelaskan cakupan pengerjaan, format berkas, dan revisi...',
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                SakuButton(
                  label: 'Terbitkan Jasa ke Marketplace',
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                    final desc = descCtrl.text.trim();
                    if (title.length < 5 || desc.length < 20) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Judul min. 5 karakter, deskripsi min. 20 karakter.',
                          ),
                        ),
                      );
                      return;
                    }

                    final token = AuthSession.instance.accessToken;
                    if (token != null && !AppConfig.useMockData) {
                      try {
                        final uri = Uri.parse('${AppConfig.apiBaseUrl}/listings');
                        final res = await http.post(
                          uri,
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: jsonEncode({
                            'judul': title,
                            'kategori': category,
                            'harga': price,
                            'deskripsi': desc,
                            'latitude': AppConfig.campusCenter.latitude,
                            'longitude': AppConfig.campusCenter.longitude,
                            'tipe_penawaran': 'Berbayar',
                          }),
                        );
                        if (res.statusCode >= 200 && res.statusCode < 300) {
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                          return;
                        }
                      } catch (_) {}
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (created == true) {
      _loadServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jasa baru berhasil diterbitkan!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _items.where((a) => a.active).length;
    final inactiveCount = _items.length - activeCount;
    final visible = [
      for (final item in _items)
        if (_tab == 0 || (_tab == 1 && item.active) || (_tab == 3 && !item.active)) item,
    ];

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader(
          'Jasa yang Saya Tawarkan',
          subtitle: 'Kelola katalog layanan yang Anda buka ke marketplace',
        ),
        SakuButton(
          label: '+ Buka Jasa Baru',
          onPressed: _createServiceDialog,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final (i, label) in [
                'Semua (${_items.length})',
                'Aktif ($activeCount)',
                'Draf (0)',
                'Nonaktif ($inactiveCount)',
              ].indexed)
                FilterChipPill(
                  label: label,
                  selected: _tab == i,
                  onTap: () => setState(() => _tab = i),
                ),
            ],
          ),
        ),
        if (visible.isEmpty)
          const InfoBox(
            text: 'Belum ada layanan di kategori ini.',
            tone: SakuTone.neutral,
          ),
        for (final item in visible)
          _ServiceCard(
            service: item,
            active: item.active,
            onToggle: () => _toggleService(item),
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.active,
    required this.onToggle,
  });

  final _ServiceItem service;
  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SakuCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: Image.asset(service.cover, fit: BoxFit.cover),
            ),
          ),
          Text(
            service.title,
            style: const TextStyle(
              fontSize: 15,
              height: 21 / 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            service.priceLabel,
            style: const TextStyle(
              fontSize: 15,
              height: 21 / 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Pengerjaan ${service.days} Hari',
            style: const TextStyle(
              fontSize: 11,
              height: 15 / 11,
              color: AppColors.textSecondary,
            ),
          ),
          StatusStrip(service.stats, tone: SakuTone.neutral),
          Semantics(
            toggled: active,
            label: 'Menerima pesanan baru',
            child: StatusStrip(
              active
                  ? '● Aktif · Menerima Pesanan Baru'
                  : '○ Nonaktif · Tidak menerima pesanan',
              tone: active ? SakuTone.success : SakuTone.neutral,
              onTap: onToggle,
              trailing: _MiniSwitch(on: active),
            ),
          ),
          if (service.barter)
            const StatusStrip('Bisa Barter', tone: SakuTone.barter),
          SakuButton(
            label: 'Edit Layanan',
            variant: SakuButtonVariant.outline,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit layanan segera hadir.')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SakuMotion.base,
      curve: SakuMotion.curve,
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: on ? AppColors.primary : AppColors.borderLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedAlign(
        duration: SakuMotion.base,
        curve: SakuMotion.curve,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
