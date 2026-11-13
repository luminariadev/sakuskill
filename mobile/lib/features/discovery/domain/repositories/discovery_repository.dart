import '../entities/discovery_filter.dart';
import '../entities/service_category.dart';
import '../entities/service_listing.dart';

/// Hasil pencarian + penanda sumber data (server atau data contoh offline).
class DiscoveryResult {
  const DiscoveryResult({required this.listings, this.isFallback = false});

  final List<ServiceListing> listings;

  /// True bila backend tidak terjangkau dan data berasal dari data contoh.
  final bool isFallback;
}

/// Kontrak repository Discovery (lapisan domain).
/// Implementasi ada di `data/repositories/discovery_repository_impl.dart`.
abstract interface class DiscoveryRepository {
  Future<DiscoveryResult> searchNearby(DiscoveryFilter filter);

  Future<List<ServiceCategory>> getCategories();
}
