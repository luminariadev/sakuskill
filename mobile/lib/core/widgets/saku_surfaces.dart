import 'package:flutter/material.dart';

import '../motion/saku_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Nada warna semantik dari design guide.
enum SakuTone { success, barter, escrow, danger, warning, neutral, dark }

extension SakuToneColors on SakuTone {
  Color get surface => switch (this) {
        SakuTone.success => AppColors.primarySurface,
        SakuTone.barter => AppColors.barterSurface,
        SakuTone.escrow => AppColors.escrowSurface,
        SakuTone.danger => AppColors.disputeSurface,
        SakuTone.warning => AppColors.warningSurface,
        SakuTone.neutral => AppColors.canvasLight,
        SakuTone.dark => AppColors.deepCanvas,
      };

  /// Teks info box per nada.
  Color get text => switch (this) {
        SakuTone.success => AppColors.primaryPressed,
        SakuTone.barter => AppColors.barterText,
        SakuTone.escrow => AppColors.escrowText,
        SakuTone.danger => AppColors.danger,
        SakuTone.warning => AppColors.warningText,
        SakuTone.neutral => AppColors.textSecondary,
        SakuTone.dark => Colors.white,
      };

  /// Warna badge status (sedikit berbeda dari teks info box).
  Color get badgeText => switch (this) {
        SakuTone.escrow => AppColors.escrow,
        _ => text,
      };
}

/// Kotak informasi berwarna (Figma "Information"): padding 12, radius 14,
/// teks 12/17. Bisa berisi teks atau widget bebas.
class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    this.text,
    this.child,
    this.tone = SakuTone.success,
    this.padding = const EdgeInsets.all(12),
    this.fontWeight = FontWeight.w400,
  }) : assert(text != null || child != null);

  final String? text;
  final Widget? child;
  final SakuTone tone;
  final EdgeInsets padding;

  /// Notice di alur transaksi memakai 500 (Figma "Notice · …").
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: AppRadius.cardBr,
      ),
      child: child ??
          Text(
            text!,
            style: TextStyle(
              fontSize: 12,
              height: 17 / 12,
              fontWeight: fontWeight,
              color: tone.text,
            ),
          ),
    );
  }
}

/// Badge status pill (Figma "SakuSkill / Status badge"): tinggi 30,
/// teks 11/700 kapital. Muncul dengan transisi warna saat status berubah.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, required this.tone});

  final String label;
  final SakuTone tone;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SakuMotion.base,
      curve: SakuMotion.curve,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: AppRadius.pillBr,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          height: 15 / 11,
          fontWeight: FontWeight.w700,
          color: tone.badgeText,
        ),
      ),
    );
  }
}

/// Kartu putih radius 14 (kartu layanan / ringkasan). Bila [onTap] diisi,
/// kartu mengecil halus saat ditekan.
class SakuCard extends StatelessWidget {
  const SakuCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.cardSurface,
    this.border = true,
    this.elevated = true,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color color;
  final bool border;
  final bool elevated;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final useShadow = elevated && color == AppColors.cardSurface;
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border ? Border.all(color: AppColors.borderLight) : null,
        boxShadow: useShadow ? AppShadows.card : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return PressableScale(scale: 0.985, onTap: onTap, child: card);
  }
}

/// Label bagian kecil kapital abu ("MILESTONE & COUNTDOWN").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.textSecondary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        height: 15 / 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// Avatar foto bulat dari aset lokal; jatuh ke inisial bila [asset] null.
class PhotoAvatar extends StatelessWidget {
  const PhotoAvatar({
    super.key,
    required this.name,
    this.asset,
    this.size = 40,
  });

  final String name;
  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Semantics(
      label: 'Foto $name',
      image: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: asset != null
              ? Image.asset(asset!, fit: BoxFit.cover)
              : Container(
                  color: AppColors.primarySurface,
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPressed,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Strip status (Figma "Status · …"): padding 10, radius 14, teks 11/600.
class StatusStrip extends StatelessWidget {
  const StatusStrip(
    this.text, {
    super.key,
    this.tone = SakuTone.neutral,
    this.bordered = false,
    this.trailing,
    this.onTap,
    this.textColor,
    this.background,
  });

  final String text;
  final SakuTone tone;
  final bool bordered;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final box = AnimatedContainer(
      duration: SakuMotion.base,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background ?? tone.surface,
        borderRadius: AppRadius.cardBr,
        border: bordered ? Border.all(color: AppColors.borderLight) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                height: 15 / 11,
                fontWeight: FontWeight.w600,
                color: textColor ?? tone.text,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
    if (onTap == null) return box;
    return PressableScale(scale: 0.985, onTap: onTap, child: box);
  }
}

/// Baris orang: avatar 40 + nama 13/700 + keterangan 11 (tinggi 48).
class PersonRow extends StatelessWidget {
  const PersonRow({
    super.key,
    required this.name,
    this.subtitle,
    this.asset,
    this.avatarSize = 40,
    this.trailing,
    this.leading,
  });

  final String name;
  final String? subtitle;
  final String? asset;
  final double avatarSize;
  final Widget? trailing;

  /// Pengganti avatar (mis. ikon perisai admin).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading ?? PhotoAvatar(name: name, asset: asset, size: avatarSize),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Judul halaman 24/800 + subjudul 13 (layar tab & daftar).
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.subtitle, this.titleSize = 24});

  final String title;
  final String? subtitle;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            height: 32 / 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              height: 19 / 13,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// Langkah milestone escrow (Figma "✓ Dana Ditahan → ● Dikerjakan /
/// ○ Bukti Dikirim → ○ Dana Dilepas"). [current] = indeks langkah aktif;
/// langkah sebelumnya ✓, aktif ●, sesudahnya ○ abu.
class MilestoneSteps extends StatelessWidget {
  const MilestoneSteps({
    super.key,
    required this.current,
    this.steps = const ['Dana Ditahan', 'Dikerjakan', 'Bukti Dikirim', 'Dana Dilepas'],
    this.separator = ' → ',
    this.allGreen = true,
    this.fontSize = 12,
  });

  final int current;
  final List<String> steps;
  final String separator;

  /// Di kartu Aktivitas semua langkah berwarna emerald.
  final bool allGreen;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    TextSpan step(int i) {
      final done = i < current;
      final active = i == current;
      final mark = done ? '✓' : (active ? '●' : '○');
      final color = (done || active || allGreen)
          ? AppColors.primary
          : AppColors.textSecondary;
      return TextSpan(
        text: '$mark ${steps[i]}',
        style: TextStyle(
          color: color,
          fontWeight: done || active || allGreen ? FontWeight.w600 : FontWeight.w400,
        ),
      );
    }

    final lines = <InlineSpan>[];
    for (var i = 0; i < steps.length; i++) {
      lines.add(step(i));
      if (i.isEven && i + 1 < steps.length) {
        lines.add(TextSpan(
          text: separator,
          style: TextStyle(
            color: (i + 1 <= current || allGreen)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ));
      } else if (i.isOdd && i + 1 < steps.length) {
        lines.add(const TextSpan(text: '\n'));
      }
    }
    return Semantics(
      label: 'Tahap ${current + 1} dari ${steps.length}: ${steps[current.clamp(0, steps.length - 1)]}',
      excludeSemantics: true,
      child: AnimatedSwitcher(
        duration: SakuMotion.base,
        child: Text.rich(
          TextSpan(children: lines),
          key: ValueKey(current),
          style: TextStyle(fontSize: fontSize, height: 17 / 12),
        ),
      ),
    );
  }
}
