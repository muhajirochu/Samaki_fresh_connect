// Auto-upserts `streetSellers/{uid}` mirror docs.
//
// Why this exists:
//   - The buyer's geo-search queries `streetSellers/` (not `users/`).
//   - Without a mirror doc the geohash query returns nothing, the
//     map is empty, and the buyer never sees the seller.
//   - Sign-in is the natural hook: every time a street-seller
//     session becomes active we ensure the mirror exists with their
//     latest location + cached identity fields.
//
// Idempotent — safe to call on every auth change. Does NOT touch
// presence (`isOnline`, `lastLocationUpdateAt`) — those stay owned by
// the live tracker so they only flip when the seller intentionally
// goes online / moves.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import '../providers/auth_provider.dart';

// Inline geohash helper that matches the rest of the project.
const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
String _encodeGeohash(double lat, double lng) {
  String hash = '';
  double minLat = -90, maxLat = 90;
  double minLng = -180, maxLng = 180;
  bool evenBit = true;
  int bit = 0;
  int ch = 0;
  while (hash.length < 7) {
    if (evenBit) {
      final mid = (minLng + maxLng) / 2;
      if (lng >= mid) {
        ch = (ch << 1) | 1;
        minLng = mid;
      } else {
        ch = ch << 1;
        maxLng = mid;
      }
    } else {
      final mid = (minLat + maxLat) / 2;
      if (lat >= mid) {
        ch = (ch << 1) | 1;
        minLat = mid;
      } else {
        ch = ch << 1;
        maxLat = mid;
      }
    }
    evenBit = !evenBit;
    if (++bit == 5) {
      hash += _base32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return hash;
}

class SellerMirrorService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  static const String _collection = 'streetSellers';

  /// Stone Town — last-resort default so the mirror is always joinable
  /// by the buyer's geo query.
  static const double _fallbackLat = -6.1629;
  static const double _fallbackLng = 39.2026;

  /// Best-effort coordinate resolution from the seller's `users/` doc.
  (double, double) _coordsFor(UserModel user) {
    final loc = user.location;
    if (loc != null &&
        loc['latitude'] is num &&
        loc['longitude'] is num) {
      return (
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
    }
    return (_fallbackLat, _fallbackLng);
  }

  /// Ensure the seller has a mirror doc. Safe to call repeatedly —
  /// we only WRITE the identity/location fields, never presence.
  Future<void> ensureMirror(UserModel user) async {
    if (!_isAvailable) return;
    if (user.role != UserRole.streetSeller) return;

    try {
      final (lat, lng) = _coordsFor(user);
      final geo = _encodeGeohash(lat, lng);
      await _firestore.collection(_collection).doc(user.userId).set(
        {
          'sellerId': user.userId,
          'fullName': user.fullName,
          'phoneNumber': user.phoneNumber,
          'profilePictureUrl': user.profilePictureUrl,
          'latitude': lat,
          'longitude': lng,
          'location': {
            'latitude': lat,
            'longitude': lng,
            'geohash': geo,
          },
          'geo': GeoPoint(lat, lng),
          'geohash': geo,
          'marketName': locNameFromUser(user),
          'regionName': locNameFromUser(user, key: 'regionName'),
          'isActive': user.isActive,
          'isVerified': false,
          // We don't touch 'isOnline' — that's owned by the live
          // tracker. Default to false here; the tracker will flip it
          // when the seller taps "Go online" for the first time.
          'isOnline': false,
        },
        SetOptions(merge: true),
      );
      AppLogger.info('Mirror ensured for street seller ${user.userId}');
    } catch (e) {
      AppLogger.error('ensureMirror failed for ${user.userId}: $e');
    }
  }
}

String? locNameFromUser(UserModel user, {String key = 'marketName'}) {
  final loc = user.location;
  if (loc == null) return null;
  final value = loc[key];
  return value is String ? value : null;
}

final sellerMirrorServiceProvider = Provider<SellerMirrorService>(
  (ref) => SellerMirrorService(),
);

/// Riverpod hook: every time the active user changes, ensure their
/// `streetSellers/{uid}` mirror exists. Re-runs are safe.
final sellerMirrorBootstrapProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return;
  final svc = ref.read(sellerMirrorServiceProvider);
  // Fire-and-forget. Errors are logged; the app keeps running.
  Future.microtask(() => svc.ensureMirror(user));
});
