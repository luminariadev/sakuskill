import 'package:flutter/foundation.dart';

import '../../domain/entities/discovery_filter.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_listing.dart';
import '../../domain/usecases/discovery_usecases.dart';

enum DiscoveryStatus { initial, loading, success, failure }

/// State management Discovery (ChangeNotifier).
///
/// Satu instance dibagi oleh Home & Explore (peta) lewat `DiscoveryScope`
/// sehingga filter radius/kategori/barter tetap sinkron antar-tab.
/// Halaman pencarian membuat instance sendiri agar kata kunci tidak
/// "bocor" ke feed Home.
class DiscoveryController extends ChangeNotifier {
  DiscoveryController({
    required SearchNearbyServices searchNearby,
    required GetServiceCategories getCategories,
    DiscoveryFilter initialFilter = const DiscoveryFilter(),
  })  : _searchNearby = searchNearby,
        _getCategories = getCategories,
        _filter = initialFilter;

  final SearchNearbyServices _searchNearby;
  final GetServiceCategories _getCategories;

  DiscoveryStatus _status = DiscoveryStatus.initial;
  DiscoveryFilter _filter;
  List<ServiceListing> _listings = const [];
  List<ServiceCategory> _categories = const [];
  bool _isFallback = false;
  String? _errorMessage;
  String? _selectedListingId;
  int _requestId = 0;
  bool _disposed = false;

  DiscoveryStatus get status => _status;
  DiscoveryFilter get filter => _filter;
  List<ServiceListing> get listings => _listings;
  List<ServiceCategory> get categories => _categories;
  bool get isLoading => _status == DiscoveryStatus.loading;
  bool get isFallback => _isFallback;
  String? get errorMessage => _errorMessage;

  ServiceListing? get selectedListing {
    if (_selectedListingId == null) return null;
    for (final l in _listings) {
      if (l.id == _selectedListingId) return l;
    }
    return null;
  }

  /// Listing yang punya koordinat (dapat dipetakan).
  List<ServiceListing> get mappableListings =>
      _listings.where((l) => l.location != null).toList(growable: false);

  Future<void> init() async {
    if (_status != DiscoveryStatus.initial) return;
    try {
      _categories = await _getCategories();
    } catch (_) {
      _categories = const [];
    }
    await _load();
  }

  Future<void> refresh() => _load();

  void setQuery(String query) {
    if (query == _filter.query) return;
    _applyFilter(_filter.copyWith(query: query));
  }

  void setCategory(String? categoryId) {
    if (categoryId == _filter.categoryId) return;
    _applyFilter(categoryId == null
        ? _filter.copyWith(clearCategory: true)
        : _filter.copyWith(categoryId: categoryId));
  }

  void setRadius(int meters) {
    if (meters == _filter.radiusMeters) return;
    _applyFilter(_filter.copyWith(radiusMeters: meters));
  }

  void setBarterOnly(bool value) {
    if (value == _filter.barterOnly) return;
    _applyFilter(_filter.copyWith(barterOnly: value));
  }

  void toggleBarterOnly() => setBarterOnly(!_filter.barterOnly);

  void selectListing(String? id) {
    if (id == _selectedListingId) return;
    _selectedListingId = id;
    _notify();
  }

  void _applyFilter(DiscoveryFilter next) {
    _filter = next;
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    _status = DiscoveryStatus.loading;
    _errorMessage = null;
    _notify();

    try {
      final result = await _searchNearby(_filter);
      if (requestId != _requestId) return; // respons usang, abaikan
      _listings = result.listings;
      _isFallback = result.isFallback;
      _status = DiscoveryStatus.success;

      // Pertahankan pilihan marker bila masih ada di hasil; jika tidak,
      // pilih listing terdekat untuk kartu pratinjau di peta.
      final stillExists = _listings.any((l) => l.id == _selectedListingId);
      if (!stillExists) {
        _selectedListingId = _listings.isEmpty ? null : _listings.first.id;
      }
    } catch (error) {
      if (requestId != _requestId) return;
      _status = DiscoveryStatus.failure;
      _errorMessage = 'Gagal memuat layanan. Coba lagi sebentar.';
      debugPrint('[Discovery] $error');
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
