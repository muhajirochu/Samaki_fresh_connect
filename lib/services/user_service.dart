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
}
