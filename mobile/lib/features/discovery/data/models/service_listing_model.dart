import '../../../../core/utils/geo.dart';
import '../../domain/entities/service_listing.dart';

/// Mapper JSON <-> entitas untuk respons `GET /api/v1/listings`.
///
/// Field wajib dari backend saat ini: listing_id, judul, deskripsi, harga,
/// tipe_penawaran, nama_penyedia, nama_keterampilan, kategori, jarak_km.
/// Field opsional (`lat`, `lng`, `prodi`, `patokan`, `rating`,
/// `jumlah_ulasan`) akan otomatis terpakai begitu backend menambahkannya —
/// `lat`/`lng` dibutuhkan agar listing bisa tampil sebagai marker di peta.
abstract final class ServiceListingModel {
  static ServiceListing fromJson(Map<String, dynamic> json) {
    final lat = _toDouble(json['lat'] ?? json['latitude']);
    final lng = _toDouble(json['lng'] ?? json['longitude']);
    final jarakKm = _toDouble(json['jarak_km']);

    return ServiceListing(
      id: json['listing_id'].toString(),
      title: (json['judul'] ?? '').toString(),
      description: (json['deskripsi'] ?? '').toString(),
      price: _toDouble(json['harga']),
      offerType: OfferType.fromApi(json['tipe_penawaran'] as String?),
      providerName: (json['nama_penyedia'] ?? 'Penyedia').toString(),
      providerMajor: json['prodi'] as String?,
      skillName: (json['nama_keterampilan'] ?? '').toString(),
      category: (json['kategori'] ?? '').toString(),
      location: (lat != null && lng != null) ? GeoPoint(lat, lng) : null,
      distanceMeters: jarakKm != null ? jarakKm * 1000 : null,
      landmark: json['patokan'] as String?,
      rating: _toDouble(json['rating']),
      reviewCount: _toDouble(json['jumlah_ulasan'])?.toInt() ?? 0,
    );
  }

  /// PostgreSQL NUMERIC dikirim sebagai string oleh node-postgres.
  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
