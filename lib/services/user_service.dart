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
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `createdAt DESC` single-field index is
      // available.
      return _firestore
          .collection('users')
          .snapshots()
          .map((snap) {
        final list = <UserModel>[];
        for (final d in snap.docs) {
          try {
            list.add(UserModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamAllUsers: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
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
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(role, createdAt DESC)` composite index
      // is available.
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'streetSeller')
          .snapshots()
          .map((snap) {
        final list = <UserModel>[];
        for (final d in snap.docs) {
          try {
            list.add(UserModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamAllStreetSellers: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
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

  /// Stream every buyer in the system — used by the admin Manage
  /// Buyers screen. Pre-filters on `role == buyer` so the screen
  /// doesn't have to filter client-side.
  Stream<List<UserModel>> streamAllBuyers() {
    if (!_isFirebaseAvailable) return Stream.value(<UserModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(role, createdAt DESC)` composite index
      // is available.
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'buyer')
          .snapshots()
          .map((snap) {
        final list = <UserModel>[];
        for (final d in snap.docs) {
          try {
            list.add(UserModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamAllBuyers: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming buyers: $e');
      return Stream.value(<UserModel>[]);
    }
  }

  /// Stream every seller, including pending approval and rejected
  /// applicants. Used by the Manage Street Sellers screen to give
  /// the admin a complete pipeline view (awaiting approval,
  /// approved, suspended, rejected).
  Stream<List<UserModel>> streamAllSellersFull() {
    if (!_isFirebaseAvailable) return Stream.value(<UserModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(role, createdAt DESC)` composite index
      // is available.
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'streetSeller')
          .snapshots()
          .map((snap) {
        final list = <UserModel>[];
        for (final d in snap.docs) {
          try {
            list.add(UserModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamAllSellersFull: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e) {
      AppLogger.error('Error streaming sellers full: $e');
      return Stream.value(<UserModel>[]);
    }
  }

  /// Approve a street-seller account. Sets `isApproved = true` and
  /// stamps the auditor fields so the moderation timeline stays
  /// intact.
  Future<void> approveSeller(String sellerId, String approverUid) async {
    if (!_isFirebaseAvailable) return;
    try {
      await _firestore.collection('users').doc(sellerId).update({
        'isApproved': true,
        'approvedBy': approverUid,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Seller $sellerId approved by $approverUid');
    } catch (e) {
      AppLogger.error('Error approving seller $sellerId: $e');
      rethrow;
    }
  }

  /// Revoke a previously-approved seller account. Sets
  /// `isApproved = false` so the seller can no longer post listings
  /// but keeps their data so the action is reversible.
  Future<void> revokeSellerApproval(String sellerId, String revokerUid) async {
    if (!_isFirebaseAvailable) return;
    try {
      await _firestore.collection('users').doc(sellerId).update({
        'isApproved': false,
        'approvedBy': revokerUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Seller $sellerId approval revoked by $revokerUid');
    } catch (e) {
      AppLogger.error('Error revoking seller $sellerId: $e');
      rethrow;
    }
  }

  /// Suspend a user (buyer or seller). Sets `isActive = false` so
  /// the user cannot sign in or interact with the marketplace.
  /// Reversible via [reactivateUser].
  Future<void> suspendUser(String userId, String actorUid) async {
    await setUserActive(userId, false);
    AppLogger.info('User $userId suspended by $actorUid');
  }

  /// Reactivate a previously-suspended user. Sets `isActive = true`.
  Future<void> reactivateUser(String userId, String actorUid) async {
    await setUserActive(userId, true);
    AppLogger.info('User $userId reactivated by $actorUid');
  }

  /// Live count of users that have [role]. Used by the admin
  /// dashboard's Total Sellers / Total Buyers tiles.
  Stream<int> streamUserCountByRole(String role) {
    if (!_isFirebaseAvailable) return Stream.value(0);
    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots()
          .map((snap) => snap.docs.length);
    } catch (e) {
      AppLogger.error('Error streaming count for role $role: $e');
      return Stream.value(0);
    }
  }

  /// Stream of street-sellers filtered by approval flag. Used by
  /// the Manage Street Sellers "Awaiting approval / Approved /
  /// Rejected" segmented filter.
  Stream<List<UserModel>> streamSellersByApproval(bool isApproved) {
    if (!_isFirebaseAvailable) return Stream.value(<UserModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(role, isApproved, createdAt DESC)`
      // composite index is available.
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'streetSeller')
          .where('isApproved', isEqualTo: isApproved)
          .snapshots()
          .map((snap) {
        final list = <UserModel>[];
        for (final d in snap.docs) {
          try {
            list.add(UserModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamSellersByApproval: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e) {
      AppLogger.error(
        'Error streaming sellers by approval $isApproved: $e',
      );
      return Stream.value(<UserModel>[]);
    }
  }

  /// One-shot client-side search across all sellers. Cheap enough
  /// for admin use because `streamAllSellersFull` already caps
  /// the underlying read.
  Future<List<UserModel>> searchSellers(String rawQuery) async {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return <UserModel>[];
    if (!_isFirebaseAvailable) return <UserModel>[];
    try {
      final snap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'streetSeller')
          .limit(500)
          .get();
      final list = <UserModel>[];
      for (final d in snap.docs) {
        try {
          list.add(UserModel.fromJson(d.data()));
        } catch (e) {
          AppLogger.warning(
              'searchSellers: dropping malformed doc ${d.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.phoneNumber.toLowerCase().contains(q))
          .toList(growable: false);
    } catch (e) {
      AppLogger.error('Error searching sellers: $e');
      return <UserModel>[];
    }
  }

  /// Same as [searchSellers] but against the buyers collection.
  Future<List<UserModel>> searchBuyers(String rawQuery) async {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return <UserModel>[];
    if (!_isFirebaseAvailable) return <UserModel>[];
    try {
      final snap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'buyer')
          .limit(500)
          .get();
      final list = <UserModel>[];
      for (final d in snap.docs) {
        try {
          list.add(UserModel.fromJson(d.data()));
        } catch (e) {
          AppLogger.warning(
              'searchBuyers: dropping malformed doc ${d.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.phoneNumber.toLowerCase().contains(q))
          .toList(growable: false);
    } catch (e) {
      AppLogger.error('Error searching buyers: $e');
      return <UserModel>[];
    }
  }

  /// Stream every listing owned by [sellerId]. Used by the admin
  /// Seller Profile screen to show their catalogue without
  /// re-instantiating the buyer-facing list.
  Stream<List<Map<String, dynamic>>> streamSellerListingsRaw(String sellerId) {
    if (!_isFirebaseAvailable) return Stream.value(<Map<String, dynamic>>[]);
    try {
      return _firestore
          .collection('fishListings')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => d.data()).toList(growable: false));
    } catch (e) {
      AppLogger.error('Error streaming seller listings: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }
}
