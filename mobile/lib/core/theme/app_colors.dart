import 'package:flutter/material.dart';

/// Token warna SakuSkill — sumber: Figma "00 · SakuSkill design system".
///
/// Gunakan token ini, JANGAN hardcode `Color(0xFF...)` di widget fitur,
/// supaya tema tetap konsisten antar-modul (Discovery, Escrow, Barter, dst).
abstract final class AppColors {
  // Brand / aksi utama
  static const Color primary = Color(0xFF059669); // Primary Emerald
  static const Color accent = Color(0xFF10B981); // Vibrant Accent
  static const Color primaryPressed = Color(0xFF047857); // Deep Hover
  static const Color primarySurface = Color(0xFFECFDF5); // Surface Tint

  // Netral gelap
  static const Color deepCanvas = Color(0xFF0F172A);
  static const Color cardSlate = Color(0xFF1E293B);
  static const Color borderSlate = Color(0xFF334155);

  // Teks & netral terang
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color canvasLight = Color(0xFFF8FAFC);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Warna fitur
  static const Color integrity = Color(0xFFF59E0B); // Anti-joki
  static const Color integritySurface = Color(0xFFFFFBEB);
  static const Color barter = Color(0xFF8B5CF6); // Smart Barter
  static const Color barterSurface = Color(0xFFF3E8FF);
  static const Color escrow = Color(0xFF3B82F6); // Escrow Ledger
  static const Color escrowSurface = Color(0xFFEFF6FF);
  static const Color dispute = Color(0xFFEF4444); // Sidang etik
  static const Color disputeSurface = Color(0xFFFEF2F2);

  // Peta kampus (fallback bila tile OSM tidak termuat)
  static const Color mapGreen = Color(0xFFE3EEDD);
}
