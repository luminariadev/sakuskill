import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../widgets/barter_widgets.dart';

/// Figma "22 · Diskusi barter" — chat dengan kesepakatan barter tersemat.
class BarterChatPage extends StatelessWidget {
  const BarterChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    const barter = DemoData.barter;
    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        PageHeader(barter.partner),
        const Text(
          'Diskusi Ruang Lingkup & Tenggat Barter',
          style: TextStyle(fontSize: 12, height: 17 / 12, color: AppColors.textSecondary),
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
        const ChatThread(
          barter: true,
          hint: 'Ketik pesan diskusi barter...',
          initial: [
            ChatMessage(
              text: 'Halo Salma! Keren banget, saya butuh desain UI 2 halaman landing page ya.',
              time: '10:12',
            ),
            ChatMessage(
              text: 'Siap Rizkia! Untuk videonya tolong diedit dengan musik upbeat '
                  'durasi 30 detik ya. Kita sepakati tenggat 4 hari pengerjaan?',
              time: '10:14',
              mine: true,
            ),
            ChatMessage(
              text: 'Deal! Saya konfirmasi kesepakatannya sekarang.',
              time: '10:15',
            ),
          ],
        ),
      ],
    );
  }
}
