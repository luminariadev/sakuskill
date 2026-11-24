import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../data/datasources/barter_remote_data_source.dart';
import '../../data/models/barter_model.dart';

/// Figma "23 · Ruang kerja barter" — berbasis milestone objektif dua pihak
/// (Diajukan -> Disepakati -> Dikerjakan -> Selesai 2 Pihak), tanpa angka
/// persentase subjektif. Dilengkapi polling sinkronisasi real-time, ruang chat
/// per kontrak barter, dan tombol rating timbal balik dua pihak.
class BarterWorkroomPage extends StatefulWidget {
  const BarterWorkroomPage({super.key, this.barter});

  final BarterAgreementModel? barter;

  @override
  State<BarterWorkroomPage> createState() => _BarterWorkroomPageState();
}

class _BarterWorkroomPageState extends State<BarterWorkroomPage> {
  BarterAgreementModel? _override;
  bool _busy = false;
  bool _initialized = false;
  Timer? _pollTimer;

  BarterAgreementModel? get _barter => _override ?? widget.barter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final b = _barter;
    if (b != null && b.id.isNotEmpty && !AppConfig.useMockData) {
      _refreshDetail(b.id);
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _refreshDetail(b.id),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshDetail(String barterId) async {
    try {
      final latest = await AppScope.of(context)
          .barterDataSource
          .getBarterDetail(barterId);
      if (!mounted) return;
      setState(() => _override = latest);
    } catch (_) {}
  }

  Future<void> _runAction(
    Future<BarterAgreementModel> Function(BarterRemoteDataSource ds, String id)
        action,
    String successMessage,
  ) async {
    final current = _barter;
    if (_busy || current == null || current.id.isEmpty) return;

    setState(() => _busy = true);
    SakuMotion.tick();
    try {
      final updated =
          await action(AppScope.of(context).barterDataSource, current.id);
      if (!mounted) return;
      setState(() => _override = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green.shade700),
      );
      if (updated.isCompleted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.barterDone,
          arguments: updated,
        );
      }
    } on BarterException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal memproses: $e'),
            backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _stepIndex(String statusKode) {
    switch (statusKode.toLowerCase()) {
      case 'accepted':
        return 1;
      case 'in_progress':
        return 2;
      case 'completion_requested':
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _barter;
    final statusKode = b?.statusKode.toLowerCase() ?? 'in_progress';
    final statusLabel = b?.status ?? 'Dikerjakan (Demo)';
    final pengajuName = (b?.namaPengaju.isNotEmpty ?? false)
        ? b!.namaPengaju
        : DemoData.me;
    final penerimaName = (b?.namaPenerima.isNotEmpty ?? false)
        ? b!.namaPenerima
        : DemoData.barter.partner;

    final setujuPengaju = b?.setujuPengaju ?? true;
    final setujuPenerima = b?.setujuPenerima ?? true;
    final selesaiPengaju = b?.konfirmasiSelesaiPengaju ?? false;
    final selesaiPenerima = b?.konfirmasiSelesaiPenerima ?? false;

    final userId = (AuthSession.instance.userId ?? '').trim().toLowerCase();
    final isInitiator =
        b == null || userId == b.pengajuId.trim().toLowerCase();
    final partnerName = isInitiator ? penerimaName : pengajuName;
    final partnerShort = partnerName.split(' ').first;

    final canApprove =
        b != null && (statusKode == 'requested' || statusKode == 'negotiating');
    final canStart = b != null && statusKode == 'accepted';
    final canConfirmDone = b == null ||
        statusKode == 'in_progress' ||
        statusKode == 'completion_requested';
    final isCompleted = b != null && b.isCompleted;
    final isCancelledOrRejected =
        b != null && (statusKode == 'cancelled' || statusKode == 'rejected');

    final iAlreadyAgreed =
        b != null && (isInitiator ? setujuPengaju : setujuPenerima);
    final iAlreadyDone =
        b != null && (isInitiator ? selesaiPengaju : selesaiPenerima);

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        const PageHeader('Proyek Barter Berjalan'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                b != null
                    ? 'ID #${b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase()} · Tenggat ${formatDateId(b.tenggatPekerjaan)}'
                    : '#BTR-2026-012 (Mode Demo)',
                style: const TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (b != null)
              GestureDetector(
                onTap: () => _refreshDetail(b.id),
                child: const Text(
                  'Segarkan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.barter,
                  ),
                ),
              ),
          ],
        ),
        InfoBox(
          text: 'STATUS BARTER: ${statusLabel.toUpperCase()} · NILAI Rp 0 (TANPA UANG)',
          tone: SakuTone.barter,
          fontWeight: FontWeight.w600,
        ),
        const InfoBox(
          text:
              'Ketentuan Smart Barter:\n'
              '1. Kedua pihak menyepakati tugas & tenggat.\n'
              '2. Barter dimulai setelah persetujuan 2 pihak.\n'
              '3. Kontrak selesai hanya jika kedua pihak saling mengonfirmasi hasil, lalu keduanya berhak saling memberi rating.',
          tone: SakuTone.neutral,
          fontWeight: FontWeight.w500,
        ),
        SakuCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const SectionLabel('TAHAP KONTRAK BARTER'),
              MilestoneSteps(
                current: _stepIndex(statusKode),
                steps: const [
                  'Diajukan',
                  'Disepakati',
                  'Dikerjakan',
                  'Selesai 2 Pihak',
                ],
                allGreen: isCompleted,
              ),
            ],
          ),
        ),
        _PartyTaskCard(
          roleTitle: 'KEWAJIBAN PENGAJU BARTER',
          name: pengajuName,
          deliverable:
              b?.deskripsiJasaPengaju ?? 'Desain UI Web Landing Page (Figma)',
          agreed: setujuPengaju,
          completed: selesaiPengaju,
        ),
        _PartyTaskCard(
          roleTitle: 'KEWAJIBAN PENERIMA BARTER',
          name: penerimaName,
          deliverable:
              b?.deskripsiJasaPenerima ?? 'Editing Video Teaser Reels 30 Detik',
          agreed: setujuPenerima,
          completed: selesaiPenerima,
        ),
        if (isCancelledOrRejected)
          InfoBox(
            key: const Key('barter-cancelled-banner'),
            text: statusKode == 'rejected'
                ? 'Penawaran barter ini telah ditolak oleh penerima.'
                : 'Penawaran barter ini telah dibatalkan sebelum disepakati/dikerjakan.',
            tone: SakuTone.danger,
            fontWeight: FontWeight.w600,
          ),
        if (canApprove) ...[
          SakuButton(
            key: const Key('barter-accept'),
            label: _busy
                ? 'Memproses...'
                : (iAlreadyAgreed
                    ? 'Anda Sudah Setuju (Menunggu Mitra)'
                    : 'Setujui Ketentuan Barter'),
            variant: SakuButtonVariant.barter,
            onPressed: (_busy || iAlreadyAgreed)
                ? null
                : () => _runAction(
                      (ds, id) => ds.acceptBarter(id),
                      'Ketentuan barter Anda disetujui.',
                    ),
          ),
          if (isInitiator)
            SakuButton(
              key: const Key('barter-cancel'),
              label: _busy ? 'Membatalkan...' : 'Batalkan Penawaran Barter',
              variant: SakuButtonVariant.destructive,
              onPressed: _busy
                  ? null
                  : () => _runAction(
                        (ds, id) => ds.cancelBarter(id),
                        'Penawaran barter berhasil dibatalkan.',
                      ),
            )
          else
            SakuButton(
              key: const Key('barter-reject'),
              label: _busy ? 'Memproses...' : 'Tolak Tawaran Barter',
              variant: SakuButtonVariant.destructive,
              onPressed: _busy
                  ? null
                  : () => _runAction(
                        (ds, id) => ds.rejectBarter(id),
                        'Penawaran barter ditolak.',
                      ),
            ),
        ],
        if (canStart) ...[
          SakuButton(
            key: const Key('barter-start'),
            label: _busy ? 'Memulai...' : 'Mulai Pengerjaan Bersama',
            variant: SakuButtonVariant.barter,
            onPressed: _busy
                ? null
                : () => _runAction(
                      (ds, id) => ds.startBarter(id),
                      'Pengerjaan barter dimulai!',
                    ),
          ),
          SakuButton(
            key: const Key('barter-cancel-accepted'),
            label: _busy
                ? 'Membatalkan...'
                : 'Batalkan Sebelum Pengerjaan Dimulai',
            variant: SakuButtonVariant.outline,
            onPressed: _busy
                ? null
                : () => _runAction(
                      (ds, id) => ds.cancelBarter(id),
                      'Kesepakatan barter dibatalkan sebelum dimulai.',
                    ),
          ),
        ],
        if (canConfirmDone)
          SakuButton(
            key: const Key('barter-submit'),
            label: _busy
                ? 'Mengonfirmasi...'
                : (iAlreadyDone
                    ? 'Menunggu Konfirmasi Mitra Lawan'
                    : 'Konfirmasi Karya Barter Selesai'),
            variant: SakuButtonVariant.barter,
            onPressed: (_busy || iAlreadyDone)
                ? null
                : () {
                    if (b == null) {
                      SakuMotion.tick();
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.barterDone);
                      return;
                    }
                    _runAction(
                      (ds, id) => ds.confirmCompletion(id),
                      'Konfirmasi penyelesaian Anda tercatat.',
                    );
                  },
          ),
        if (isCompleted)
          SakuButton(
            key: const Key('barter-mutual-review'),
            label: 'Beri Rating & Ulasan untuk $partnerShort',
            variant: SakuButtonVariant.barter,
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.barterDone,
              arguments: b,
            ),
          ),
        SakuButton(
          label: 'Buka Chat Diskusi Barter',
          variant: SakuButtonVariant.outline,
          onPressed: () => Navigator.of(context).pushNamed(
            AppRoutes.barterChat,
            arguments: b,
          ),
        ),
        if (b != null &&
            (statusKode == 'in_progress' ||
                statusKode == 'completion_requested' ||
                isCompleted))
          SakuButton(
            label: 'Ajukan Komplain Transaksi',
            variant: SakuButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.complaint,
              arguments: b,
            ),
          ),
      ],
    );
  }
}

class _PartyTaskCard extends StatelessWidget {
  const _PartyTaskCard({
    required this.roleTitle,
    required this.name,
    required this.deliverable,
    required this.agreed,
    required this.completed,
  });

  final String roleTitle;
  final String name;
  final String deliverable;
  final bool agreed;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return SakuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          SectionLabel(roleTitle, color: AppColors.barterText),
          PersonRow(
            name: name,
            subtitle: deliverable,
            leading: InitialsAvatar(name: name, size: 40),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _BadgeChip(
                label: agreed ? '✓ Ketentuan Disetujui' : '○ Belum Menyetujui',
                active: agreed,
              ),
              _BadgeChip(
                label: completed ? '✓ Hasil Dikonfirmasi' : '● Pengerjaan / Menunggu',
                active: completed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.barterSurface : AppColors.surfaceSubtle,
        borderRadius: AppRadius.pillBr,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.barterText : AppColors.textSecondary,
        ),
      ),
    );
  }
}
