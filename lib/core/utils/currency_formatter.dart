import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class FormatterUtils {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatIDR(int amount) {
    return _currencyFormat.format(amount);
  }

  /// Haversine formula computation in pure Dart for zero-overhead local distance calculation
  static double calculateDistanceKm(LatLng point1, LatLng point2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    final double dLon = _degreesToRadians(point2.longitude - point1.longitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(point1.latitude)) *
            math.cos(_degreesToRadians(point2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadiusKm * c;
    return (distance * 10).round() / 10.0;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
