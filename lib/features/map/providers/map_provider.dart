import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/map_constants.dart';
import '../models/current_location_model.dart';
import '../models/result.dart';
import '../repositories/map_repository.dart';
import '../services/gps_service.dart';
import '../services/permission_service.dart';

/// State container for the Map & GPS Foundation screen.
///
/// The provider holds **state, not UI**. It has no `BuildContext` reference,
/// never calls `showDialog`, and never reads `Theme.of(context)`. The
/// screen is responsible for:
///   * calling [initialize] on first frame,
///   * deciding which dialog (if any) to show when [errorType] changes,
///   * rendering loading / error / map widgets.
///
/// The provider exposes:
///   * [isLoading] — true until the first fix arrives or an error is final,
///   * [permissionState] — mirrors the enum-style state for widgets that
///     want to show a badge,
///   * [gpsEnabled] — whether the OS reports GPS hardware on,
///   * [currentLocation] — the latest fix (or null),
///   * [currentAddress] — the latest reverse-geocoded address (cached),
///   * [errorType] / [errorMessage] — UI-affecting failure info,
///   * [lastUpdatedAt] — wall-clock time of the latest fix.
class MapProvider with ChangeNotifier {
  MapProvider({MapRepository? repository})
      : _repository = repository ?? MapRepository();

  final MapRepository _repository;

  // ── State fields ────────────────────────────────────────────────────────────

  bool _isLoading = true;
  LocationPermissionState _permissionState = LocationPermissionState.denied;
  bool _gpsEnabled = false;
  CurrentLocationModel? _currentLocation;
  String? _currentAddress;
  DateTime? _lastUpdatedAt;
  MapErrorType _errorType = MapErrorType.none;
  String _errorMessage = '';

  StreamSubscription<Result<CurrentLocationModel, GpsFailure>>?
      _locationSubscription;

  // ── Public getters ─────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  LocationPermissionState get permissionState => _permissionState;
  bool get gpsEnabled => _gpsEnabled;
  CurrentLocationModel? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  double? get currentAccuracy => _currentLocation?.accuracy;
  double? get currentSpeed => _currentLocation?.speed;
  double? get currentHeading => _currentLocation?.heading;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  MapErrorType get errorType => _errorType;
  String get errorMessage => _errorMessage;

  /// Re-exposes the permission service so the screen can open settings /
  /// show dialogs without holding its own reference.
  PermissionService get permissions => _repository.permissions;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Reads permission, requests it if needed, then fetches the first fix
  /// and starts the live stream.
  ///
  /// Safe to call multiple times — it cancels any in-flight subscription
  /// first.
  Future<void> initialize() async {
    _setLoading(resetError: true);

    // 1. Service enabled?
    final initialCheck = await _repository.checkPermission();
    _applyPermissionResult(initialCheck);

    if (initialCheck is ServiceDisabled) {
      _setError(MapErrorType.gpsDisabled, MapConstants.errorGpsDisabled);
      return;
    }

    // 2. Need to ask for permission?
    PermissionCheckResult current = initialCheck;
    if (current is PermissionDenied) {
      current = await _repository.requestPermission();
      _applyPermissionResult(current);
    }

    if (current is ServiceDisabled) {
      _setError(MapErrorType.gpsDisabled, MapConstants.errorGpsDisabled);
      return;
    }
    if (current is PermissionDenied) {
      _setError(
        MapErrorType.permissionDenied,
        MapConstants.errorPermissionDenied,
      );
      return;
    }
    if (current is PermissionPermanentlyDenied) {
      _setError(
        MapErrorType.permissionPermanentlyDenied,
        MapConstants.errorPermissionPermanentlyDenied,
      );
      return;
    }

    // 3. Permission is granted — fetch a one-shot fix then start the stream.
    await _fetchInitialFixAndListen();
  }

  /// Re-runs [initialize]. Used by the retry button.
  Future<void> retry() async {
    _stopListening();
    _repository.clearGeocodeCache();
    await initialize();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _applyPermissionResult(PermissionCheckResult result) {
    _gpsEnabled = result is! ServiceDisabled;
    _permissionState = switch (result) {
      PermissionGranted() => LocationPermissionState.granted,
      PermissionDenied() => LocationPermissionState.denied,
      PermissionPermanentlyDenied() =>
        LocationPermissionState.permanentlyDenied,
      ServiceDisabled() => LocationPermissionState.serviceDisabled,
    };
    notifyListeners();
  }

  Future<void> _fetchInitialFixAndListen() async {
    final fixResult = await _repository.getCurrentLocation();
    final ok = fixResult.fold(
      ok: (loc) {
        _currentLocation = loc;
        _lastUpdatedAt = loc.timestamp;
        return true;
      },
      err: (failure) {
        _mapGpsFailure(failure);
        return false;
      },
    );

    if (ok) {
      // Resolve the first address — this can return null if the geocoder
      // fails, in which case we keep the existing (empty) address and let
      // the next stream tick try again.
      final address = await _repository.reverseGeocode(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      if (address != null) {
        _currentAddress = address;
      }
    }

    _isLoading = false;
    notifyListeners();

    if (ok) {
      _startListening();
    }
  }

  void _startListening() {
    _stopListening();
    _locationSubscription = _repository
        .getLocationStream()
        .listen(
          _onStreamEvent,
          onError: (Object e) {
            // Belt-and-braces: the stream emits Err values for known
            // failures, but a raw exception can still escape.
            _setError(MapErrorType.unknown, '${MapConstants.errorUnknown}: $e');
          },
        );
  }

  void _stopListening() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _onStreamEvent(
    Result<CurrentLocationModel, GpsFailure> event,
  ) async {
    event.fold(
      ok: (loc) async {
        _currentLocation = loc;
        _lastUpdatedAt = loc.timestamp;
        _errorType = MapErrorType.none;
        _errorMessage = '';
        notifyListeners();

        final address = await _repository.reverseGeocode(
          loc.latitude,
          loc.longitude,
        );
        if (address != null) {
          _currentAddress = address;
          notifyListeners();
        }
      },
      err: _mapGpsFailure,
    );
  }

  void _mapGpsFailure(GpsFailure failure) {
    switch (failure) {
      case GpsFailure.serviceDisabled:
        _setError(MapErrorType.gpsDisabled, MapConstants.errorGpsDisabled);
      case GpsFailure.permissionDenied:
        _setError(
          MapErrorType.permissionDenied,
          MapConstants.errorPermissionDenied,
        );
      case GpsFailure.timeout:
      case GpsFailure.unknown:
        _setError(
          MapErrorType.locationUnavailable,
          MapConstants.errorLocationUnavailable,
        );
    }
  }

  void _setLoading({bool resetError = false}) {
    _isLoading = true;
    if (resetError) {
      _errorType = MapErrorType.none;
      _errorMessage = '';
    }
    notifyListeners();
  }

  void _setError(MapErrorType type, String message) {
    _errorType = type;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}