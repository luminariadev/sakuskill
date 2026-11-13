import 'package:flutter/foundation.dart';

import '../../domain/entities/discovery_filter.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_listing.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../domain/usecases/listing_filter.dart';
import '../datasources/discovery_local_data_source.dart';
import '../datasources/discovery_remote_data_source.dart';

/// Strategi: coba API backend → bila gagal (server mati/timeout/format salah)
/// jatuh ke data contoh lokal, lalu terapkan [ListingFilter] di klien supaya
/// perilaku pencarian, kategori & radius konsisten di kedua sumber.
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  // Private named parameter: tetap dipanggil dengan `remote:` / `local:`.
  DiscoveryRepositoryImpl({
    required this._remote,
    required this._local,
    this.forceLocal = false,
  });

  final DiscoveryRemoteDataSource _remote;
  final DiscoveryLocalDataSource _local;
  final bool forceLocal;

  @override
  Future<DiscoveryResult> searchNearby(DiscoveryFilter filter) async {
    List<ServiceListing> raw;
    var isFallback = false;

    if (forceLocal) {
      // Mode demo disengaja (USE_MOCK_DATA) — bukan kegagalan, jadi banner
      // "server belum terhubung" tidak perlu tampil.
      raw = _local.getListings();
    } else {
      try {
        raw = await _remote.fetchNearby(filter);
      } catch (error) {
        debugPrint('[Discovery] API tidak terjangkau, pakai data contoh: $error');
        raw = _local.getListings();
        isFallback = true;
      }
    }

    return DiscoveryResult(
      listings: ListingFilter.apply(raw, filter),
      isFallback: isFallback,
    );
  }

  /// Belum ada endpoint kategori — pakai daftar seed yang sama dengan backend.
  @override
  Future<List<ServiceCategory>> getCategories() async => _local.getCategories();
}
