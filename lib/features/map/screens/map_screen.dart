import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../map/demo_sellers.dart';
import '../constants/map_constants.dart';
import '../providers/map_provider.dart';
import '../services/permission_service.dart';
import '../widgets/gps_error_widget.dart';
import '../widgets/gps_loading_widget.dart';
import '../widgets/location_information_card.dart';

/// Production-ready Map & GPS Foundation screen.
///
/// Layout:
///   * AppBar with refresh action
///   * Google Map filling the body
///   * Floating "my location" button, anchored above the bottom card
///   * Bottom [LocationInformationCard]
///
/// The screen is responsible for:
///   * Driving the provider's [MapProvider.initialize] on first frame,
///   * Picking which dialog (if any) to show when [MapProvider.errorType]
///     transitions to a non-`none` value,
///   * Mapping [MapErrorType] to [GpsErrorType] for the error widget.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MapProvider>(
      create: (_) => MapProvider(),
      child: const _MapScreenContent(),
    );
  }
}

class _MapScreenContent extends StatefulWidget {
  const _MapScreenContent();

  @override
  State<_MapScreenContent> createState() => _MapScreenContentState();
}

class _MapScreenContentState extends State<_MapScreenContent> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;

  /// The height of the bottom telemetry card, measured after the first
  /// layout. The FAB uses this to sit just above the card.
  double _bottomCardHeight = MapConstants.bottomCardMinHeight;

  MapErrorType? _lastErrorShown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MapProvider>();
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _centerOnUser(MapProvider provider) async {
    final location = provider.currentLocation;
    if (location == null) return;

    final controller = await _mapControllerCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(location.latitude, location.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  /// Translate the provider's [MapErrorType] into the simpler
  /// [GpsErrorType] used by the widget.
  GpsErrorType _toWidgetErrorType(MapErrorType type) {
    switch (type) {
      case MapErrorType.gpsDisabled:
        return GpsErrorType.gpsDisabled;
      case MapErrorType.permissionDenied:
        return GpsErrorType.permissionDenied;
      case MapErrorType.permissionPermanentlyDenied:
        return GpsErrorType.permissionPermanentlyDenied;
      case MapErrorType.network:
        return GpsErrorType.network;
      case MapErrorType.locationUnavailable:
      case MapErrorType.unknown:
      case MapErrorType.none:
        return GpsErrorType.locationUnavailable;
    }
  }

  String _errorTitle(GpsErrorType type) {
    switch (type) {
      case GpsErrorType.gpsDisabled:
        return 'GPS Hardware Off';
      case GpsErrorType.permissionDenied:
        return 'Location Denied';
      case GpsErrorType.permissionPermanentlyDenied:
        return 'Permissions Blocked';
      case GpsErrorType.network:
        return 'No Internet';
      case GpsErrorType.locationUnavailable:
        return 'GPS Signal Lost';
      case GpsErrorType.unknown:
        return 'Unexpected Error';
    }
  }

  /// When the provider's errorType changes to a non-`none` value, surface
  /// the matching dialog. The provider stays UI-free; the screen drives the
  /// UX.
  void _maybeShowDialog(MapProvider provider) {
    final type = provider.errorType;
    if (type == _lastErrorShown || type == MapErrorType.none) return;
    _lastErrorShown = type;

    switch (type) {
      case MapErrorType.gpsDisabled:
        provider.permissions.showGpsDisabledDialog(
          context,
          onEnable: () async {
            await provider.permissions.openLocationSettings();
            if (!mounted) return;
            provider.retry();
          },
        );
      case MapErrorType.permissionDenied:
        provider.permissions.showPermissionDeniedDialog(
          context,
          onGrant: () async {
            final result = await provider.permissions.requestLocationPermission();
            if (!mounted) return;
            _onPermissionResolved(provider, result);
          },
        );
      case MapErrorType.permissionPermanentlyDenied:
        provider.permissions.showPermissionPermanentlyDeniedDialog(
          context,
          onOpenSettings: () async {
            await provider.permissions.openAppSettings();
            if (!mounted) return;
            provider.retry();
          },
        );
      case MapErrorType.network:
      case MapErrorType.locationUnavailable:
      case MapErrorType.unknown:
      case MapErrorType.none:
        // No dialog — the error widget on screen handles these.
        break;
    }
  }

  Future<void> _onPermissionResolved(
    MapProvider provider,
    PermissionCheckResult result,
  ) async {
    if (result is PermissionGranted) {
      await provider.retry();
    } else {
      // Re-initialize so the provider's permission state mirrors reality.
      await provider.retry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();

    // Run dialog side-effects after the build so we don't call setState
    // during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeShowDialog(provider);
    });

    const initialPosition = CameraPosition(
      target: LatLng(MapConstants.defaultLatitude, MapConstants.defaultLongitude),
      zoom: MapConstants.defaultZoom,
    );

    // Camera is constrained to the Zanzibar archipelago so users can't
    // pan off into the Indian Ocean. min/maxZoom keeps the view anchored
    // at a useful scale.
    final zanzibarBounds = LatLngBounds(
      southwest: const LatLng(
        MapConstants.boundsSouth,
        MapConstants.boundsWest,
      ),
      northeast: const LatLng(
        MapConstants.boundsNorth,
        MapConstants.boundsEast,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map & GPS Foundation'),
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.retry(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Map
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: initialPosition,
              minMaxZoomPreference: const MinMaxZoomPreference(
                MapConstants.minZoom,
                MapConstants.maxZoom,
              ),
              cameraTargetBounds: CameraTargetBounds(zanzibarBounds),
              markers: buildDemoSellerMarkerSet(),
              myLocationEnabled: provider.permissionState ==
                  LocationPermissionState.granted,
              myLocationButtonEnabled: false, // custom FAB below
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(controller);
                }
                _mapController = controller;
                if (provider.currentLocation != null) {
                  _centerOnUser(provider);
                }
              },
            ),
          ),

          // 2. Loading overlay
          if (provider.isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.gray900.withValues(alpha: 0.10),
                child: const GpsLoadingWidget(),
              ),
            ),

          // 3. Error overlay
          if (!provider.isLoading && provider.errorType != MapErrorType.none)
            Positioned.fill(
              child: GpsErrorWidget(
                errorType: _toWidgetErrorType(provider.errorType),
                title: _errorTitle(_toWidgetErrorType(provider.errorType)),
                description: provider.errorMessage,
                onRetry: () => provider.retry(),
              ),
            ),

          // 4. Floating "my location" button — anchored just above the
          // bottom card using the card's measured height.
          if (!provider.isLoading &&
              provider.errorType == MapErrorType.none &&
              provider.currentLocation != null)
            Positioned(
              right: AppSizes.paddingMD,
              bottom: _bottomCardHeight + AppSizes.paddingSM,
              child: FloatingActionButton(
                heroTag: 'map_my_location',
                onPressed: () => _centerOnUser(provider),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                ),
                child: const Icon(Icons.my_location_rounded),
              ),
            ),

          // 5. Bottom card. The card itself reports its own height so the
          // FAB above can stay anchored correctly as it grows / shrinks.
          if (!provider.isLoading &&
              provider.errorType == MapErrorType.none &&
              provider.currentLocation != null &&
              provider.lastUpdatedAt != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _MeasuredCard(
                onSizeChanged: (size) {
                  if ((size.height - _bottomCardHeight).abs() > 0.5) {
                    setState(() => _bottomCardHeight = size.height);
                  }
                },
                child: LocationInformationCard(
                  location: provider.currentLocation!,
                  address: provider.currentAddress ?? 'Determining your address...',
                  gpsEnabled: provider.gpsEnabled,
                  permissionStatus: provider.permissionState,
                  lastUpdatedAt: provider.lastUpdatedAt!,
                ),
              ),
            ),

          // 6. Top "sellers nearby" pill — confirms to the user that
          // the demo data is loaded. Tapping opens a sheet listing
          // each seller's name + fish so the user can verify visually.
          if (!provider.isLoading && provider.errorType == MapErrorType.none)
            Positioned(
              top: AppSizes.paddingMD,
              left: AppSizes.paddingMD,
              child: _DemoSellersPill(
                count: demoSellerMarkers.length,
                onTap: () => _showDemoSellersSheet(context),
              ),
            ),
        ],
      ),
    );
  }

  void _showDemoSellersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingLG,
            vertical: AppSizes.paddingMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              Text(
                'Demo sellers on the map',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                'These 5 sellers are loaded into Firestore on first launch '
                'and rendered here so you can confirm the foundation '
                'module works end-to-end.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray600,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              for (final s in demoSellerMarkers)
                _DemoSellerRow(seller: s),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill at the top-left of the map showing the number of demo
/// sellers + tap-to-list.
class _DemoSellersPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _DemoSellersPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMD,
            vertical: AppSizes.paddingXS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.store_rounded,
                  size: 14,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(width: AppSizes.paddingXS),
              Text(
                '$count sellers nearby',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: AppColors.gray600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the demo-sellers sheet.
class _DemoSellerRow extends StatelessWidget {
  final DemoSellerMarker seller;
  const _DemoSellerRow({required this.seller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: AppColors.primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSizes.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seller.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  seller.fish,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${seller.latitude.toStringAsFixed(4)}, '
            '${seller.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapper that reports its post-layout size to a parent callback.
/// Used to anchor the FAB above the bottom card.
class _MeasuredCard extends StatelessWidget {
  const _MeasuredCard({required this.child, required this.onSizeChanged});

  final Widget child;
  final ValueChanged<Size> onSizeChanged;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderObject = context.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        onSizeChanged(renderObject.size);
      }
    });
    return child;
  }
}