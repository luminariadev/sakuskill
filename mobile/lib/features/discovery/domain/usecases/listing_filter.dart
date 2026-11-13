import '../../../../core/utils/geo.dart';
import '../entities/discovery_filter.dart';
import '../entities/service_listing.dart';

/// Aturan bisnis penyaringan Discovery (pure Dart, mudah di-unit-test).
///
/// 1. Hitung ulang jarak tiap listing dari `filter.origin` dengan Haversine
///    (bila koordinat tersedia), jika tidak pakai jarak dari server.
/// 2. Buang listing di luar radius.
/// 3. Cocokkan kata kunci (judul, keahlian, kategori, penyedia, deskripsi).
/// 4. Saring kategori & Smart Barter.
/// 5. Urutkan dari yang terdekat.
abstract final class ListingFilter {
  static List<ServiceListing> apply(
    Iterable<ServiceListing> listings,
    DiscoveryFilter filter,
  ) {
    final keywords = _tokenize(filter.query);

    final result = <ServiceListing>[];
    for (final listing in listings) {
      final distance = listing.location != null
          ? Haversine.distanceMeters(filter.origin, listing.location!)
          : listing.distanceMeters;

      if (distance != null && distance > filter.radiusMeters) continue;
      if (filter.categoryId != null && listing.category != filter.categoryId) {
        continue;
      }
      if (filter.barterOnly && !listing.offerType.acceptsBarter) continue;
      if (keywords.isNotEmpty && !_matches(listing, keywords)) continue;

      result.add(listing.copyWith(distanceMeters: distance));
    }

    result.sort((a, b) {
      final da = a.distanceMeters ?? double.infinity;
      final db = b.distanceMeters ?? double.infinity;
      return da.compareTo(db);
    });
    return result;
  }

  static List<String> _tokenize(String query) => query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  /// Semua kata kunci harus muncul di salah satu field (AND antar-kata).
  static bool _matches(ServiceListing l, List<String> keywords) {
    final haystack = [
      l.title,
      l.skillName,
      l.category,
      l.providerName,
      l.description,
      l.landmark ?? '',
    ].join(' ').toLowerCase();
    return keywords.every(haystack.contains);
  }
}
