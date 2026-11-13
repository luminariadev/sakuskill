import 'package:flutter_test/flutter_test.dart';
import 'package:sakuskill/features/discovery/data/datasources/discovery_local_data_source.dart';
import 'package:sakuskill/features/discovery/data/models/service_listing_model.dart';
import 'package:sakuskill/features/discovery/domain/entities/discovery_filter.dart';
import 'package:sakuskill/features/discovery/domain/entities/service_listing.dart';
import 'package:sakuskill/features/discovery/domain/usecases/listing_filter.dart';

void main() {
  final all = const DiscoveryLocalDataSource().getListings();

  List<String> names(List<ServiceListing> l) =>
      l.map((e) => e.providerName).toList();

  group('ListingFilter', () {
    test('radius 2 km membuang listing > 2 km dan urut dari terdekat', () {
      final result = ListingFilter.apply(all, const DiscoveryFilter());
      expect(result, hasLength(7));
      expect(names(result), isNot(contains('Fajar Nugraha'))); // ≈ 2,67 km
      expect(result.first.providerName, 'Rifqi Hamdani'); // ≈ 243 m
      for (var i = 1; i < result.length; i++) {
        expect(
          result[i].distanceMeters!,
          greaterThanOrEqualTo(result[i - 1].distanceMeters!),
        );
      }
    });

    test('radius 500 m', () {
      final result =
          ListingFilter.apply(all, const DiscoveryFilter(radiusMeters: 500));
      expect(
        names(result),
        ['Rifqi Hamdani', 'Ahmad Fauzi', 'Sarah Aulia'],
      );
    });

    test('Smart Barter hanya menampilkan Barter / Berbayar dan Barter', () {
      final result = ListingFilter.apply(
        all,
        const DiscoveryFilter(radiusMeters: 3000, barterOnly: true),
      );
      expect(result.every((l) => l.offerType.acceptsBarter), isTrue);
      expect(names(result), isNot(contains('Sarah Aulia')));
      expect(names(result), isNot(contains('Nabila Putri')));
    });

    test('filter kategori', () {
      final result = ListingFilter.apply(
        all,
        const DiscoveryFilter(radiusMeters: 3000, categoryId: 'Jasa Teknis'),
      );
      expect(names(result), ['Rifqi Hamdani', 'Fajar Nugraha']);
    });

    test('kata kunci tidak peka huruf besar & semua kata harus cocok', () {
      final poster = ListingFilter.apply(
        all,
        const DiscoveryFilter(query: 'DESAIN poster'),
      );
      // Sarah cocok lewat nama keahlian "Desain UI/UX & Grafis Poster".
      expect(names(poster), ['Ahmad Fauzi', 'Sarah Aulia']);

      final none = ListingFilter.apply(
        all,
        const DiscoveryFilter(query: 'joki skripsi'),
      );
      expect(none, isEmpty);
    });

    test('listing tanpa koordinat memakai jarak dari server', () {
      final fromApi = ServiceListingModel.fromJson(const {
        'listing_id': 'x',
        'judul': 'Servis Laptop',
        'deskripsi': '',
        'harga': '50000.00',
        'tipe_penawaran': 'Berbayar',
        'nama_penyedia': 'Budi',
        'nama_keterampilan': 'Instalasi OS',
        'kategori': 'Jasa Teknis',
        'jarak_km': '1.25',
      });
      expect(fromApi.location, isNull);
      expect(fromApi.distanceMeters, 1250);

      expect(
        ListingFilter.apply([fromApi], const DiscoveryFilter(radiusMeters: 1000)),
        isEmpty,
      );
      expect(
        ListingFilter.apply([fromApi], const DiscoveryFilter()),
        hasLength(1),
      );
    });
  });

  group('ServiceListingModel', () {
    test('parse NUMERIC string, enum, dan koordinat opsional', () {
      final l = ServiceListingModel.fromJson(const {
        'listing_id': 'abc',
        'judul': 'Desain Poster',
        'deskripsi': 'desc',
        'harga': '35000.00',
        'tipe_penawaran': 'Berbayar dan Barter',
        'nama_penyedia': 'Ahmad',
        'nama_keterampilan': 'Desain',
        'kategori': 'Desain',
        'jarak_km': 0.32,
        'lat': -6.929,
        'lng': '107.719',
      });
      expect(l.price, 35000);
      expect(l.offerType, OfferType.paidAndBarter);
      expect(l.location?.latitude, -6.929);
      expect(l.location?.longitude, 107.719);
    });

    test('tipe penawaran tidak dikenal → Berbayar', () {
      expect(OfferType.fromApi('???'), OfferType.paid);
      expect(OfferType.fromApi(null), OfferType.paid);
    });
  });
}
