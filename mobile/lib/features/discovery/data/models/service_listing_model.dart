import '../../../../core/utils/geo.dart';
import '../../domain/entities/service_listing.dart';

/// Mapper JSON <-> entitas untuk respons `GET /api/v1/listings`.
///
/// Field wajib dari backend saat ini: listing_id, judul, deskripsi, harga,
/// tipe_penawaran, nama_penyedia, nama_keterampilan, kategori, jarak_km.
/// Field opsional (`lat`, `lng`, `prodi`, `patokan`, `rating`,
/// `jumlah_ulasan`, `jenis` = penawaran|permintaan, `tukar_dengan`,
/// `lama_hari`) akan otomatis terpakai begitu backend menambahkannya —
/// `lat`/`lng` dibutuhkan agar listing bisa tampil sebagai marker di peta.
abstract final class ServiceListingModel {
  static ServiceListing fromJson(Map<String, dynamic> json) {
    final lat = _toDouble(json['lat'] ?? json['latitude']);
    final lng = _toDouble(json['lng'] ?? json['longitude']);
    final jarakKm = _toDouble(json['jarak_km']);
    final reviewCount = _toDouble(json['jumlah_ulasan'])?.toInt() ?? 0;
    final rating = _toDouble(json['rating'] ?? json['rata_rata_rating']);

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
      rating: (reviewCount == 0 && (rating ?? 0) == 0) ? null : rating,
      reviewCount: reviewCount,
      kind: ListingKind.fromApi(json['jenis'] as String?),
      barterWant:
          (json['tukar_dengan'] ?? json['deskripsi_imbalan_barter']) as String?,
      deliveryDays: _toDouble(json['lama_hari'])?.toInt(),
      scopeItems: (json['cakupan'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  /// PostgreSQL NUMERIC dikirim sebagai string oleh node-postgres.
  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
