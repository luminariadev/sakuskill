import 'package:latlong2/latlong.dart';
import '../../../../core/security/rbac_matrix.dart';

class UserEntity {
  final String id;
  final String name;
  final String nim;
  final String major;
  final String faculty;
  final String avatar;
  final UserRole role;
  final bool verifiedStudent;
  final int walletBalance; // Simulated Escrow Ledger in IDR
  final double rating;
  final int reviewCount;
  final String phone;
  final String locationName;
  final LatLng coordinates;
  final List<String> skills;

  const UserEntity({
    required this.id,
    required this.name,
    required this.nim,
    required this.major,
    required this.faculty,
    required this.avatar,
    required this.role,
    required this.verifiedStudent,
    required this.walletBalance,
    required this.rating,
    required this.reviewCount,
    required this.phone,
    required this.locationName,
    required this.coordinates,
    required this.skills,
  });

  UserEntity copyWith({
    int? walletBalance,
    double? rating,
    int? reviewCount,
  }) {
    return UserEntity(
      id: id,
      name: name,
      nim: nim,
      major: major,
      faculty: faculty,
      avatar: avatar,
      role: role,
      verifiedStudent: verifiedStudent,
      walletBalance: walletBalance ?? this.walletBalance,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      phone: phone,
      locationName: locationName,
      coordinates: coordinates,
      skills: skills,
    );
  }
}
