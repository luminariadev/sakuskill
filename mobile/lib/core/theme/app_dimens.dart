import 'package:flutter/material.dart';

/// Geometri dari design system: radius 4 / 8 / 14 / pill, spacing kelipatan 4.
abstract final class AppRadius {
  static const double tag = 4;
  static const double input = 8; // tombol & input
  static const double card = 14; // kartu & banner
  static const double pill = 999;

  static const BorderRadius tagBr = BorderRadius.all(Radius.circular(tag));
  static const BorderRadius inputBr = BorderRadius.all(Radius.circular(input));
  static const BorderRadius cardBr = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillBr = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // padding horizontal layar mobile
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
}

abstract final class AppShadows {
  /// "Flat 0 1px 3px / 5%"
  static const List<BoxShadow> flat = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Dual-layer ambient shadow halus untuk kartu di atas kanvas mineral.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0B1512), offset: Offset(0, 4), blurRadius: 12),
    BoxShadow(color: Color(0x050B1512), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Elevasi lebih dalam untuk kartu hero, banner escrow, dan overlay peta.
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x160B1512), offset: Offset(0, 8), blurRadius: 24),
  ];

  /// Bayangan atas lembut untuk bottom navigation bar.
  static const List<BoxShadow> navBar = [
    BoxShadow(color: Color(0x0D0B1512), offset: Offset(0, -3), blurRadius: 14),
  ];

  /// "Emerald glow" untuk tombol mengambang.
  static const List<BoxShadow> emeraldGlow = [
    BoxShadow(color: Color(0x40059669), offset: Offset(0, 4), blurRadius: 14),
  ];
}
