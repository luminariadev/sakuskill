import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Avatar inisial (placeholder sampai foto profil tersedia dari backend).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 32,
    this.ringColor,
  });

  final String name;
  final double size;
  final Color? ringColor;

  static const List<(Color, Color)> _palettes = [
    (Color(0xFFD1FAE5), Color(0xFF047857)),
    (Color(0xFFEDE9FE), Color(0xFF6D28D9)),
    (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    (Color(0xFFFEF3C7), Color(0xFFB45309)),
    (Color(0xFFFCE7F3), Color(0xFFBE185D)),
    (Color(0xFFE0F2FE), Color(0xFF0369A1)),
  ];

  @override
  Widget build(BuildContext context) {
    final hash = name.codeUnits.fold<int>(0, (acc, c) => acc + c);
    final (bg, fg) = _palettes[hash % _palettes.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: ringColor != null
            ? Border.all(color: ringColor!, width: 2.5)
            : Border.all(color: AppColors.cardSurface, width: 1.5),
      ),
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
