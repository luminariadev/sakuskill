import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/saku_icon.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/discovery_filter.dart';
import '../../domain/entities/service_listing.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/discovery_scope.dart';
import '../widgets/campus_map_widgets.dart';
import '../widgets/discovery_filters.dart';

LatLng _toLatLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

/// Figma "02 · Explore campus" — peta kampus OpenStreetMap (flutter_map)
/// dengan lingkaran radius, marker talenta, dan kartu pratinjau.
class CampusMapPage extends StatefulWidget {
  const CampusMapPage({super.key});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage> {
  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();
  bool _mapReady = false;
  int? _fittedRadius;

  @override
  void dispose() {
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  /// Zoom agar seluruh lingkaran radius terlihat.
  void _fitRadius(DiscoveryFilter filter) {
    if (!_mapReady) return;
    _fittedRadius = filter.radiusMeters;
    final origin = filter.origin;
    final r = filter.radiusMeters.toDouble();
    final dLat = r / 111320;
    final dLng = r / (111320 * math.cos(origin.latitude * math.pi / 180));
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(origin.latitude - dLat, origin.longitude - dLng),
          LatLng(origin.latitude + dLat, origin.longitude + dLng),
        ),
        padding: const EdgeInsets.fromLTRB(24, 150, 24, 230),
      ),
    );
  }

  void _focus(ServiceListing listing) {
    final controller = DiscoveryScope.read(context);
    controller.selectListing(listing.id);
    if (_mapReady && listing.location != null) {
      _map.move(_toLatLng(listing.location!), _map.camera.zoom);
    }
  }

  List<ServiceListing> _visible(DiscoveryController c) {
    final q = _search.text.trim().toLowerCase();
    final all = c.mappableListings;
    if (q.isEmpty) return all;
    return all
        .where((l) =>
            l.providerName.toLowerCase().contains(q) ||
            l.title.toLowerCase().contains(q) ||
            l.category.toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = DiscoveryScope.of(context);
    final filter = controller.filter;
    final visible = _visible(controller);
    final selected = controller.selectedListing;
    final origin = _toLatLng(filter.origin);

    // Sesuaikan zoom saat radius diganti dari tab mana pun.
    if (_mapReady && _fittedRadius != filter.radiusMeters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitRadius(DiscoveryScope.read(context).filter);
      });
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: origin,
                initialZoom: 15.5,
                minZoom: 12,
                maxZoom: 19,
                backgroundColor: AppColors.mapGreen,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  _mapReady = true;
                  _fitRadius(DiscoveryScope.read(context).filter);
                },
                onTap: (_, __) => FocusScope.of(context).unfocus(),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.mapTileUrl,
                  subdomains: AppConfig.mapTileSubdomains,
                  retinaMode: RetinaMode.isHighDensity(context),
                  userAgentPackageName: AppConfig.osmUserAgent,
                  maxZoom: 19,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: origin,
                      radius: filter.radiusMeters.toDouble(),
                      useRadiusInMeter: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderColor: AppColors.primary.withValues(alpha: 0.6),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(origin.latitude + 0.0032, origin.longitude),
                      width: 150,
                      height: 52,
                      child: const CampusMapLabel(),
                    ),
                    Marker(
                      point: origin,
                      width: 17,
                      height: 17,
                      child: const OriginDot(),
                    ),
                    for (final l in visible)
                      Marker(
                        point: _toLatLng(l.location!),
                        width: talentMarkerSize.width,
                        height: talentMarkerSize.height,
                        child: TalentMarker(
                          listing: l,
                          selected: l.id == selected?.id,
                          onTap: () => _focus(l),
                        ),
                      ),
                  ],
                ),
                const SimpleAttributionWidget(
                  source: Text(AppConfig.mapAttribution),
                  alignment: Alignment.bottomLeft,
                ),
              ],
            ),
          ),

          // ---- Kontrol atas: pencarian + radius (Figma "Explore Cibiru")
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        borderRadius: AppRadius.pillBr,
                        boxShadow: AppShadows.flat,
                      ),
                      child: SizedBox(
                        height: 46,
                        child: TextField(
                          key: const Key('map-search-input'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 12),
                          // expands: dekorasi (border pill) mengisi tinggi 46.
                          expands: true,
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            hintText: 'Cari keahlian di sekitar Anda...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 13, right: 11),
                              child: SakuIcon(
                                SakuIcons.search,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            prefixIconConstraints:
                                BoxConstraints(minWidth: 44, minHeight: 20),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.pillBr,
                              borderSide:
                                  BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.pillBr,
                              borderSide:
                                  BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.pillBr,
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: RadiusPills(
                        value: filter.radiusMeters,
                        onChanged: controller.setRadius,
                      ),
                    ),
                    if (controller.isLoading) ...[
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    if (controller.isFallback) ...[
                      const SizedBox(height: 8),
                      const OfflineDataBanner(),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ---- Kontrol bawah: recenter + kartu pratinjau -------------------
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MapCircleButton(
                  tooltip: 'Kembali ke kampus',
                  icon: Icons.my_location_rounded,
                  onPressed: () => _fitRadius(filter),
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _bottomContent(controller, visible, selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomContent(
    DiscoveryController controller,
    List<ServiceListing> visible,
    ServiceListing? selected,
  ) {
    if (selected != null && visible.any((l) => l.id == selected.id)) {
      return TalentPreviewCard(
        key: ValueKey('preview-${selected.id}'),
        listing: selected,
        onOpenDetail: () => Navigator.of(context).pushNamed(
          AppRoutes.serviceDetail,
          arguments: selected,
        ),
      );
    }
    if (!controller.isLoading && visible.isEmpty) {
      return Container(
        key: const ValueKey('empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: AppRadius.cardBr,
          boxShadow: AppShadows.flat,
        ),
        child: const Text(
          'Tidak ada talenta di radius ini. Coba perbesar radius.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }
    return const SizedBox.shrink(key: ValueKey('none'));
  }
}
