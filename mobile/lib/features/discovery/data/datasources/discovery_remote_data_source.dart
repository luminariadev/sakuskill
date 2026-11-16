import '../../../../core/network/api_client.dart';
import '../../domain/entities/discovery_filter.dart';
import '../../domain/entities/service_listing.dart';
import '../models/service_listing_model.dart';

/// Sumber data REST: `GET {base}/listings?lat&lng&radius_m` lewat [ApiClient].
///
/// Kegagalan dilempar sebagai `ApiException`; repository menangkapnya dan
/// jatuh ke data contoh lokal.
class DiscoveryRemoteDataSource {
  DiscoveryRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<ServiceListing>> fetchNearby(DiscoveryFilter filter) async {
    // Filter tipe barter, kata kunci & kategori dikerjakan di klien karena
    // endpoint belum mendukungnya (barterOnly = 'Barter' ATAU 'Berbayar dan
    // Barter', sedangkan query tipe_penawaran hanya menerima satu nilai).
    final res = await _api.get(
      '/listings',
      query: {
        'lat': filter.origin.latitude,
        'lng': filter.origin.longitude,
        'radius_m': filter.radiusMeters,
      },
    );
    return res
        .dataList('listings')
        .map(ServiceListingModel.fromJson)
        .toList(growable: false);
  }
}
