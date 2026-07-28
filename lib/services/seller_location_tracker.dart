// Live GPS tracker for street sellers.
//
// Lifecycle:
//   - The seller taps "Go online" on their dashboard.
//   - We call `start()` which subscribes to `Geolocator.getPositionStream`
//     and switches their Firestore doc to `isOnline = true`.
//   - Each fix: compute fresh geohash, decide whether the seller has
//     moved enough to warrant a Firestore write (debounce by distance —
//     low-end devices emit fixes every 1s and we don't want to write at
//     that rate), then push a `toLocationPatch` update.
//   - On "Go offline" or `dispose`: cancel the stream subscription,
//     write a final `isOnline = false` patch.
//
// All state lives behind a `ChangeNotifier` so a `StateNotifierProvider`
// can keep the UI in sync with the active/inactive state.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/street_seller_model.dart';
import '../utils/logger.dart';
import '../utils/zanzibar_bounds.dart';
import 'geohash_service.dart';

enum SellerTrackerStatus {
  /// The tracker has not been started yet (or has been disposed).
  idle,
  /// Waiting on the OS location service or permission grant.
  waitingForPermission,
  /// Actively streaming fixes and writing to Firestore.
  online,
  /// Permission was denied or a runtime error occurred.
  error,
}

class SellerLocationTracker extends ChangeNotifier {
  SellerLocationTracker();

  static const String _collection = 'streetSellers';

  /// Minimum metres between writes — keeps us from hammering Firestore
  /// when the seller is stationary. Default 25 m matches the typical
  /// GPS noise floor on a Samsung A-series.
  static const double _minMoveMeters = 25.0;

  /// Maximum interval between writes even if the seller hasn't moved —
  /// keeps the buyer's "last seen" indicator fresh.
  static const Duration _maxWriteInterval = Duration(seconds: 30);

  /// Time we give the OS to deliver the first fix before erroring out.
  static const Duration _startupTimeout = Duration(seconds: 12);

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  StreamSubscription<Position>? _positionSub;
  Timer? _heartbeatTimer;
  SellerTrackerStatus _status = SellerTrackerStatus.idle;
  String? _errorMessage;
  String? _sellerId;
  DateTime? _lastWriteAt;
  Position? _lastWrittenFix;

  SellerTrackerStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _status == SellerTrackerStatus.online;

  Future<bool> start(String sellerId) async {
    if (_status == SellerTrackerStatus.online && _sellerId == sellerId) {
      // Idempotent — same seller already tracked.
      return true;
    }
    await stop(writeOfflinePatch: false);

    _sellerId = sellerId;
    _setStatus(SellerTrackerStatus.waitingForPermission);

    if (!_isAvailable) {
      _setError('Firebase is not available on this device.');
      return false;
    }

    // 1) OS-level service check.
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      _setError('Location services are off. Turn them on to go online.');
      return false;
    }

    // 2) Permission.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setError(
        'Location permission denied. Grant it from system settings.',
      );
      return false;
    }

    // 3) Flip the online flag first — if the GPS stream hangs for any
    //    reason, at least the buyer knows the seller *intends* to be live.
    await _firestore.collection(_collection).doc(sellerId).set(
          {
            'isOnline': true,
            'sellerId': sellerId,
            // Triggers Cloud Functions / triggers if any are watching.
            'onlineSince': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

    // 4) Subscribe to the position stream.
    final completer = Completer<void>();
    try {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // OS-level coarse filter; we have our own
        ),
      ).listen(
        (pos) {
          if (!completer.isCompleted) completer.complete();
          _handleFix(pos);
        },
        onError: (e, st) {
          AppLogger.error('Position stream error: $e');
          _setError('GPS error: $e');
          stop(writeOfflinePatch: true);
        },
      );
    } catch (e) {
      _setError('Could not start GPS: $e');
      return false;
    }

    // We optimistically mark "online" the moment permission + service
    // checks succeed. The first fix arrives through the stream and may
    // take a moment longer, but the buyer already sees the seller.
    _setStatus(SellerTrackerStatus.online);

    // 5) Heartbeat — writes a marker every `_maxWriteInterval` so the
    //    buyer's `lastSeen` indicator doesn't go stale even if the
    //    seller is parked. Independent of the position stream.
    _heartbeatTimer = Timer.periodic(_maxWriteInterval, (_) async {
      if (_lastWrittenFix == null) return;
      await _writeFix(_lastWrittenFix!, force: true);
    });

    // First-fix timeout in case GPS never delivers.
    unawaited(_startupTimeoutTimer(completer));
    return true;
  }

  Future<void> _startupTimeoutTimer(Completer<void> completer) async {
    await Future<void>.delayed(_startupTimeout);
    if (!completer.isCompleted && _status == SellerTrackerStatus.online) {
      AppLogger.warning(
          'GPS did not deliver first fix within $_startupTimeout — still online');
    }
  }

  Future<void> _handleFix(Position pos) async {
    final last = _lastWrittenFix;
    if (last != null) {
      final moved = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        pos.latitude,
        pos.longitude,
      );
      final movedEnough = moved >= _minMoveMeters;
      final staleEnough = _lastWriteAt == null ||
          DateTime.now().difference(_lastWriteAt!) >= _maxWriteInterval;
      if (!movedEnough && !staleEnough) return;
    }
    // Reject fixes outside Zanzibar. A momentary GPS glitch (lost
    // signal, VPN, an emulator anchored to a faraway landmark) can
    // produce a coordinate that is provably wrong for the Zanzibar
    // marketplace. Skipping the write keeps the last good fix; the
    // heartbeat will re-emit it on the next tick so `lastSeen`
    // doesn't go stale.
    if (!ZanzibarBounds.isValidZanzibarCoord(pos.latitude, pos.longitude)) {
      AppLogger.warning(
        'Seller GPS fix outside Zanzibar (${pos.latitude}, ${pos.longitude}) '
        '— skipping write, keeping last good fix.',
      );
      return;
    }
    await _writeFix(pos);
  }

  Future<void> _writeFix(Position pos, {bool force = false}) async {
    final sellerId = _sellerId;
    if (sellerId == null) return;

    final geo = GeohashService.encode(pos.latitude, pos.longitude);
    final patch = StreetSellerModel(
      sellerId: sellerId,
      fullName: '', // unused — toMap/toLocationPatch ignores this
      phoneNumber: '',
      latitude: pos.latitude,
      longitude: pos.longitude,
      geohash: geo,
      headingDegrees: pos.heading.isNaN ? null : pos.heading,
      speedMps: pos.speed.isNaN ? null : pos.speed,
      accuracyMeters: pos.accuracy,
      lastLocationUpdateAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toLocationPatch(geo);

    try {
      await _firestore
          .collection(_collection)
          .doc(sellerId)
          .set(patch, SetOptions(merge: true));
      _lastWriteAt = DateTime.now();
      _lastWrittenFix = pos;
      if (kDebugMode) {
        AppLogger.debug(
            'Updated seller $sellerId → ${pos.latitude},${pos.longitude} '
            '($geo)${force ? ' (heartbeat)' : ''}');
      }
    } catch (e) {
      AppLogger.error('Write failed for $sellerId: $e');
      _setError('Firestore write failed: $e');
    }
  }

  Future<void> stop({bool writeOfflinePatch = true}) async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _positionSub?.cancel();
    _positionSub = null;

    final sellerId = _sellerId;
    if (writeOfflinePatch && sellerId != null && _isAvailable) {
      try {
        await _firestore.collection(_collection).doc(sellerId).set(
          {
            'isOnline': false,
            'lastOfflineAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        AppLogger.error('Failed to write offline patch: $e');
      }
    }

    _sellerId = null;
    _lastWriteAt = null;
    _lastWrittenFix = null;
    _setStatus(SellerTrackerStatus.idle);
  }

  void _setStatus(SellerTrackerStatus s) {
    if (_status == s) return;
    _status = s;
    if (s != SellerTrackerStatus.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = SellerTrackerStatus.error;
    AppLogger.warning('Tracker error: $message');
    notifyListeners();
  }

  @override
  void dispose() {
    // Best-effort synchronous cleanup. The actual write is fired off
    // without awaiting — Firestore's offline queue keeps it safe.
    unawaited(stop(writeOfflinePatch: true));
    super.dispose();
  }
}

/// Wrap a [Position] into a typed tuple so callers don't need to import
/// `geolocator` directly.
class SellerFix {
  final double latitude;
  final double longitude;
  final double? headingDegrees;
  final double? speedMps;
  final double? accuracyMeters;
  final DateTime observedAt;
  const SellerFix({
    required this.latitude,
    required this.longitude,
    required this.observedAt,
    this.headingDegrees,
    this.speedMps,
    this.accuracyMeters,
  });
}