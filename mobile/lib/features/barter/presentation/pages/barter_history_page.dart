import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../data/models/barter_model.dart';
import '../widgets/barter_widgets.dart';

/// Figma "24B · Riwayat barter" — daftar kontrak barter dari backend (atau contoh
/// demo hanya saat `AppConfig.useMockData`).
class BarterHistoryPage extends StatefulWidget {
  const BarterHistoryPage({super.key});

  @override
  State<BarterHistoryPage> createState() => _BarterHistoryPageState();
}

class _BarterHistoryPageState extends State<BarterHistoryPage> {
  int _filter = 0; // 0 Semua · 1 Berjalan · 2 Menunggu · 3 Selesai
  List<BarterAgreementModel> _remoteBarters = const [];
  bool _loading = false;
  bool _fetchedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetchedOnce && !AppConfig.useMockData) {
      _fetchedOnce = true;
      _loadBarters();
    }
  }

  Future<void> _loadBarters() async {
    if (AppConfig.useMockData) return;
    setState(() => _loading = true);
    try {
      final list = await AppScope.of(context).barterDataSource.listMyBarters();
      if (mounted) {
        setState(() {
          _remoteBarters = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.useMockData) {
      return _buildLiveBody(context);
    }

    const barter = DemoData.barter;
    const filters = [
      'Semua (3)',
      'Sedang Berjalan (1)',
      'Menunggu Konfirmasi (1)',
      '✓ Selesai Barter (1)',
    ];
    Widget filterText(int i) => GestureDetector(
          onTap: () => setState(() => _filter = i),
          child: Text(
            filters[i],
            style: TextStyle(
              fontSize: 11,
              height: 15 / 11,
              fontWeight: i == _filter ? FontWeight.w700 : FontWeight.w500,
              color: i == _filter ? AppColors.barterText : AppColors.textSecondary,
            ),
          ),
        );
    const bold = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Kontrak Barter Saya'),
        const Text(
          'Riwayat pertukaran keahlian tanpa uang tunai',
          style: TextStyle(
            fontSize: 12,
            height: 17 / 12,
            color: AppColors.textSecondary,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(children: [filterText(0), const Text('   ·   '), filterText(1)]),
            filterText(2),
            StatusStrip(
              filters[3],
              tone: _filter == 3 ? SakuTone.barter : SakuTone.neutral,
              textColor: AppColors.barterText,
              onTap: () => setState(() => _filter = 3),
            ),
          ],
        ),
        if (_filter == 1 || _filter == 0)
          StatusStrip(
            'Kontrak ${barter.code} · Pengerjaan bersama  ›',
            tone: SakuTone.barter,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.barterWorkroom),
          ),
        if (_filter == 2 || _filter == 0)
          StatusStrip(
            'Permintaan dari Salma · Menunggu konfirmasi Anda  ›',
            tone: SakuTone.warning,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.barterIncoming),
          ),
        if (_filter == 3 || _filter == 0)
          SakuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                const Text(
                  'KONTRAK #BTR-2026-012',
                  style: TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.barterText,
                  ),
                ),
                const InfoBox(
                  text: '✓ BARTER SELESAI & TUNTAS',
                  fontWeight: FontWeight.w500,
                ),
                const Text(
                  'Desain UI Web Landing Page\n✓ Diterima Rizkia',
                  style: bold,
                ),
                const SwapGlyph(size: 28),
                const Text(
                  'Editing Video Reels 30 Detik\n✓ Diterima Salma',
                  style: bold,
                ),
                SakuButton(
                  label: 'Buka Arsip Chat Diskusi',
                  variant: SakuButtonVariant.outline,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.barterChat),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLiveBody(BuildContext context) {
    final running = _remoteBarters
        .where((b) => b.isInProgress || b.statusKode == 'accepted')
        .toList();
    final waiting = _remoteBarters
        .where((b) =>
            b.statusKode == 'requested' ||
            b.statusKode == 'negotiating' ||
            b.isWaitingConfirmation)
        .toList();
    final completed = _remoteBarters.where((b) => b.isCompleted).toList();

    final visible = switch (_filter) {
      1 => running,
      2 => waiting,
      3 => completed,
      _ => _remoteBarters,
    };

    final filters = [
      'Semua (${_remoteBarters.length})',
      'Berjalan (${running.length})',
      'Menunggu (${waiting.length})',
      'Selesai (${completed.length})',
    ];

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Kontrak Barter Saya'),
        const Text(
          'Riwayat pertukaran keahlian Rp 0 yang tercatat pada akun Anda',
          style: TextStyle(
            fontSize: 12,
            height: 17 / 12,
            color: AppColors.textSecondary,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (var i = 0; i < filters.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _filter = i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: i == _filter
                          ? AppColors.barter
                          : AppColors.cardSurface,
                      borderRadius: AppRadius.pillBr,
                      border: Border.all(
                        color: i == _filter
                            ? AppColors.barter
                            : AppColors.clayBorder,
                      ),
                    ),
                    child: Text(
                      filters[i],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: i == _filter
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (visible.isEmpty)
          SakuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                const Text(
                  'Belum ada riwayat kontrak barter pada kategori ini.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                SakuButton(
                  label: 'Ajukan Penawaran Barter',
                  variant: SakuButtonVariant.barter,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.proposeBarter),
                ),
              ],
            ),
          )
        else
          for (final b in visible)
            _LiveBarterHistoryCard(
              barter: b,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.barterWorkroom, arguments: b)
                  .then((_) => _loadBarters()),
            ),
      ],
    );
  }
}

class _LiveBarterHistoryCard extends StatelessWidget {
  const _LiveBarterHistoryCard({required this.barter, required this.onTap});

  final BarterAgreementModel barter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final myId = AuthSession.instance.userId;
    final partnerName =
        myId == barter.pengajuId ? barter.namaPenerima : barter.namaPengaju;

    return SakuCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          StatusStrip(
            'SMART BARTER · ${barter.status.toUpperCase()}',
            tone: SakuTone.barter,
          ),
          PersonRow(
            name: partnerName.isEmpty ? 'Mitra Barter' : partnerName,
            subtitle: 'Tenggat ${formatDateId(barter.tenggatPekerjaan)}',
            leading: InitialsAvatar(
              name: partnerName.isEmpty ? 'Mitra' : partnerName,
              size: 40,
            ),
          ),
          Text(
            '⇄ ${barter.deskripsiJasaPengaju}\n⇄ ${barter.deskripsiJasaPenerima}',
            style: const TextStyle(
              fontSize: 12.5,
              height: 18 / 12.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
