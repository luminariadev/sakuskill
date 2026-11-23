import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../widgets/barter_widgets.dart';

/// Figma "22 · Diskusi barter" — chat dengan kesepakatan barter tersemat.
class BarterChatPage extends StatefulWidget {
  const BarterChatPage({super.key});

  @override
  State<BarterChatPage> createState() => _BarterChatPageState();
}

class _BarterChatPageState extends State<BarterChatPage> {
  Timer? _clockTimer;
  String _liveClock = formatClockSeconds(DateTime.now());
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _messages = [
      ChatMessage(
        text: 'Halo Salma! Keren banget, saya butuh desain UI 2 halaman landing page ya.',
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

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _liveClock = formatClockSeconds(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<bool> _sendMessage(String text) async {
    final now = DateTime.now();
    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(
          text: text,
          time: formatTimeWib(now),
          mine: true,
        ),
      ];
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const barter = DemoData.barter;
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        PageHeader(barter.partner),
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
                '${barter.mySkill} ⇄ ${barter.partnerSkill}\nTenggat: 4 Hari Bersama',
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SakuButton(
                key: const Key('barter-confirm-deal'),
                label: 'Konfirmasi Kesepakatan Barter',
                variant: SakuButtonVariant.barter,
                onPressed: () {
                  SakuMotion.tick();
                  Navigator.of(context).pushReplacementNamed(AppRoutes.barterWorkroom);
                },
              ),
            ],
          ),
        ),
        ChatThread(
          barter: true,
          hint: 'Ketik pesan diskusi barter...',
          initial: _messages,
          messages: _messages,
          onSendMessage: _sendMessage,
        ),
      ],
    );
  }
}
