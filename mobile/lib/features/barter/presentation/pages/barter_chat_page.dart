import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../../../auth/data/auth_session.dart';
import '../../data/models/barter_model.dart';
import '../widgets/barter_widgets.dart';

/// Figma "22 · Diskusi barter" — ruang chat real-time untuk kesepakatan Smart Barter.
class BarterChatPage extends StatefulWidget {
  const BarterChatPage({super.key, this.barter});

  final BarterAgreementModel? barter;

  @override
  State<BarterChatPage> createState() => _BarterChatPageState();
}

class _BarterChatPageState extends State<BarterChatPage> {
  Timer? _clockTimer;
  Timer? _pollTimer;
  String _liveClock = formatClockSeconds(DateTime.now());
  List<ChatMessage> _messages = const [];
  bool _initialized = false;
  bool _loading = false;
  bool _sending = false;

  BarterAgreementModel? _resolveBarter(BuildContext context) {
    if (widget.barter != null) return widget.barter;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is BarterAgreementModel ? args : null;
  }

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _liveClock = formatClockSeconds(DateTime.now()));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final b = _resolveBarter(context);
    if (b != null && b.id.isNotEmpty && !AppConfig.useMockData) {
      _loadMessages(b.id);
      _pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _loadMessages(b.id, silent: true),
      );
    } else if (AppConfig.useMockData) {
      final now = DateTime.now();
      _messages = [
        ChatMessage(
          text:
              'Halo Salma! Keren banget, saya butuh desain UI 2 halaman landing page ya.',
          time: formatTimeWib(now.subtract(const Duration(minutes: 9))),
        ),
        ChatMessage(
          text: 'Siap Rizkia! Untuk videonya tolong diedit dengan musik upbeat '
              'durasi 30 detik ya. Kita sepakati tenggat 4 hari pengerjaan?',
          time: formatTimeWib(now.subtract(const Duration(minutes: 6))),
          mine: true,
        ),
        ChatMessage(
          text: 'Deal! Saya konfirmasi kesepakatannya sekarang.',
          time: formatTimeWib(now.subtract(const Duration(minutes: 2))),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  ChatMessage _mapMsg(Map<String, dynamic> json, String? myId) {
    final senderId = (json['sender_id'] ?? '').toString().trim().toLowerCase();
    final me = (myId ?? '').trim().toLowerCase();
    final rawTime = json['dibuat_pada']?.toString();
    final dt = rawTime != null ? DateTime.tryParse(rawTime)?.toLocal() : null;
    return ChatMessage(
      text: (json['isi_pesan'] ?? '').toString(),
      time: formatTimeWib(dt ?? DateTime.now()),
      mine: me.isNotEmpty && senderId == me,
    );
  }

  Future<void> _loadMessages(String barterId, {bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final raw = await AppScope.of(context)
          .barterDataSource
          .listMessages(barterId);
      if (!mounted) return;
      final myId = AuthSession.instance.userId;
      setState(() {
        _messages = raw.map((m) => _mapMsg(m, myId)).toList(growable: false);
      });
    } catch (_) {
      // Abaikan gangguan polling sesaat
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _sendMessage(String text, BarterAgreementModel? b) async {
    if (b == null || b.id.isEmpty || AppConfig.useMockData) {
      final now = DateTime.now();
      setState(() {
        _messages = [
          ..._messages,
          ChatMessage(text: text, time: formatTimeWib(now), mine: true),
        ];
      });
      return true;
    }

    setState(() => _sending = true);
    try {
      final created = await AppScope.of(context).barterDataSource.sendMessage(
            barterId: b.id,
            isiPesan: text,
          );
      if (!mounted) return false;
      final myId = AuthSession.instance.userId;
      setState(() {
        _messages = [..._messages, _mapMsg(created, myId)];
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan barter: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _resolveBarter(context);
    if (b == null && !AppConfig.useMockData) {
      return SakuScreen(
        background: AppColors.canvasLight,
        showBack: true,
        children: [
          const PageHeader('Diskusi Smart Barter'),
          const InfoBox(
            text:
                'Pilih salah satu kontrak Smart Barter di tab Aktivitas Saya untuk membuka ruang diskusi dengan mitra.',
            tone: SakuTone.barter,
            fontWeight: FontWeight.w500,
          ),
          SakuButton(
            label: 'Kembali',
            variant: SakuButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    final myId = (AuthSession.instance.userId ?? '').trim().toLowerCase();
    final partnerName = b != null
        ? (myId == b.pengajuId.trim().toLowerCase()
            ? b.namaPenerima
            : b.namaPengaju)
        : DemoData.barter.partner;
    final displayPartner =
        partnerName.trim().isEmpty ? 'Mitra Barter' : partnerName.trim();

    final swapSummary = b != null
        ? '${b.deskripsiJasaPengaju} ⇄ ${b.deskripsiJasaPenerima}\nStatus: ${b.status} · Tenggat: ${formatDateId(b.tenggatPekerjaan)}'
        : '${DemoData.barter.mySkill} ⇄ ${DemoData.barter.partnerSkill}\nTenggat: 4 Hari Bersama';

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        PageHeader(displayPartner),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.barter,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Online · Sesi Realtime Aktif $_liveClock',
              style: const TextStyle(
                fontSize: 11,
                height: 15 / 11,
                fontWeight: FontWeight.w600,
                color: AppColors.barter,
              ),
            ),
          ],
        ),
        InfoBox(
          tone: SakuTone.barter,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const BarterEyebrow('KESEPAKATAN BARTER'),
              Text(
                swapSummary,
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SakuButton(
                key: const Key('barter-confirm-deal'),
                label: b != null
                    ? 'Buka Ruang Kerja & Status Barter'
                    : 'Konfirmasi Kesepakatan Barter',
                variant: SakuButtonVariant.barter,
                onPressed: () {
                  SakuMotion.tick();
                  Navigator.of(context).pushReplacementNamed(
                    AppRoutes.barterWorkroom,
                    arguments: b,
                  );
                },
              ),
            ],
          ),
        ),
        if (_loading && _messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (b != null && _messages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada pesan. Diskusikan detail pengerjaan & tenggat barter bersama mitra Anda di bawah.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ChatThread(
            barter: true,
            hint: 'Ketik pesan diskusi barter...',
            initial: _messages,
            messages: _messages,
            sending: _sending,
            onSendMessage: (text) => _sendMessage(text, b),
          ),
        ],
      ],
    );
  }
}
