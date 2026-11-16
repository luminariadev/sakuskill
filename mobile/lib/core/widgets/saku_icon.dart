import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

/// Ikon garis SakuSkill (Figma "User Design / 00 · Design guide" → 04 Icons:
/// 24px, stroke 1.8px, rounded caps). File SVG ada di `assets/icons/`.
enum SakuIcons {
  home,
  compass,
  plus,
  chat,
  briefcase,
  shield,
  wallet,
  lock,
  check,
  clock,
  search,
  pin,
  star,
  alert,
  swap,
  back,
  send,
  clip,
  eye,
  filter,
  scale,
  chevron,
  upload,
  mail,
  bookmark,
  camera,
  bell,
  share,
  user,
  orders;

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

/// Emblem SakuSkill (kotak hijau + saku-perisai + infinity + sparkle),
/// disusun dari 4 SVG Figma dengan inset yang sama seperti di desain.
class SakuEmblem extends StatelessWidget {
  const SakuEmblem({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget part(String name, EdgeInsets inset) => Positioned(
          left: inset.left * size,
          top: inset.top * size,
          right: inset.right * size,
          bottom: inset.bottom * size,
          child: SvgPicture.asset('assets/icons/$name.svg', fit: BoxFit.fill),
        );
    return Semantics(
      label: 'Logo SakuSkill',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            part('emblem_base', const EdgeInsets.all(0.0625)),
            // Inset sudah memperhitungkan overflow stroke di Figma
            // (inset negatif -5.4%/-4.38% dan -3.99%/-11.88%).
            part('emblem_shield',
                const EdgeInsets.fromLTRB(0.3095, 0.2900, 0.3095, 0.2490)),
            part('emblem_infinity',
                const EdgeInsets.fromLTRB(0.2490, 0.3935, 0.2490, 0.4130)),
            part('emblem_sparkle',
                const EdgeInsets.fromLTRB(0.6895, 0.2129, 0.2168, 0.6934)),
          ],
        ),
      ),
    );
  }
}
