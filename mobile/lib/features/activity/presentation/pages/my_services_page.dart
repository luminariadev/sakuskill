import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/state/account_finance_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
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
    required this.description,
    required this.price,
    required this.priceLabel,
    required this.days,
    required this.stats,
    required this.category,
    required this.offerType,
    required this.active,
    this.barterWant,
    this.isRemote = false,
  });

  final String id;
  final String title;
  final String description;
  final int price;
  final String priceLabel;
  final int days;
  final String stats;
  final String category;
  final String offerType; // 'Berbayar' | 'Barter' | 'Berbayar dan Barter'
  final String? barterWant;
  bool active;
  final bool isRemote;

  bool get acceptsBarter =>
      offerType == 'Barter' || offerType == 'Berbayar dan Barter';

  bool get acceptsPayment =>
      offerType == 'Berbayar' || offerType == 'Berbayar dan Barter';
}

/// Figma "9B · Jasa saya" — katalog layanan milik pengguna dengan dukungan
/// Tambah/Edit layanan nyata dan pilihan penawaran Berbayar / Barter / Keduanya.
class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  List<_ServiceItem> _items = [];
  bool _loading = false;
  int _tab = 0; // 0 Semua · 1 Aktif · 2 Nonaktif

  static const _categories = [
    'Desain',
    'Jasa Teknis',
    'Fotografi',
    'Bimbingan Belajar',
  ];

  static const _offerTypes = [
    'Berbayar',
    'Berbayar dan Barter',
    'Barter',
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    if (AppConfig.useMockData) {
      if (mounted) {
        setState(() {
          _items = [
            for (final s in DemoData.myServices)
              _ServiceItem(
                id: s.title,
                title: s.title,
                description:
                    'Layanan profesional mahasiswa kampus Cibiru siap dikerjakan sesuai kesepakatan.',
                price: 50000,
                priceLabel: s.priceLabel,
                days: s.days,
                stats: s.stats,
                category: 'Desain',
                offerType: s.barter ? 'Berbayar dan Barter' : 'Berbayar',
                barterWant: s.barter ? 'Editing Video / Desain Web' : null,
                active: true,
                isRemote: false,
              ),
          ];
        });
        AccountFinanceStore.instance.setMyServiceCount(_items.length);
      }
      return;
    }

    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    if (mounted) setState(() => _loading = true);
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/listings/me');
      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(AppConfig.networkTimeout);

      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final list = decoded['data'] as List<dynamic>? ?? const [];
        final parsed = list.map((item) {
          final harga =
              (double.tryParse(item['harga']?.toString() ?? '0') ?? 0).round();
          final tipe = item['tipe_penawaran']?.toString() ?? 'Berbayar';
          final active = item['status'] == 'Aktif';
          final barterDesc = item['deskripsi_imbalan_barter']?.toString();
          return _ServiceItem(
            id: item['listing_id']?.toString() ?? '',
            title: item['judul']?.toString() ?? 'Layanan',
            description: item['deskripsi']?.toString() ?? '',
            price: harga,
            priceLabel: tipe == 'Barter'
                ? 'Smart Barter (Rp 0)'
                : formatRupiah(harga),
            days: 3,
            stats: tipe == 'Berbayar dan Barter'
                ? 'Menerima Uang & Barter'
                : (tipe == 'Barter' ? 'Barter Skill Rp 0' : 'Layanan Berbayar'),
            category: item['kategori']?.toString() ?? 'Desain',
            offerType: tipe,
            barterWant: barterDesc,
            active: active,
            isRemote: true,
          );
        }).toList();

        setState(() => _items = parsed);
        AccountFinanceStore.instance.setMyServiceCount(parsed.length);
      }
    } catch (_) {
      // Pertahankan state terakhir jika offline
    } finally {
      if (mounted) setState(() => _loading = false);
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
          final uri =
              Uri.parse('${AppConfig.apiBaseUrl}/listings/${item.id}/status');
          await http
              .patch(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                  'status': nextStatus ? 'Aktif' : 'Nonaktif',
                }),
              )
              .timeout(AppConfig.networkTimeout);
        } catch (_) {}
      }
    }
  }

  Future<void> _openServiceFormSheet({_ServiceItem? existing}) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final priceCtrl = TextEditingController(
      text: isEdit ? '${existing.price}' : '50000',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final barterWantCtrl =
        TextEditingController(text: existing?.barterWant ?? '');

    var category = existing != null && _categories.contains(existing.category)
        ? existing.category
        : _categories.first;
    var offerType = existing != null && _offerTypes.contains(existing.offerType)
        ? existing.offerType
        : 'Berbayar';
    var saving = false;
    String? formError;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final needsBarter =
              offerType == 'Barter' || offerType == 'Berbayar dan Barter';
          final needsPrice =
              offerType == 'Berbayar' || offerType == 'Berbayar dan Barter';

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xEBFFFFFF),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                      width: 1.2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.dashedBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          isEdit ? 'Edit Layanan' : 'Buka Jasa Baru',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kategori Layanan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 8,
                            children: [
                              for (final cat in _categories)
                                FilterChipPill(
                                  label: cat,
                                  selected: category == cat,
                                  onTap: () =>
                                      setSheetState(() => category = cat),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tipe Penawaran',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 8,
                            children: [
                              for (final mode in _offerTypes)
                                FilterChipPill(
                                  label: mode,
                                  selected: offerType == mode,
                                  tone: mode == 'Berbayar'
                                      ? FilterChipTone.neutral
                                      : FilterChipTone.barter,
                                  onTap: () => setSheetState(() {
                                    offerType = mode;
                                    if (mode == 'Barter') {
                                      priceCtrl.text = '0';
                                    } else if (priceCtrl.text.trim() == '0' ||
                                        priceCtrl.text.trim().isEmpty) {
                                      priceCtrl.text = '50000';
                                    }
                                  }),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SakuTextField(
                          key: const ValueKey('svc-title'),
                          controller: titleCtrl,
                          label: 'Judul Jasa / Layanan',
                          hint: 'mis. Desain Logo & Banner Portofolio',
                        ),
                        if (needsPrice) ...[
                          const SizedBox(height: 10),
                          SakuTextField(
                            key: const ValueKey('svc-price'),
                            controller: priceCtrl,
                            label: 'Harga (Rp)',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                        if (needsBarter) ...[
                          const SizedBox(height: 10),
                          SakuTextField(
                            key: const ValueKey('svc-barter-want'),
                            controller: barterWantCtrl,
                            label:
                                'Imbalan Barter yang Dicari (min. 5 karakter)',
                            hint: 'mis. Jasa Edit Video Reels atau Foto Produk',
                          ),
                        ],
                        const SizedBox(height: 10),
                        SakuTextField(
                          key: const ValueKey('svc-desc'),
                          controller: descCtrl,
                          label: 'Deskripsi Layanan (min. 20 karakter)',
                          hint:
                              'Jelaskan cakupan pengerjaan, format berkas, dan revisi...',
                          minLines: 3,
                          maxLines: 5,
                        ),
                        if (formError != null) ...[
                          const SizedBox(height: 10),
                          InfoBox(text: formError!, tone: SakuTone.danger),
                        ],
                        const SizedBox(height: 16),
                        SakuButton(
                          label: saving
                              ? 'Menyimpan...'
                              : (isEdit
                                  ? 'Simpan Perubahan'
                                  : 'Terbitkan Jasa ke Marketplace'),
                          onPressed: saving
                              ? null
                              : () async {
                                  final title = titleCtrl.text.trim();
                                  final price = needsPrice
                                      ? (int.tryParse(priceCtrl.text.trim()) ??
                                          0)
                                      : 0;
                                  final desc = descCtrl.text.trim();
                                  final barterDesc = barterWantCtrl.text.trim();

                                  if (title.length < 5) {
                                    setSheetState(() => formError =
                                        'Judul jasa minimal 5 karakter.');
                                    return;
                                  }
                                  if (needsPrice && price <= 0) {
                                    setSheetState(() => formError =
                                        'Harga wajib lebih dari Rp 0 untuk layanan berbayar.');
                                    return;
                                  }
                                  if (needsBarter && barterDesc.length < 5) {
                                    setSheetState(() => formError =
                                        'Isi imbalan barter yang dicari (min. 5 karakter).');
                                    return;
                                  }
                                  if (desc.length < 20) {
                                    setSheetState(() => formError =
                                        'Deskripsi layanan minimal 20 karakter.');
                                    return;
                                  }

                                  if (AppConfig.useMockData) {
                                    Navigator.of(ctx).pop(true);
                                    return;
                                  }

                                  final token = AuthSession.instance.accessToken;
                                  if (token == null) {
                                    setSheetState(() => formError =
                                        'Sesi login tidak ditemukan.');
                                    return;
                                  }

                                  setSheetState(() {
                                    saving = true;
                                    formError = null;
                                  });

                                  try {
                                    final bodyPayload = <String, dynamic>{
                                      'judul': title,
                                      'kategori': category,
                                      'harga': price,
                                      'deskripsi': desc,
                                      'tipe_penawaran': offerType,
                                      'deskripsi_imbalan_barter':
                                          needsBarter ? barterDesc : null,
                                      if (!isEdit) ...{
                                        'latitude':
                                            AppConfig.campusCenter.latitude,
                                        'longitude':
                                            AppConfig.campusCenter.longitude,
                                      },
                                    };

                                    final uri = isEdit && existing.isRemote
                                        ? Uri.parse(
                                            '${AppConfig.apiBaseUrl}/listings/${existing.id}')
                                        : Uri.parse(
                                            '${AppConfig.apiBaseUrl}/listings');

                                    final headers = {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    };

                                    final res = isEdit && existing.isRemote
                                        ? await http
                                            .put(uri,
                                                headers: headers,
                                                body: jsonEncode(bodyPayload))
                                            .timeout(AppConfig.networkTimeout)
                                        : await http
                                            .post(uri,
                                                headers: headers,
                                                body: jsonEncode(bodyPayload))
                                            .timeout(AppConfig.networkTimeout);

                                    if (res.statusCode >= 200 &&
                                        res.statusCode < 300) {
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop(true);
                                      }
                                      return;
                                    }

                                    String msg =
                                        'Gagal menyimpan layanan (HTTP ${res.statusCode}).';
                                    try {
                                      final decoded = jsonDecode(
                                          utf8.decode(res.bodyBytes));
                                      if (decoded is Map &&
                                          decoded['message'] is String) {
                                        msg = decoded['message'] as String;
                                      }
                                    } catch (_) {}

                                    if (ctx.mounted) {
                                      setSheetState(() {
                                        saving = false;
                                        formError = msg;
                                      });
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      setSheetState(() {
                                        saving = false;
                                        formError =
                                            'Gagal terhubung ke server: $e';
                                      });
                                    }
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (saved == true) {
      await _loadServices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Perubahan layanan berhasil disimpan!'
                  : 'Jasa baru berhasil diterbitkan ke marketplace!',
            ),
            backgroundColor: Colors.green.shade700,
          ),
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
        if (_tab == 0 ||
            (_tab == 1 && item.active) ||
            (_tab == 2 && !item.active))
          item,
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
          key: const Key('my-services-add'),
          label: '+ Buka Jasa Baru',
          onPressed: () => _openServiceFormSheet(),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final (i, label) in [
                'Semua (${_items.length})',
                'Aktif ($activeCount)',
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
        if (_loading && _items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (visible.isEmpty)
          const InfoBox(
            text:
                'Belum ada layanan yang Anda terbitkan pada kategori ini. Ketuk "+ Buka Jasa Baru" untuk mulai menawarkan keahlian Anda.',
            tone: SakuTone.neutral,
          ),
        for (final item in visible)
          _ServiceCard(
            service: item,
            active: item.active,
            onToggle: () => _toggleService(item),
            onEdit: () => _openServiceFormSheet(existing: item),
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
    required this.onEdit,
  });

  final _ServiceItem service;
  final bool active;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  static String _iconKey(String category) => switch (category) {
        'Desain' => 'design',
        'Jasa Teknis' => 'tech',
        'Fotografi' => 'photo',
        'Bimbingan Belajar' => 'tutor',
        _ => '',
      };

  static Color _accentFor(String category) => switch (category) {
        'Desain' => AppColors.primary,
        'Jasa Teknis' => AppColors.escrow,
        'Fotografi' => AppColors.warningText,
        'Bimbingan Belajar' => const Color(0xFF0D9488),
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final tint = _accentFor(service.category);
    return SakuCard(
      radius: 18,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClayIconBadge(
                size: 46,
                radius: 15,
                tint: tint,
                icon: categoryIcon(_iconKey(service.category)),
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 21 / 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            service.priceLabel,
                            style: TextStyle(
                              fontSize: 15,
                              height: 21 / 15,
                              fontWeight: FontWeight.w800,
                              color: service.acceptsPayment
                                  ? AppColors.primary
                                  : AppColors.barterText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.1),
                            borderRadius: AppRadius.pillBr,
                          ),
                          child: Text(
                            '${service.days} Hari',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: tint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
          if (service.acceptsBarter)
            StatusStrip(
              service.acceptsPayment
                  ? 'Bisa Uang & Smart Barter${service.barterWant != null ? ' · Cari: ${service.barterWant}' : ''}'
                  : 'Smart Barter Rp 0${service.barterWant != null ? ' · Cari: ${service.barterWant}' : ''}',
              tone: SakuTone.barter,
            ),
          SakuButton(
            key: Key('edit-service-${service.id}'),
            label: 'Edit Layanan',
            variant: SakuButtonVariant.outline,
            onPressed: onEdit,
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
