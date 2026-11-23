import 'dart:async';

import 'package:flutter/material.dart';

import '../motion/saku_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/formatters.dart';
import 'saku_icon.dart';

/// Satu pesan chat.
class ChatMessage {
  const ChatMessage({required this.text, required this.time, this.mine = false});

  final String text;
  final String time;

  /// True = dikirim pengguna (gelembung hijau, ✓✓).
  final bool mine;
}

/// Gelembung chat (Figma "Chat & service molecules"): lebar maks 310,
/// padding 12, radius 14, teks 14/20. Klien abu #F1F5F9, saya hijau
/// #ECFDF5 dengan teks #065F46.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.barter = false});

  final ChatMessage message;

  /// Ruang barter: gelembung saya ungu (#F3E8FF / #6B21A8).
  final bool barter;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mine
                ? (barter ? AppColors.barterSurface : AppColors.bubbleProvider)
                : AppColors.bubbleClient,
            borderRadius: AppRadius.cardBr,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: mine
                      ? (barter
                          ? AppColors.bubbleBarterText
                          : AppColors.bubbleProviderText)
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                mine ? '${message.time}  ✓✓' : message.time,
                style: const TextStyle(
                  fontSize: 10,
                  height: 14 / 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daftar pesan + kolom ketik. Pesan baru meluncur masuk dari bawah.
/// Daftar pesan + kolom ketik. Pesan baru meluncur masuk dari bawah.
class ChatThread extends StatefulWidget {
  const ChatThread({
    super.key,
    required this.initial,
    this.messages,
    this.onSendMessage,
    this.sending = false,
    this.hint = 'Ketik pesan kesepakatan...',
    this.barter = false,
  });

  final List<ChatMessage> initial;
  final List<ChatMessage>? messages;
  final Future<bool> Function(String text)? onSendMessage;
  final bool sending;
  final String hint;
  final bool barter;

  @override
  State<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends State<ChatThread> {
  late final List<ChatMessage> _localMessages = [...widget.initial];
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || widget.sending) return;
    SakuMotion.tick();

    if (widget.onSendMessage != null) {
      final ok = await widget.onSendMessage!(text);
      if (ok && mounted) {
        _input.clear();
      }
      return;
    }

    final now = DateTime.now();
    setState(() {
      _localMessages.add(ChatMessage(
        text: text,
        time: formatTimeWib(now),
        mine: true,
      ));
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayed = widget.messages ?? _localMessages;
    return Column(
      spacing: 16,
      children: [
        for (var i = 0; i < displayed.length; i++)
          FadeSlideIn(
            key: ValueKey('msg-$i-${displayed[i].time}-${displayed[i].text.hashCode}'),
            index: i < widget.initial.length ? i : 0,
            child: ChatBubble(message: displayed[i], barter: widget.barter),
          ),
        ChatComposer(controller: _input, hint: widget.hint, onSend: _send),
      ],
    );
  }
}

/// Kolom ketik pesan (Figma "+  Ketik pesan kesepakatan...  ➤").
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.hint = 'Ketik pesan...',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const SakuIcon(SakuIcons.plus, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const Key('chat-input'),
              controller: controller,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('chat-send'),
            tooltip: 'Kirim',
            onPressed: onSend,
            icon: const SakuIcon(SakuIcons.send, size: 20, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

enum TimelineState { done, current, pending }

/// Timeline status vertikal (Figma "Milestone timeline"): ✓ selesai,
/// ● berjalan (bold), ○ menunggu (abu). Teks 12/17.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.items});

  final List<(String, TimelineState)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          for (var i = 0; i < items.length; i++)
            FadeSlideIn(
              index: i,
              offset: 6,
              child: Text(
                '${switch (items[i].$2) {
                  TimelineState.done => '✓',
                  TimelineState.current => '●',
                  TimelineState.pending => '○',
                }}  ${items[i].$1}',
                style: TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  fontWeight: items[i].$2 == TimelineState.current
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: items[i].$2 == TimelineState.pending
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu hitung mundur gelap (Figma "Countdown timer" / "Estimated
/// completion"). Angka berdetak tiap detik.
class CountdownCard extends StatefulWidget {
  const CountdownCard({
    super.key,
    required this.label,
    required this.remaining,
    this.note,
    this.color = AppColors.accent,
    this.showDays = false,
    this.fontSize = 22,
  });

  final String label;
  final Duration remaining;
  final String? note;
  final Color color;

  /// Format "02 Hari : 14 Jam : 30 Menit" (true) atau
  /// "04 Jam : 32 Menit : 15 Detik" (false).
  final bool showDays;
  final double fontSize;

  @override
  State<CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<CountdownCard> {
  late Duration _left = widget.remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _left = _left > const Duration(seconds: 1)
            ? _left - const Duration(seconds: 1)
            : Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _text {
    if (widget.showDays) {
      return '${_two(_left.inDays)} Hari : ${_two(_left.inHours % 24)} Jam : '
          '${_two(_left.inMinutes % 60)} Menit';
    }
    return '${_two(_left.inHours)} Jam : ${_two(_left.inMinutes % 60)} Menit : '
        '${_two(_left.inSeconds % 60)} Detik';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.deepCanvas,
        borderRadius: AppRadius.cardBr,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 10,
              height: 14 / 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          Semantics(
            liveRegion: false,
            label: 'Sisa waktu $_text',
            excludeSemantics: true,
            child: Text(
              _text,
              style: TextStyle(
                fontSize: widget.fontSize,
                height: 31 / 22,
                fontWeight: FontWeight.w700,
                color: widget.color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (widget.note != null)
            Text(
              widget.note!,
              style: const TextStyle(
                fontSize: 12,
                height: 17 / 12,
                color: AppColors.bannerBody,
              ),
            ),
        ],
      ),
    );
  }
}

/// Baris rincian "Harga jasa ……… Rp 50.000".
class AmountRow extends StatelessWidget {
  const AmountRow(this.label, this.value, {super.key, this.total = false});

  final String label;
  final String value;
  final bool total;

  @override
  Widget build(BuildContext context) {
    final style = total
        ? const TextStyle(
            fontSize: 18,
            height: 25 / 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          )
        : const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.textSecondary);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

/// Opsi pilihan berbingkai (metode bayar, jenis kompensasi): terpilih =
/// latar hijau muda + ◉ #047857; lainnya putih berborder + ○ abu.
class SelectableOption extends StatelessWidget {
  const SelectableOption({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryPressed : AppColors.textSecondary;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      child: PressableScale(
        scale: 0.985,
        onTap: () {
          SakuMotion.tick();
          onTap();
        },
        child: AnimatedContainer(
          duration: SakuMotion.base,
          curve: SakuMotion.curve,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : AppColors.cardSurface,
            borderRadius: AppRadius.cardBr,
            border: Border.all(
              color: selected ? AppColors.primarySurface : AppColors.borderLight,
            ),
          ),
          child: Text(
            '${selected ? '◉' : '○'} $title'
            '${subtitle != null ? '\n    $subtitle' : ''}',
            style: TextStyle(
              fontSize: 12,
              height: 17 / 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bilah progres 6 px (Figma "Progress 75%"): mengisi dari 0 ke [value]
/// dalam 700 ms saat tampil, dan beranimasi saat nilai berubah.
class SakuProgressBar extends StatelessWidget {
  const SakuProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.height = 6,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: '${(value * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: SakuMotion.reduced(context)
            ? Duration.zero
            : const Duration(milliseconds: 700),
        curve: SakuMotion.curve,
        builder: (_, v, __) => ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(height: height, color: AppColors.borderLight),
              FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pilihan segmen sebaris di dalam kotak hijau (Figma "+6 Jam ◉ +12 Jam
/// +24 Jam").
class InlineChoice extends StatelessWidget {
  const InlineChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadius.cardBr,
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: i == selected,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    SakuMotion.tick();
                    onChanged(i);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: AnimatedDefaultTextStyle(
                      duration: SakuMotion.fast,
                      style: TextStyle(
                        fontSize: 12,
                        height: 17 / 12,
                        fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.primaryPressed,
                      ),
                      child: Text(i == selected ? '◉ ${options[i]}' : options[i]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lingkaran sukses 64 px dengan ✓ (Figma "Success icon"). Muncul sekali
/// dengan skala 0.7 → 1 (easeOutBack, 420 ms) — perayaan kecil, tidak heboh.
class SuccessBadge extends StatelessWidget {
  const SuccessBadge({super.key, this.color = AppColors.primary, this.surface = AppColors.primarySurface});

  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
      child: SakuIcon(SakuIcons.check, size: 32, color: color),
    );
    if (SakuMotion.reduced(context)) return badge;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: badge,
    );
  }
}

/// Rating bintang 32 px amber (Figma "★ ★ ★ ★ ★"); bintang yang dipilih
/// membesar sebentar.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 14,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i <= value,
            label: 'Beri $i bintang',
            excludeSemantics: true,
            child: PressableScale(
              scale: 0.85,
              onTap: () {
                SakuMotion.tick();
                onChanged(i);
              },
              child: AnimatedSwitcher(
                duration: SakuMotion.fast,
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Text(
                  i <= value ? '★' : '☆',
                  key: ValueKey(i <= value),
                  style: const TextStyle(
                    fontSize: 32,
                    height: 45 / 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
