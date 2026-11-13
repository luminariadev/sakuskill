import '../../../../core/config/app_config.dart';
import '../../../../core/utils/geo.dart';

/// Kriteria pencarian Discovery. Immutable — ubah lewat [copyWith].
class DiscoveryFilter {
  const DiscoveryFilter({
    this.query = '',
    this.categoryId,
    this.radiusMeters = AppConfig.defaultRadiusMeters,
    this.barterOnly = false,
    this.origin = AppConfig.campusCenter,
  });

  final String query;

  /// Null = semua kategori.
  final String? categoryId;
  final int radiusMeters;

  /// True = hanya listing yang menerima Smart Barter.
  final bool barterOnly;

  /// Titik asal perhitungan jarak (lokasi pengguna / pusat kampus).
  final GeoPoint origin;

  bool get hasQuery => query.trim().isNotEmpty;

  DiscoveryFilter copyWith({
    String? query,
    String? categoryId,
    bool clearCategory = false,
    int? radiusMeters,
    bool? barterOnly,
    GeoPoint? origin,
  }) {
    return DiscoveryFilter(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      radiusMeters: radiusMeters ?? this.radiusMeters,
      barterOnly: barterOnly ?? this.barterOnly,
      origin: origin ?? this.origin,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoveryFilter &&
      other.query == query &&
      other.categoryId == categoryId &&
      other.radiusMeters == radiusMeters &&
      other.barterOnly == barterOnly &&
      other.origin == origin;

  @override
  int get hashCode =>
      Object.hash(query, categoryId, radiusMeters, barterOnly, origin);
}
