import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sakuskill_mobile/core/constants/campus_constants.dart';
import 'package:sakuskill_mobile/core/theme/app_theme.dart';
import 'package:sakuskill_mobile/features/services/domain/entities/service_item.dart';

class CampusMapWidget extends StatelessWidget {
  final List<ServiceItem> services;
  final double maxDistanceKm;
  final ValueChanged<ServiceItem> onServiceSelected;

  const CampusMapWidget({
    super.key,
    required this.services,
    required this.maxDistanceKm,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: CampusConstants.campusLocation,
              initialZoom: 14.8,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.uinsgd.sakuskill',
                maxZoom: 19,
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: CampusConstants.campusLocation,
                    radius: maxDistanceKm * 1000,
                    useRadiusInMeter: true,
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderColor: AppTheme.primary,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Campus Centroid Marker
                  Marker(
                    point: CampusConstants.campusLocation,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 18),
                    ),
                  ),
                  // Service Markers
                  ...services.map((item) {
                    final priceK = item.price >= 1000 ? '${(item.price / 1000).round()}k' : '${item.price}';
                    return Marker(
                      point: item.coordinates,
                      width: 50,
                      height: 28,
                      child: GestureDetector(
                        onTap: () => onServiceSelected(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primary, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              priceK,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          PositionBar(
            maxDistanceKm: maxDistanceKm,
          ),
        ],
      ),
    );
  }
}

class PositionBar extends StatelessWidget {
  final double maxDistanceKm;

  const PositionBar({super.key, required this.maxDistanceKm});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Radius: $maxDistanceKm km',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
