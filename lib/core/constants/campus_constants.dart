import 'package:latlong2/latlong.dart';

class CampusConstants {
  static const String campusName = 'Kampus 1 UIN Sunan Gunung Djati Bandung';
  static const String campusAddress = 'Jl. A.H. Nasution No. 105, Cipadung, Cibiru, Kota Bandung';
  static const LatLng campusLocation = LatLng(-6.9317, 107.7176);

  static const double maxCampusRadiusKm = 3.0;
}

enum ServiceCategory {
  itSupport,
  creativeDesign,
  photography,
  tutoring,
  eventSupport,
}

class CategoryMeta {
  final String label;
  final String description;
  final int baseRate;

  const CategoryMeta({
    required this.label,
    required this.description,
    required this.baseRate,
  });

  static const Map<ServiceCategory, CategoryMeta> info = {
    ServiceCategory.itSupport: CategoryMeta(
      label: 'IT & Troubleshoot',
      description: 'Pembersihan laptop, instalasi OS Linux, setup dev tools.',
      baseRate: 35000,
    ),
    ServiceCategory.creativeDesign: CategoryMeta(
      label: 'Desain Grafis',
      description: 'Banner ormawa, spanduk kegiatan, infografis feeds IG.',
      baseRate: 40000,
    ),
    ServiceCategory.photography: CategoryMeta(
      label: 'Foto & Video',
      description: 'Foto wisuda Anwar Musaddad, dokumentasi acara himpunan.',
      baseRate: 60000,
    ),
    ServiceCategory.tutoring: CategoryMeta(
      label: 'Mentoring Skill',
      description: 'Bimbingan logika algoritma dasar, percakapan bahasa.',
      baseRate: 30000,
    ),
    ServiceCategory.eventSupport: CategoryMeta(
      label: 'Dukungan Acara',
      description: 'MC formal/non-formal kegiatan kampus, kepanitiaan.',
      baseRate: 50000,
    ),
  };
}
