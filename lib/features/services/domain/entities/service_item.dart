import 'package:latlong2/latlong.dart';
import '../../../../core/constants/campus_constants.dart';

class ServiceItem {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final ServiceCategory category;
  final int price;
  final bool acceptsBarter;
  final String? barterWishlist;
  final String locationName;
  final LatLng coordinates;
  final double distanceFromCampusKm;
  final int estimatedDeliveryHours;
  final String imageUrl;
  final DateTime createdAt;

  const ServiceItem({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.acceptsBarter,
    this.barterWishlist,
    required this.locationName,
    required this.coordinates,
    required this.distanceFromCampusKm,
    required this.estimatedDeliveryHours,
    required this.imageUrl,
    required this.createdAt,
  });
}
