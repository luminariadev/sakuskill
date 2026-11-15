import 'package:flutter/foundation.dart';

import '../utils/geo.dart';

/// Konfigurasi runtime. Bisa diubah tanpa mengedit kode lewat --dart-define:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
///   flutter run --dart-define=USE_MOCK_DATA=true
abstract final class AppConfig {
  static const String _apiOverride = String.fromEnvironment('API_BASE_URL');

  /// Paksa memakai data contoh lokal (berguna untuk demo / saat backend mati).
  static const bool useMockData = bool.fromEnvironment('USE_MOCK_DATA');

  /// Base URL sesuai docs/API_CONTRACT.md. Emulator Android memakai 10.0.2.2.
  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) return _apiOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  static const Duration networkTimeout = Duration(seconds: 6);

  /// Titik pusat default: UIN Sunan Gunung Djati Kampus 1, Jl. A.H. Nasution,
  /// Cibiru, Bandung. Dipakai sebagai lokasi pengguna sampai modul lokasi
  /// perangkat (GPS) tersedia.
  static const GeoPoint campusCenter = GeoPoint(-6.93105, 107.71745);
  static const String campusLabel = 'Cibiru';

  /// Opsi radius (meter). Backend menerima radius_m >= 100.
  static const List<int> radiusOptions = [500, 1000, 2000, 3000];
  static const int defaultRadiusMeters = 2000;

  /// Ambang chip "4.8+" (rating penyedia) di Beranda.
  static const double topRatedThreshold = 4.8;

  /// Tile peta: OpenStreetMap standar (user agent diisi sesuai kebijakan
  /// tile OSM).
  ///
  /// Catatan: CARTO kini meminta API key (tile tampil "API KEY REQUIRED"),
  /// jadi default memakai tile OSM standar.
  static const String mapTileUrl = osmStandardTileUrl;
  static const List<String> mapTileSubdomains = <String>[];
  static const String mapAttribution = '© OpenStreetMap contributors';

  static const String osmStandardTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'id.ac.uinsgd.sakuskill';
}
