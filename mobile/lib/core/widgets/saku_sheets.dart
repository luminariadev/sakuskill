import 'dart:ui';

import 'package:flutter/material.dart';

import '../motion/saku_motion.dart';
import '../theme/app_colors.dart';
import 'saku_buttons.dart';

/// Bottom sheet SakuSkill (Glassmorphism + Claymorphism): radius atas 28,
/// padding 20, drag handle 36×4, jarak antar-elemen 10.
/// Muncul dari bawah 280 ms easeOutCubic di atas scrim slate.
Future<T?> showSakuSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Handle digambar sendiri sesuai Figma (36×4 #CBD5E1).
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 280),
      reverseDuration: Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xEBFFFFFF),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: 1.2,
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dashedBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    builder(ctx),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Isi standar sheet konfirmasi: judul 18/700, pesan 12, [body] bebas,
/// tombol konfirmasi, dan tautan batal di tengah.
class SakuSheetContent extends StatelessWidget {
  const SakuSheetContent({
    super.key,
    required this.title,
    this.message,
    this.body = const [],
    required this.confirmLabel,
    required this.onConfirm,
    this.confirmVariant = SakuButtonVariant.primary,
    this.cancelLabel = 'Kembali',
    this.secondary,
  });

  final String title;
  final String? message;
  final List<Widget> body;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final SakuButtonVariant confirmVariant;
  final String cancelLabel;

  /// Tombol kedua opsional di bawah konfirmasi (mis. "Tolak").
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            height: 25 / 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (message != null)
          Text(
            message!,
            style: const TextStyle(
              fontSize: 12,
              height: 17 / 12,
              color: AppColors.textSecondary,
            ),
          ),
        ...body,
        SakuButton(
          key: const Key('sheet-confirm'),
          label: confirmLabel,
          variant: confirmVariant,
          onPressed: onConfirm,
        ),
        if (secondary != null) secondary!,
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: Text(cancelLabel),
          ),
        ),
      ],
    );
  }
}

/// Daftar pilihan radio teks (◉ terpilih emerald semibold, ○ abu).
/// Penanda berganti dengan transisi skala singkat.
class RadioOptions extends StatelessWidget {
  const RadioOptions({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.activeColor = AppColors.primary,
    this.fontSize = 12,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final Color activeColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        for (var i = 0; i < options.length; i++)
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: i == selected,
            label: options[i],
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                SakuMotion.tick();
                onChanged(i);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: SakuMotion.fast,
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Text(
                      i == selected ? '◉ ' : '○ ',
                      key: ValueKey(i == selected),
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 17 / 12,
                        color: i == selected ? activeColor : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: SakuMotion.fast,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 17 / 12,
                        fontWeight: i == selected ? FontWeight.w600 : FontWeight.w400,
                        color: i == selected ? activeColor : AppColors.textSecondary,
                      ),
                      child: Text(options[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
