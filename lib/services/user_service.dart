import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import '../utils/logger.dart';

class UserService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  /// Fetch user data from Firestore by user ID
  Future<UserModel?> fetchUserById(String userId) async {
    if (!_isFirebaseAvailable) return null;
    try {
      AppLogger.info('Fetching user data for: $userId');

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
        AppLogger.info(
            'User data fetched successfully. Role: ${user.role.displayName}');
        return user;
      } else {
        AppLogger.warning('User document not found: $userId');
        return null;
      }
    } catch (e) {
      AppLogger.error('Error fetching user data: $e');
      return null;
    }
  }

  /// Save user data to Firestore
  Future<void> saveUser(UserModel user) async {
    if (!_isFirebaseAvailable) return;
    try {
      AppLogger.info('Saving user data for: ${user.userId}');

      await _firestore
          .collection('users')
          .doc(user.userId)
          .set(user.toJson(), SetOptions(merge: true));

      AppLogger.info('User data saved successfully');
    } catch (e) {
      AppLogger.error('Error saving user data: $e');
      rethrow;
    }
  }

  /// Stream user data changes (real-time)
  Stream<UserModel?> userStream(String userId) {
    if (!_isFirebaseAvailable) return Stream.value(null);
    try {
      return _firestore.collection('users').doc(userId).snapshots().map((doc) {
        if (doc.exists) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }
        return null;
      });
    } catch (e) {
      AppLogger.error('Error creating user stream: $e');
      return const Stream.empty();
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    if (!_isFirebaseAvailable) return;
    try {
      AppLogger.info('Updating user role for: $userId to $newRole');

      await _firestore
          .collection('users')
          .doc(userId)
          .update({'role': newRole});

      AppLogger.info('User role updated successfully');
    } catch (e) {
      AppLogger.error('Error updating user role: $e');
      rethrow;
    }
  }

  /// Update user profile fields
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    if (!_isFirebaseAvailable) return;
    try {
      AppLogger.info('Updating profile for: $userId');
      await _firestore.collection('users').doc(userId).update({
        ...fields,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      AppLogger.info('Profile updated successfully');
    } catch (e) {
      AppLogger.error('Error updating profile: $e');
      rethrow;
    }
  }

  /// Persist a seller's shop location to their user doc.
  ///
  /// Writes both a denormalised top-level shape (for single-field geo
  /// queries) and a nested `location` map (for human readers). The
  /// `geohash` is optional — callers that have already computed one pass
  /// it in; otherwise it is left null.
  Future<void> updateUserLocation(
    String userId, {
    required double latitude,
    required double longitude,
    String? geohash,
  }) async {
    if (!_isFirebaseAvailable) return;
    try {
      AppLogger.info('Updating location for user: $userId');
      await _firestore.collection('users').doc(userId).update({
        'latitude': latitude,
        'longitude': longitude,
        if (geohash != null) 'geohash': geohash,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          if (geohash != null) 'geohash': geohash,
        },
        'geo': GeoPoint(latitude, longitude),
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      AppLogger.info('User location updated successfully');
    } catch (e) {
      AppLogger.error('Error updating user location: $e');
      rethrow;
    }
  }

  /// Stream every user in the system — used by the admin Manage
  /// Street Sellers screen. Backed by Firestore snapshots so the
  /// list refreshes live as new users register or are approved /
  /// blocked.
  Stream<List<UserModel>> streamAllUsers() {
    if (!_isFirebaseAvailable) return Stream.value(<UserModel>[]);
    try {
      return _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => UserModel.fromJson(d.data()))
              .toList(growable: false));
    } catch (e) {
      AppLogger.error('Error streaming all users: $e');
      return Stream.value(<UserModel>[]);
    }
  }

  /// Stream every street seller — convenience over [streamAllUsers]
  /// that pre-filters on `role == streetSeller` so the admin screen
  /// does not have to filter client-side.
  Stream<List<UserModel>> streamAllStreetSellers() {
    if (!_isFirebaseAvailable) return Stream.value(<UserModel>[]);
    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'streetSeller')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => UserModel.fromJson(d.data()))
              .toList(growable: false));
    } catch (e) {
      AppLogger.error('Error streaming street sellers: $e');
      return Stream.value(<UserModel>[]);
    }
  }

  /// Stream a count of users grouped by role. Returns a Map<role, int>
  /// so the dashboard can show live totals without enumerating every
  /// document. Cheap to render because Firestore returns the
  /// snapshot and we bucket in one pass.
  Stream<Map<String, int>> streamUserCountsByRole() {
    if (!_isFirebaseAvailable) {
      return Stream.value(<String, int>{
        'buyer': 0,
        'streetSeller': 0,
        'admin': 0,
      });
    }
    try {
      return _firestore.collection('users').snapshots().map((snap) {
        final counts = <String, int>{
          'buyer': 0,
          'streetSeller': 0,
          'admin': 0,
        };
        for (final doc in snap.docs) {
          final role = (doc.data()['role'] as String?) ?? 'buyer';
          counts[role] = (counts[role] ?? 0) + 1;
        }
        return counts;
      });
    } catch (e) {
      AppLogger.error('Error streaming user counts: $e');
      return Stream.value(<String, int>{
        'buyer': 0,
        'streetSeller': 0,
        'admin': 0,
      });
    }
  }

  /// Block / unblock a user (admin moderation action).
  ///
  /// Sets `isActive = false` so the user cannot sign in or appear in
  /// marketplace listings, but preserves their data so the action is
  /// reversible.
  Future<void> setUserActive(String userId, bool isActive) async {
    if (!_isFirebaseAvailable) return;
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('User $userId active flag set to $isActive');
    } catch (e) {
      AppLogger.error('Error toggling active flag for $userId: $e');
      rethrow;
    }
  }
}
