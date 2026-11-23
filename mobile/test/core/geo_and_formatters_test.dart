import 'package:flutter_test/flutter_test.dart';
import 'package:sakuskill/core/utils/formatters.dart';
import 'package:sakuskill/core/utils/geo.dart';

void main() {
  group('Haversine', () {
    const campus = GeoPoint(-6.93105, 107.71745);

    test('jarak titik yang sama = 0', () {
      expect(Haversine.distanceMeters(campus, campus), 0);
    });

    test('1 derajat bujur di ekuator ≈ 111,2 km', () {
      final d = Haversine.distanceMeters(
        const GeoPoint(0, 0),
        const GeoPoint(0, 1),
      );
      expect(d, closeTo(111195, 5));
    });

    test('Gedung Sate → UIN SGD Cibiru ≈ 11,34 km', () {
      final d = Haversine.distanceKm(const GeoPoint(-6.9025, 107.6188), campus);
      expect(d, closeTo(11.34, 0.01));
    });

    test('simetris (A→B = B→A)', () {
      const other = GeoPoint(-6.9290, 107.7190);
      expect(
        Haversine.distanceMeters(campus, other),
        closeTo(Haversine.distanceMeters(other, campus), 1e-9),
      );
    });

    test('isWithinRadius', () {
      const near = GeoPoint(-6.92945, 107.7159); // ≈ 243 m
      expect(Haversine.isWithinRadius(campus, near, 500), isTrue);
      expect(Haversine.isWithinRadius(campus, near, 200), isFalse);
    });
  });

  group('format', () {
    test('formatDistance', () {
      expect(formatDistance(243), '240 m');
      expect(formatDistance(832), '830 m');
      expect(formatDistance(1221), '1.2 km');
    });

    test('formatRupiah', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(35000), 'Rp 35.000');
      expect(formatRupiah(150000), 'Rp 150.000');
      expect(formatRupiah(1250000), 'Rp 1.250.000');
    });

    test('initialsOf', () {
      expect(initialsOf('Ahmad Fauzi'), 'AF');
      expect(initialsOf('Mulyana'), 'M');
      expect(initialsOf('  '), '?');
    });

    test('walkingMinutes minimal 1 menit', () {
      expect(walkingMinutes(10), 1);
      expect(walkingMinutes(240), 3);
    });

    test('formatTimeWib & formatClockSeconds', () {
      final dt = DateTime(2026, 11, 24, 14, 5, 9);
      expect(formatTimeWib(dt), '14:05 WIB');
      expect(formatClockSeconds(dt), '14:05:09 WIB');
    });

    test('formatRelativeTime', () {
      final base = DateTime(2026, 11, 24, 14, 30, 0);
      expect(formatRelativeTime(base.subtract(const Duration(seconds: 20)), baseTime: base), 'Baru saja');
      expect(formatRelativeTime(base.subtract(const Duration(minutes: 5)), baseTime: base), '5 mnt lalu');
      expect(formatRelativeTime(base.subtract(const Duration(hours: 2)), baseTime: base), '12:30 WIB');
      expect(formatRelativeTime(base.subtract(const Duration(days: 1)), baseTime: base), 'Kemarin, 14:30 WIB');
      expect(formatRelativeTime(base.subtract(const Duration(days: 3)), baseTime: base), '3 hari lalu');
    });
  });
}
