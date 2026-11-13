import 'dart:math' as math;

/// Titik koordinat WGS84 murni (tanpa dependensi paket peta), dipakai di
/// lapisan domain. Lapisan presentasi mengonversinya ke `LatLng` flutter_map.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude)
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// Perhitungan jarak great-circle dengan rumus Haversine.
///
///   a = sin²(Δφ/2) + cos φ1 · cos φ2 · sin²(Δλ/2)
///   d = 2R · atan2(√a, √(1−a))
///
/// R = 6.371.008,8 m (mean Earth radius, IUGG). Galat < 0,5% untuk skala
/// kampus — cukup untuk filter radius 500 m–3 km.
abstract final class Haversine {
  static const double earthRadiusMeters = 6371008.8;

  static double distanceMeters(GeoPoint a, GeoPoint b) {
    final phi1 = _toRad(a.latitude);
    final phi2 = _toRad(b.latitude);
    final dPhi = _toRad(b.latitude - a.latitude);
    final dLambda = _toRad(b.longitude - a.longitude);

    final h = math.pow(math.sin(dPhi / 2), 2) +
        math.cos(phi1) * math.cos(phi2) * math.pow(math.sin(dLambda / 2), 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusMeters * c;
  }

  static double distanceKm(GeoPoint a, GeoPoint b) =>
      distanceMeters(a, b) / 1000;

  static bool isWithinRadius(GeoPoint origin, GeoPoint target, double radiusM) =>
      distanceMeters(origin, target) <= radiusM;

  static double _toRad(double deg) => deg * math.pi / 180;
}

/// Format jarak untuk UI: "250 m", "0.8 km", "2.4 km".
String formatDistance(double meters) {
  if (meters < 1000) {
    final rounded = (meters / 10).round() * 10;
    return '$rounded m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Estimasi waktu jalan kaki (~80 m/menit ≈ 4,8 km/jam).
int walkingMinutes(double meters) => math.max(1, (meters / 80).round());
