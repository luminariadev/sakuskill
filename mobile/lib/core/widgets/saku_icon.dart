import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

/// Ikon garis SakuSkill (Figma "Design guide" → 04 / Ikon: 24px, stroke
/// 1.8px). File SVG diekspor dari Figma ke `assets/icons/`.
enum SakuIcons {
  home,
  compass,
  orders,
  swap,
  user,
  bell,
  pin,
  search,
  shield,
  back,
  share,
  bookmark;

  String get asset => 'assets/icons/$name.svg';
}

/// Menampilkan [SakuIcons] dengan warna tema — warna stroke asli SVG
/// diganti lewat [ColorFilter] agar satu file bisa dipakai aktif/nonaktif.
class SakuIcon extends StatelessWidget {
  const SakuIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.semanticLabel,
  });

  final SakuIcons icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color;
    return SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      colorFilter: c == null ? null : ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}
