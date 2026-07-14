// The OSM-tile map widget. Renders:
//   - OpenStreetMap tiles via `flutter_map`'s TileLayer
//   - A marker for the buyer's current position
//   - A marker for every seller that has the searched fish
//   - The active route polyline (when a seller is selected)
//
// Live-presence: a seller's marker is green if their `isOnline` flag
// is set (via `SellerLocationTracker`) and the last fix is recent.
// Otherwise the marker is grey. The marker colour is in addition to
// the existing selected → accent-orange highlight, so a selected
// online seller renders as a green-with-orange-ring pin.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../constants/app_colors.dart';
import '../../models/map_filter_model.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../utils/logger.dart';

class SellerMap extends ConsumerStatefulWidget {
  final List<SellerWithFish> sellers;
  final BuyerLocation buyerLocation;
  final RouteResult? activeRoute;
  final SellerWithFish? selectedSeller;
  final void Function(SellerWithFish seller) onSellerTap;

  const SellerMap({
    super.key,
    required this.sellers,
    required this.buyerLocation,
    required this.activeRoute,
    required this.selectedSeller,
    required this.onSellerTap,
  });

  @override
  ConsumerState<SellerMap> createState() => _SellerMapState();
}

class _SellerMapState extends ConsumerState<SellerMap> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant SellerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the selection changes, re-center the map on the new seller.
    if (widget.selectedSeller != null &&
        widget.selectedSeller != oldWidget.selectedSeller) {
      _fitBoundsForSelection();
    }
  }

  void _fitBoundsForSelection() {
    final seller = widget.selectedSeller;
    if (seller == null) return;
    final buyer = LatLng(widget.buyerLocation.latitude, widget.buyerLocation.longitude);
    final points = <LatLng>[buyer, seller.position];
    final routePoints = widget.activeRoute?.points;
    if (routePoints != null && routePoints.length > 2) {
      points.addAll(routePoints);
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buyer = LatLng(
      widget.buyerLocation.latitude,
      widget.buyerLocation.longitude,
    );

    // Debug: log the seller count we received so a developer can
    // confirm the pipeline is wired correctly.
    AppLogger.debug(
      'SellerMap.build: ${widget.sellers.length} sellers, '
      'buyer at (${buyer.latitude}, ${buyer.longitude})',
    );
    for (final s in widget.sellers) {
      AppLogger.debug(
        '  → ${s.seller.fullName} (${s.seller.sellerId}) at '
        '(${s.seller.latitude}, ${s.seller.longitude})',
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: buyer,
        initialZoom: 13,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // OSM raster tiles. Using the public OpenStreetMap tile server —
        // for production, swap to a self-hosted or paid tile provider.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.samakifresh.connect',
          maxZoom: 19,
          tileProvider: NetworkTileProvider(),
        ),

        // Polyline for the active route.
        if (widget.activeRoute != null && widget.activeRoute!.points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.activeRoute!.points,
                strokeWidth: 5,
                color: widget.activeRoute!.source == RouteSource.osrm
                    ? AppColors.primaryBlue
                    : AppColors.accentOrange,
                borderColor: Colors.white,
                borderStrokeWidth: 2,
                pattern: widget.activeRoute!.source == RouteSource.osrm
                    ? const StrokePattern.solid()
                    : const StrokePattern.dotted(),
              ),
            ],
          ),

        // Markers: buyer + each matching seller.
        MarkerLayer(
          markers: [
            // Buyer "you are here" marker.
            Marker(
              point: buyer,
              width: 40,
              height: 40,
              child: const _BuyerMarker(),
            ),
            // Seller markers.
            for (final s in widget.sellers)
              Marker(
                point: s.position,
                width: 52,
                height: 60,
                alignment: Alignment.topCenter,
                child: _SellerMarker(
                  seller: s,
                  isSelected: s == widget.selectedSeller,
                  onTap: () => widget.onSellerTap(s),
                ),
              ),
          ],
        ),

        // Attribution — required by the OSM tile usage policy.
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

class _BuyerMarker extends StatelessWidget {
  const _BuyerMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_pin_circle,
            color: Colors.white, size: 22),
      ),
    );
  }
}

class _SellerMarker extends StatelessWidget {
  final SellerWithFish seller;
  final bool isSelected;
  final VoidCallback onTap;

  const _SellerMarker({
    required this.seller,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Base color depends on live-presence. Selected state upgrades the
    // outer ring to orange (existing behaviour).
    final isOnline = _isRecentlyOnline(seller);
    final baseColor = isOnline ? AppColors.successGreen : AppColors.gray500;
    final ringColor = isSelected ? AppColors.accentOrange : baseColor;
    final dotSize = isSelected ? 38.0 : 32.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer "live ring" — faint pulse when the seller is online.
              if (isOnline)
                Container(
                  width: dotSize + 16,
                  height: dotSize + 16,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              // White-bordered base.
              Container(
                width: dotSize + 6,
                height: dotSize + 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: ringColor, width: 2),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline
                        ? Icons.store_rounded
                        : Icons.store_mall_directory_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          // Small triangle below the pin (the "teardrop" tail).
          CustomPaint(
            size: const Size(10, 6),
            painter: _MarkerTailPainter(color: ringColor),
          ),
        ],
      ),
    );
  }

  /// True if the seller is currently online **and** their last fix is
  /// fresh (within the last 5 minutes). Older fixes would still render
  /// `isOnline: true` from Firestore but the seller is in fact away.
  bool _isRecentlyOnline(SellerWithFish s) {
    if (!s.seller.isOnline) return false;
    final lastFix = s.seller.lastLocationUpdateAt;
    if (lastFix == null) return false;
    return DateTime.now().difference(lastFix) <
        const Duration(minutes: 5);
  }
}

class _MarkerTailPainter extends CustomPainter {
  final Color color;
  _MarkerTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MarkerTailPainter old) => old.color != color;
}
