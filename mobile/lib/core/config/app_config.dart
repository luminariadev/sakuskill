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

  /// Tile peta: data OpenStreetMap dengan gaya CARTO Voyager (warna lembut,
  /// paling mirip ilustrasi peta di Figma). Ganti ke [osmStandardTileUrl]
  /// bila ingin tile OSM standar.
  static const String mapTileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const List<String> mapTileSubdomains = ['a', 'b', 'c', 'd'];
  static const String mapAttribution = '© OpenStreetMap contributors © CARTO';

  static const String osmStandardTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'id.ac.uinsgd.sakuskill';
}
