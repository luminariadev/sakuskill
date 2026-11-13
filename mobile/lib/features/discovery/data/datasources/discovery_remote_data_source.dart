import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../domain/entities/discovery_filter.dart';
import '../../domain/entities/service_listing.dart';
import '../models/service_listing_model.dart';

class DiscoveryException implements Exception {
  const DiscoveryException(this.message);
  final String message;

  @override
  String toString() => 'DiscoveryException: $message';
}

/// Sumber data REST: `GET {base}/listings?lat&lng&radius_m`.
class DiscoveryRemoteDataSource {
  DiscoveryRemoteDataSource({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<ServiceListing>> fetchNearby(DiscoveryFilter filter) async {
    // Filter tipe barter, kata kunci & kategori dikerjakan di klien karena
    // endpoint belum mendukungnya (barterOnly = 'Barter' ATAU 'Berbayar dan
    // Barter', sedangkan query tipe_penawaran hanya menerima satu nilai).
    final uri = Uri.parse('$_baseUrl/listings').replace(queryParameters: {
      'lat': filter.origin.latitude.toString(),
      'lng': filter.origin.longitude.toString(),
      'radius_m': filter.radiusMeters.toString(),
    });

    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(AppConfig.networkTimeout);

    if (response.statusCode != 200) {
      throw DiscoveryException('HTTP ${response.statusCode} dari $uri');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw const DiscoveryException('Format respons tidak sesuai kontrak API');
    }

    final data = body['data'];
    final items = data is List
        ? data
        : (data is Map<String, dynamic> ? data['listings'] as List? : null);
    if (items == null) return const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(ServiceListingModel.fromJson)
        .toList(growable: false);
  }
}
