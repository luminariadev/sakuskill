import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../discovery/presentation/widgets/discovery_filters.dart';

/// Figma "9B · Jasa saya" — katalog layanan milik pengguna.
class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  late final List<bool> _active = [for (final _ in DemoData.myServices) true];
  int _tab = 0; // 0 Semua · 1 Aktif · 2 Draf · 3 Nonaktif

  @override
  Widget build(BuildContext context) {
    const services = DemoData.myServices;
    final activeCount = _active.where((a) => a).length;
    final inactiveCount = services.length - activeCount;
    final visible = [
      for (var i = 0; i < services.length; i++)
        if (_tab == 0 || (_tab == 1 && _active[i]) || (_tab == 3 && !_active[i])) i,
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
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formulir buka jasa baru segera hadir.')),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final (i, label) in [
                'Semua (${services.length})',
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
        for (final i in visible)
          _ServiceCard(
            service: services[i],
            active: _active[i],
            onToggle: () {
              SakuMotion.tick();
              setState(() => _active[i] = !_active[i]);
            },
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

  final DemoService service;
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
          SakuButton(
            label: 'Lihat Preview Pembeli',
            variant: SakuButtonVariant.outline,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.shell),
          ),
        ],
      ),
    );
  }
}

/// Saklar kecil "ON/OFF" dengan knob yang bergeser 160 ms.
class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(
          on ? 'ON' : 'OFF',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: on ? AppColors.primaryPressed : AppColors.textSecondary,
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 30,
          height: 18,
          padding: const EdgeInsets.all(2),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: on ? AppColors.accent : AppColors.dashedBorder,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
