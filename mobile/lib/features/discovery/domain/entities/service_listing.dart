import '../../../../core/utils/geo.dart';

/// Tipe penawaran — nilai string mengikuti `offer_type_enum` di backend.
enum OfferType {
  paid('Berbayar'),
  barter('Barter'),
  paidAndBarter('Berbayar dan Barter');

  const OfferType(this.apiValue);
  final String apiValue;

  bool get acceptsBarter => this != OfferType.paid;
  bool get acceptsPayment => this != OfferType.barter;

  static OfferType fromApi(String? value) => OfferType.values.firstWhere(
        (t) => t.apiValue == value,
        orElse: () => OfferType.paid,
      );
}

/// Jenis postingan di marketplace: penawaran jasa oleh penyedia, atau
/// "Kebutuhan Proyek" (permintaan) yang diposting klien.
enum ListingKind {
  offer('penawaran'),
  request('permintaan');

  const ListingKind(this.apiValue);
  final String apiValue;

  static ListingKind fromApi(String? value) =>
      value == ListingKind.request.apiValue ? request : offer;
}

/// Entitas layanan/jasa yang tampil di Discovery.
///
/// Field dibuat selaras dengan respons `GET /api/v1/listings`
/// (lihat backend/src/modules/listings/listings.repository.js).
class ServiceListing {
  const ServiceListing({
    required this.id,
    required this.title,
    required this.description,
    required this.offerType,
    required this.providerName,
    required this.skillName,
    required this.category,
    this.price,
    this.providerMajor,
    this.location,
    this.distanceMeters,
    this.landmark,
    this.rating,
    this.reviewCount = 0,
    this.kind = ListingKind.offer,
    this.coverAsset,
    this.barterWant,
    this.deliveryDays,
    this.scopeItems = const [],
    this.galleryAssets = const [],
  });

  final String id;
  final String title;
  final String description;
  final OfferType offerType;
  final String providerName;
  final String skillName;
  final String category;

  /// Null bila listing murni barter.
  final num? price;

  /// Program studi/semester penyedia, mis. "Teknik Informatika • Sem 7".
  final String? providerMajor;

  /// Koordinat lokasi layanan. Wajib untuk tampil di peta kampus.
  final GeoPoint? location;

  /// Jarak dari titik pengguna (meter), dihitung via Haversine.
  final double? distanceMeters;

  /// Patokan lokasi, mis. "Gedung FST".
  final String? landmark;
  final double? rating;
  final int reviewCount;

  /// Penawaran jasa atau "Kebutuhan Proyek" (permintaan klien).
  final ListingKind kind;

  /// Gambar sampul. Sementara aset lokal demo; nanti URL dari backend.
  final String? coverAsset;

  /// Keahlian yang diinginkan sebagai tukaran, mis. "Tukar Jasa Desain Web".
  final String? barterWant;

  /// Lama pengerjaan (penawaran) / tenggat yang dibutuhkan (permintaan).
  final int? deliveryDays;

  /// Poin "Deskripsi & Cakupan Brief" (mis. "Format PDF & JPG").
  final List<String> scopeItems;

  /// Foto portofolio untuk slider detail (aset demo; nanti URL).
  final List<String> galleryAssets;

  bool get isRequest => kind == ListingKind.request;

  ServiceListing copyWith({double? distanceMeters}) => ServiceListing(
        id: id,
        title: title,
        description: description,
        offerType: offerType,
        providerName: providerName,
        skillName: skillName,
        category: category,
        price: price,
        providerMajor: providerMajor,
        location: location,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        landmark: landmark,
        rating: rating,
        reviewCount: reviewCount,
        kind: kind,
        coverAsset: coverAsset,
        barterWant: barterWant,
        deliveryDays: deliveryDays,
        scopeItems: scopeItems,
        galleryAssets: galleryAssets,
      );
}
