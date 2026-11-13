import '../entities/discovery_filter.dart';
import '../entities/service_category.dart';
import '../repositories/discovery_repository.dart';

/// Mencari layanan di sekitar titik asal sesuai [DiscoveryFilter].
class SearchNearbyServices {
  const SearchNearbyServices(this._repository);
  final DiscoveryRepository _repository;

  Future<DiscoveryResult> call(DiscoveryFilter filter) =>
      _repository.searchNearby(filter);
}

/// Mengambil daftar kategori layanan.
class GetServiceCategories {
  const GetServiceCategories(this._repository);
  final DiscoveryRepository _repository;

  Future<List<ServiceCategory>> call() => _repository.getCategories();
}
