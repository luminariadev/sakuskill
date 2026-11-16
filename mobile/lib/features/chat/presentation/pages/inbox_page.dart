import 'package:material_ui/material_ui.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../discovery/presentation/widgets/discovery_filters.dart';

/// Figma "8 · Pesan & diskusi" — tab Chat.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  ConversationKind? _filter;

  @override
  Widget build(BuildContext context) {
    const all = DemoData.conversations;
    int count(ConversationKind k) => all.where((c) => c.kind == k).length;
    final visible =
        _filter == null ? all : all.where((c) => c.kind == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const PageHeader(
              'Pesan & Diskusi',
              subtitle: 'Diskusi lancar, kolaborasi lebih dekat.',
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  FilterChipPill(
                    label: 'Semua (${all.length})',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  FilterChipPill(
                    key: const Key('inbox-escrow'),
                    label: 'Pesanan Escrow (${count(ConversationKind.escrow)})',
                    selected: _filter == ConversationKind.escrow,
                    onTap: () => setState(() => _filter = ConversationKind.escrow),
                  ),
                  FilterChipPill(
                    label: 'Smart Barter (${count(ConversationKind.barter)})',
                    selected: _filter == ConversationKind.barter,
                    onTap: () => setState(() => _filter = ConversationKind.barter),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: SakuMotion.base,
              child: Column(
                key: ValueKey(_filter),
                spacing: 16,
                children: [
                  for (var i = 0; i < visible.length; i++)
                    FadeSlideIn(
                      index: i,
                      child: _ConversationCard(conversation: visible[i]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation});

  final DemoConversation conversation;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final route = switch (c.kind) {
      ConversationKind.escrow => AppRoutes.orderChat,
      ConversationKind.barter => AppRoutes.barterChat,
      ConversationKind.support => AppRoutes.complaint,
    };
    return SakuCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          PersonRow(
            name: c.name,
            subtitle: c.subtitle,
            asset: c.asset,
            leading: c.kind == ConversationKind.support
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: SakuIcon(SakuIcons.shield, size: 32, color: AppColors.primary),
                  )
                : null,
          ),
          if (c.contextLabel != null)
            StatusStrip(
              c.contextLabel!,
              tone: c.kind == ConversationKind.barter
                  ? SakuTone.barter
                  : SakuTone.escrow,
            ),
          Text(
            c.lastMessage,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            c.unread > 0 ? '${c.time}   ● ${c.unread} pesan baru' : c.time,
            style: TextStyle(
              fontSize: 10,
              height: 14 / 10,
              fontWeight: FontWeight.w600,
              color: c.unread > 0 ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
