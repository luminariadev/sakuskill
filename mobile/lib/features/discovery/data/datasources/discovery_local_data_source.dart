import '../../../../core/config/app_config.dart';
import '../../../../core/utils/geo.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/entities/service_listing.dart';

/// Data contoh di sekitar UIN SGD Cibiru — dipakai saat backend belum jalan
/// (mode demo/offline) dan sebagai fixture pengujian.
///
/// Koordinat = pusat kampus + offset kecil (0,001° ≈ 110 m).
class DiscoveryLocalDataSource {
  const DiscoveryLocalDataSource();

  static GeoPoint _around(double dLat, double dLng) => GeoPoint(
        AppConfig.campusCenter.latitude + dLat,
        AppConfig.campusCenter.longitude + dLng,
      );

  /// Kategori mengikuti seed `skills.kategori` di migrasi backend.
  static const List<ServiceCategory> categories = [
    ServiceCategory(id: 'Desain', label: 'Desain', iconKey: 'design'),
    ServiceCategory(id: 'Jasa Teknis', label: 'Jasa Teknis', iconKey: 'tech'),
    ServiceCategory(id: 'Fotografi', label: 'Fotografi', iconKey: 'photo'),
    ServiceCategory(
      id: 'Bimbingan Belajar',
      label: 'Bimbingan Belajar',
      iconKey: 'tutor',
    ),
  ];

  List<ServiceCategory> getCategories() => categories;

  List<ServiceListing> getListings() => [
        ServiceListing(
          id: 'demo-001',
          title: 'Jasa Desain Feed IG & Poster Acara Kampus UKM',
          description:
              'Desain feed Instagram, poster, dan banner acara UKM. Revisi '
              '2x, file siap cetak (PDF/PNG).',
          price: 35000,
          offerType: OfferType.paidAndBarter,
          providerName: 'Ahmad Fauzi',
          providerMajor: 'Teknik Informatika • Sem 7',
          skillName: 'Desain UI/UX & Grafis Poster',
          category: 'Desain',
          location: _around(0.0021, 0.0020),
          landmark: 'Gedung FST',
          rating: 4.8,
          reviewCount: 24,
        ),
        ServiceListing(
          id: 'demo-002',
          title: 'Instalasi Ulang OS, Dual Boot Linux & Servis Laptop Kampus',
          description:
              'Install ulang Windows/Linux, dual boot, pembersihan '
              'malware, dan optimasi laptop untuk kuliah.',
          price: 50000,
          offerType: OfferType.paidAndBarter,
          providerName: 'Rifqi Hamdani',
          providerMajor: 'Teknik Informatika • Sem 5',
          skillName: 'Instalasi OS & Perbaikan Laptop',
          category: 'Jasa Teknis',
          location: _around(0.0016, -0.0015),
          landmark: 'Gedung FST',
          rating: 4.9,
          reviewCount: 18,
        ),
        ServiceListing(
          id: 'demo-003',
          title: 'Jasa Desain Logo & Identitas Visual UKM',
          description:
              'Logo, palet warna, dan panduan identitas sederhana untuk '
              'UKM atau himpunan.',
          price: 45000,
          offerType: OfferType.paid,
          providerName: 'Sarah Aulia',
          providerMajor: 'Sistem Informasi • Sem 5',
          skillName: 'Desain UI/UX & Grafis Poster',
          category: 'Desain',
          location: _around(-0.0025, 0.0028),
          landmark: 'Kopma',
          rating: 4.7,
          reviewCount: 11,
        ),
        ServiceListing(
          id: 'demo-004',
          title: 'Bimbingan Pemrograman Dasar Python',
          description:
              'Sesi belajar konsep dasar (bukan pengerjaan tugas) — '
              'variabel, perulangan, fungsi. Sesuai kode etik anti-joki.',
          offerType: OfferType.barter,
          providerName: 'Mulyana',
          providerMajor: 'Teknik Informatika • Sem 7',
          skillName: 'Bimbingan Belajar Pemrograman Dasar',
          category: 'Bimbingan Belajar',
          location: _around(0.0040, 0.0038),
          landmark: 'Perpustakaan',
          rating: 5.0,
          reviewCount: 7,
        ),
        ServiceListing(
          id: 'demo-005',
          title: 'Foto Wisuda & Dokumentasi Mini Sidang',
          description:
              'Sesi foto wisuda 1 jam + 30 foto edit. Bisa juga dokumentasi '
              'seminar dan sidang.',
          price: 75000,
          offerType: OfferType.paidAndBarter,
          providerName: 'Dina Rahmawati',
          providerMajor: 'Sains Komunikasi',
          skillName: 'Fotografi Wisuda & Kegiatan Kampus',
          category: 'Fotografi',
          location: _around(-0.0060, 0.0045),
          landmark: 'Aula Utama',
          rating: 4.8,
          reviewCount: 32,
        ),
        ServiceListing(
          id: 'demo-006',
          title: 'Editing Video Teaser Reels 30 Detik',
          description:
              'Editing video pendek untuk promosi acara: color grading, '
              'subtitle, musik bebas lisensi.',
          offerType: OfferType.barter,
          providerName: 'Zikri Maulana',
          providerMajor: 'DKV • Sem 5',
          skillName: 'Fotografi Wisuda & Kegiatan Kampus',
          category: 'Fotografi',
          location: _around(0.0085, -0.0070),
          landmark: 'Masjid Kampus',
          rating: 4.6,
          reviewCount: 9,
        ),
        ServiceListing(
          id: 'demo-007',
          title: 'Bimbingan Belajar Kalkulus Dasar',
          description:
              'Pendampingan memahami limit, turunan, dan integral. '
              'Bukan jasa pengerjaan tugas/ujian.',
          price: 30000,
          offerType: OfferType.paid,
          providerName: 'Nabila Putri',
          providerMajor: 'Pendidikan Matematika • Sem 6',
          skillName: 'Bimbingan Belajar Pemrograman Dasar',
          category: 'Bimbingan Belajar',
          location: _around(0.0120, -0.0080),
          landmark: 'Gedung Tarbiyah',
          rating: 4.9,
          reviewCount: 14,
        ),
        ServiceListing(
          id: 'demo-008',
          title: 'Debugging & Pembuatan Web Sederhana',
          description:
              'Perbaikan bug website/UKM landing page (HTML, Laravel, '
              'Flutter Web). Konsultasi gratis 15 menit.',
          price: 100000,
          offerType: OfferType.paidAndBarter,
          providerName: 'Fajar Nugraha',
          providerMajor: 'Teknik Informatika • Sem 8',
          skillName: 'Debugging & Pembuatan Web Sederhana',
          category: 'Jasa Teknis',
          location: _around(-0.0180, -0.0160),
          landmark: 'Bundaran Cibiru',
          rating: 4.7,
          reviewCount: 21,
        ),
      ];
}
