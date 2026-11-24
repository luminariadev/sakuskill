import 'package:flutter/material.dart';

import '../motion/saku_motion.dart';
import '../theme/app_colors.dart';
import 'saku_icon.dart';

/// Kerangka layar dari Figma ("Scrollable screen"): padding 20 sisi,
/// 16 atas, 24 bawah, jarak antar-elemen [gap] (default 16).
///
/// Anak-anak muncul bertahap (fade + geser 10 px) — micro-interaction
/// pembuka yang ringan. [bottomBar] tetap menempel di bawah (mis. aksi
/// "Sticky service actions").
class SakuScreen extends StatelessWidget {
  const SakuScreen({
    super.key,
    required this.children,
    this.background = AppColors.cardSurface,
    this.gap = 16,
    this.showBack = false,
    this.onBack,
    this.bottomBar,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
    this.animateIn = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final Color background;
  final double gap;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? bottomBar;
  final EdgeInsets padding;
  final bool animateIn;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (showBack)
        BackArrowButton(onPressed: onBack),
      ...children,
    ];
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: bottomBar == null,
        child: SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            spacing: gap,
            children: [
              for (var i = 0; i < items.length; i++)
                animateIn ? FadeSlideIn(index: i, child: items[i]) : items[i],
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// Panah kembali hijau (Figma "←" 22–24px emerald).
class BackArrowButton extends StatelessWidget {
  const BackArrowButton({super.key, this.onPressed, this.color = AppColors.primary});

  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Kembali',
      excludeSemantics: true,
      child: PressableScale(
        scale: 0.9,
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: SakuIcon(SakuIcons.back, size: 24, color: color),
        ),
      ),
    );
  }
}

/// Header halaman dengan panah kembali + judul satu baris (layar transaksi).
class SakuTopBar extends StatelessWidget {
  const SakuTopBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BackArrowButton(onPressed: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Bar aksi bawah putih dengan garis atas (dipakai layar dengan CTA tetap).
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: child,
        ),
      ),
    );
  }
}
