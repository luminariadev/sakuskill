import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Avatar clay medallion: menampilkan foto profil (bytes atau data-URI/URL)
/// bila tersedia, dan jatuh kembali secara mulus ke inisial nama pengguna.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 32,
    this.ringColor,
    this.photoUrl,
    this.imageBytes,
  });

  final String name;
  final double size;
  final Color? ringColor;
  final String? photoUrl;
  final Uint8List? imageBytes;

  static final Map<String, Uint8List?> _decodedCache = <String, Uint8List?>{};

  static const List<(Color, Color, Color)> _palettes = [
    (Color(0xFFE6FBF2), Color(0xFFC5F4DF), Color(0xFF047857)),
    (Color(0xFFF3EEFF), Color(0xFFE4D9FF), Color(0xFF6D28D9)),
    (Color(0xFFEAF2FF), Color(0xFFD5E5FF), Color(0xFF1D4ED8)),
    (Color(0xFFFFF8E1), Color(0xFFFEF0B8), Color(0xFFB45309)),
    (Color(0xFFFCEEF5), Color(0xFFFAD7E8), Color(0xFFBE185D)),
    (Color(0xFFE7F6FE), Color(0xFFCBEBFD), Color(0xFF0369A1)),
  ];

  static Uint8List? _decodeDataUri(String? raw) {
    if (raw == null || !raw.startsWith('data:image/')) return null;
    if (_decodedCache.containsKey(raw)) return _decodedCache[raw];
    final comma = raw.indexOf(',');
    if (comma < 0 || comma + 1 >= raw.length) {
      _decodedCache[raw] = null;
      return null;
    }
    try {
      final decoded = base64Decode(raw.substring(comma + 1));
      if (_decodedCache.length >= 24) {
        _decodedCache.remove(_decodedCache.keys.first);
      }
      _decodedCache[raw] = decoded;
      return decoded;
    } catch (_) {
      _decodedCache[raw] = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hash = name.codeUnits.fold<int>(0, (acc, c) => acc + c);
    final (topBg, bottomBg, fg) = _palettes[hash % _palettes.length];

    final fallbackInitials = Text(
      initialsOf(name),
      style: TextStyle(
        fontSize: size * 0.36,
        fontWeight: FontWeight.w800,
        color: fg,
      ),
    );

    final trimmedUrl = photoUrl?.trim();
    final memoryBytes = imageBytes ?? _decodeDataUri(trimmedUrl);

    Widget content = fallbackInitials;
    if (memoryBytes != null && memoryBytes.isNotEmpty) {
      content = ClipOval(
        child: Image.memory(
          memoryBytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Center(child: fallbackInitials),
        ),
      );
    } else if (trimmedUrl != null &&
        (trimmedUrl.startsWith('https://') || trimmedUrl.startsWith('http://'))) {
      content = ClipOval(
        child: Image.network(
          trimmedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Center(child: fallbackInitials),
        ),
      );
    }

    return Semantics(
      label: 'Avatar $name',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [topBg, bottomBg],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: ringColor ?? Colors.white,
            width: ringColor != null ? 2.4 : 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              offset: Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}
