import 'package:flutter/material.dart';

/// Token warna SakuSkill — sumber: Figma "Design guide" (v1.0, Nov 2026).
///
/// Gunakan token ini, JANGAN hardcode `Color(0xFF...)` di widget fitur,
/// supaya tema tetap konsisten antar-modul (Discovery, Escrow, Barter, dst).
abstract final class AppColors {
  // Brand / aksi utama
  static const Color primary = Color(0xFF059669); // Primary Emerald
  static const Color accent = Color(0xFF10B981); // Vibrant Accent
  static const Color primaryPressed = Color(0xFF047857); // Deep Hover
  static const Color primarySurface = Color(0xFFECFDF5); // Surface Tint

  // Netral gelap (forest-obsidian bernuansa emerald)
  static const Color deepCanvas = Color(0xFF0B1512);
  static const Color deepForestAccent = Color(0xFF0F2D24);
  static const Color cardSlate = Color(0xFF13221D);
  static const Color borderSlate = Color(0xFF283E36);

  // Teks & netral terang (mineral alabaster harmonis dengan Emerald)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textBody = Color(0xFF475569); // paragraf deskripsi
  static const Color borderLight = Color(0xFFE3E8E5);
  static const Color canvasLight = Color(0xFFF2F6F4);
  static const Color surfaceSubtle = Color(0xFFF0F4F2);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Permukaan Claymorphism & Glassmorphism
  static const Color glassFill = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0xEBFFFFFF);
  static const Color clayTop = Color(0xFFFFFFFF);
  static const Color clayBottom = Color(0xFFF7FAF8);
  static const Color clayBorder = Color(0xFFE6EFEA);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color barterLight = Color(0xFFA78BFA);

  // Warna fitur
  static const Color integrity = Color(0xFFF59E0B); // Anti-joki
  static const Color integritySurface = Color(0xFFFFFBEB);
  static const Color barter = Color(0xFF8B5CF6); // Smart Barter
  static const Color barterSurface = Color(0xFFF3E8FF);
  static const Color barterText = Color(0xFF7E22CE); // teks chip/badge barter
  static const Color barterBorder = Color(0xFFD8B4FE);
  static const Color escrow = Color(0xFF3B82F6); // Escrow Ledger
  static const Color escrowSurface = Color(0xFFEFF6FF);
  static const Color escrowText = Color(0xFF2563EB); // teks info escrow
  static const Color dispute = Color(0xFFEF4444); // Sidang etik
  static const Color disputeSurface = Color(0xFFFEF2F2);
  static const Color danger = Color(0xFFDC2626); // tombol destruktif & error

  // Peringatan tenggat (< 6 jam) — Warning Amber
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFFB45309);

  // Gelembung chat (Figma "Chat & service molecules")
  static const Color bubbleClient = Color(0xFFEEF2F0);
  static const Color bubbleProvider = Color(0xFFECFDF5);
  static const Color bubbleProviderText = Color(0xFF065F46);
  static const Color bubbleBarterText = Color(0xFF6B21A8); // chat barter
  static const Color dashedBorder = Color(0xFFCBD5E1);
  static const Color scrim = Color(0x8C0F172A); // latar bottom sheet

  // Peta kampus (fallback bila tile OSM tidak termuat)
  static const Color mapGreen = Color(0xFFEAF0E8);
  static const Color mapGreenDesign = Color(0xFFE8EFE9); // "Peta simulasi"
  static const Color mapBlock = Color(0xFFD5E3D7);
  static const Color mapCampus = Color(0xFFCDE3D2); // area kampus
  static const Color mapCampusLabel = Color(0xFF63806B);
  static const Color markerBorder = Color(0xFFA7F3D0); // pill marker talenta

  // Banner media detail layanan
  static const Color mediaGreen = Color(0xFF064E3B);
  static const Color mediaHighlight = Color(0xFFFDE047);
  static const Color bannerBody = Color(0xFFCBD5E1); // teks di banner gelap
}
