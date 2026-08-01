import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import '../utils/logger.dart';

class UserService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get _isFirebaseAvailable => Firebase.apps.isNotEmpty;

  /// Lenient fallback parser used when [UserModel.fromJson] throws on
  /// a malformed field. Returns a fully populated [UserModel] with
  /// safe defaults for any field that could not be parsed, so the
  /// caller can still log the user in instead of seeing "User
  /// profile not found".
  ///
  /// Required fields that fail to parse are filled with these
  /// defaults:
  ///   - [UserModel.createdAt] / [UserModel.updatedAt] → DateTime.now()
  ///   - [UserModel.email]       → the lookup email (or empty)
  ///   - [UserModel.fullName]    → the email local-part (or empty)
  ///   - [UserModel.role]        → falls back to [UserRole.buyer]
  ///     (the [UserRoleConverter] is already lenient, so a parse
  ///     error here means the field is genuinely missing — safer
  ///     to grant the lowest privilege than to deny sign-in).
  ///
  /// If a truly structural error is encountered (e.g. the doc isn't
  /// a Map at all), returns `null` so the caller can fall through.
  UserModel? _recoverUserModel(Map<String, dynamic> data, String userId) {
    final now = DateTime.now();
    final email = (data['email'] as String?)?.trim() ?? '';
    final fallbackName = email.isNotEmpty
        ? email.split('@').first.replaceAll(RegExp(r'[^A-Za-z0-9]'), ' ')
        : 'User';
    final safe = <String, dynamic>{
      'userId': data['userId'] ?? userId,
      'email': email,
      'fullName': (data['fullName'] as String?)?.trim().isNotEmpty == true
          ? data['fullName']
          : fallbackName,
      'phoneNumber': (data['phoneNumber'] as String?) ?? '',
      'role': data['role'] is String ? data['role'] : 'buyer',
      'isActive': data['isActive'] is bool ? data['isActive'] : true,
      'isApproved': data['isApproved'] is bool ? data['isApproved'] : false,
      'totalListings': data['totalListings'] is int ? data['totalListings'] : 0,
      'totalOrders': data['totalOrders'] is int ? data['totalOrders'] : 0,
      'totalSales': data['totalSales'] is num ? data['totalSales'] : 0.0,
      'averageRating':
          data['averageRating'] is num ? data['averageRating'] : 0.0,
      'totalEarnings':
          data['totalEarnings'] is num ? data['totalEarnings'] : 0.0,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      // Pass through any optional fields whose type matches; drop
      // the rest. This keeps the lenient parser cheap and bounded.
      if (data['profilePictureUrl'] is String)
        'profilePictureUrl': data['profilePictureUrl'],
      if (data['location'] is Map)
        'location': Map<String, dynamic>.from(data['location'] as Map),
    };
    return UserModel.fromJson(safe);
  }

  /// Fetch user data from Firestore by user ID.
  ///
  /// Strategy (in order):
  ///   1. Direct doc lookup at `users/{uid}` — fast path.
  ///   2. Email-exact query — catches documents saved with `.add()` or
  ///      a wrong ID by an older version of the app.
  ///   3. Case-insensitive email retry — catches mixed-case mismatches.
  ///   4. Full collection scan (≤500 docs) — absolute last resort for
  ///      accounts where the `email` field is missing from Firestore.
  ///
  /// When found via fallback, the document is **migrated** to
  /// `users/{uid}` so the next login uses the fast path.
  Future<UserModel?> fetchUserById(String userId, {String? email}) async {
    if (!_isFirebaseAvailable) return null;
    try {
      AppLogger.debug('fetchUserById: START uid=$userId email=$email');

      // ── 1. Direct doc lookup (fast path) ────────────────────────
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await _firestore.collection('users').doc(userId).get();
      } on FirebaseException catch (fe) {
        AppLogger.error(
            'fetchUserById: Firestore GET users/$userId FAILED '
            'code=${fe.code} msg=${fe.message}');
        rethrow;
      }

      AppLogger.debug(
          'fetchUserById: users/$userId exists=${doc.exists} '
          'fields=${doc.exists ? doc.data()?.keys.toList() : 'N/A'}');

      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['userId'] = data['userId'] ?? doc.id;
        try {
          final user = UserModel.fromJson(data);
          AppLogger.info(
              'fetchUserById: SUCCESS by UID. role=${user.role.displayName}');
          return user;
        } catch (parseErr) {
          // HARD FIX: profile exists but a field was malformed
          // (e.g. `createdAt` set to a string in an old write).
          // Returning `null` here left the user staring at "User
          // profile not found" even though their doc was on the
          // server. Now we salvage what we can — fill missing
          // required fields with safe defaults, parse the rest,
          // and return the user. The next write will overwrite
          // the malformed fields with valid values.
          AppLogger.warning(
              'fetchUserById: UserModel.fromJson THREW for users/$userId — '
              'attempting lenient recovery\n'
              'data=$data\nerr=$parseErr');
          try {
            final recovered = _recoverUserModel(data, userId);
            if (recovered != null) {
              AppLogger.info(
                  'fetchUserById: Recovered user with lenient parser. '
                  'role=${recovered.role.displayName}');
              return recovered;
            }
          } catch (recoveryErr) {
            AppLogger.error(
                'fetchUserById: Lenient recovery also failed: $recoveryErr');
          }
          return null;
        }
      }

      // ── 2. Email-based fallback (self-healing migration) ────────
      //
      // The document at `users/{uid}` doesn't exist. This is the
      // common case for users whose Firestore records were created
      // outside the app (e.g. Firebase Console import, direct
      // writes, or old code that used a different doc-id strategy).
      //
      // We query by email, and if found, copy the data to
      // `users/{uid}` so the next login is instant.
      if (email != null && email.isNotEmpty) {
        AppLogger.info(
            'fetchUserById: users/$userId NOT FOUND — trying email lookup: $email');

        // Try exact email match first.
        QuerySnapshot<Map<String, dynamic>> emailQuery;
        try {
          emailQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
        } on FirebaseException catch (fe) {
          AppLogger.error(
              'fetchUserById: email query FAILED code=${fe.code} msg=${fe.message}');
          rethrow;
        }

        AppLogger.debug(
            'fetchUserById: email query matched ${emailQuery.docs.length} doc(s)');

        // ── 3. Case-insensitive fallback — some older registrations
        // stored the email in a different case. We re-run with
        // lowercase if the first query returned nothing.
        if (emailQuery.docs.isEmpty) {
          final lowerEmail = email.toLowerCase();
          if (lowerEmail != email) {
            AppLogger.info(
                'fetchUserById: retrying with lowercase email: $lowerEmail');
            try {
              emailQuery = await _firestore
                  .collection('users')
                  .where('email', isEqualTo: lowerEmail)
                  .limit(1)
                  .get();
              AppLogger.debug(
                  'fetchUserById: lowercase query matched ${emailQuery.docs.length} doc(s)');
            } on FirebaseException catch (fe) {
              AppLogger.warning(
                  'fetchUserById: lowercase email query failed: ${fe.code}');
            }
          }
        }

        if (emailQuery.docs.isNotEmpty) {
          final oldDoc = emailQuery.docs.first;
          final data = Map<String, dynamic>.from(oldDoc.data());
          // Stamp the canonical userId into the data.
          data['userId'] = userId;

          AppLogger.info(
              'fetchUserById: Found user by email (oldDocId=${oldDoc.id}). '
              'Migrating to users/$userId...');

          // Write the canonical document at `users/{uid}`.
          try {
            await _firestore
                .collection('users')
                .doc(userId)
                .set(data, SetOptions(merge: true));
            AppLogger.info('fetchUserById: Migration write succeeded');
          } on FirebaseException catch (fe) {
            AppLogger.error(
                'fetchUserById: Migration SET failed code=${fe.code} msg=${fe.message}');
            // Even if migration write fails, still return the user
            // so they can log in — migration will retry next login.
          }

          // Delete the orphaned document if its ID differs.
          if (oldDoc.id != userId) {
            try {
              await _firestore.collection('users').doc(oldDoc.id).delete();
              AppLogger.info('fetchUserById: Deleted orphan doc: users/${oldDoc.id}');
            } catch (e) {
              AppLogger.warning(
                  'fetchUserById: Could not delete orphan doc ${oldDoc.id}: $e');
            }
          }

          try {
            final user = UserModel.fromJson(data);
            AppLogger.info(
                'fetchUserById: SUCCESS via email migration. role=${user.role.displayName}');
            return user;
          } catch (parseErr, parseSt) {
            AppLogger.error(
                'fetchUserById: UserModel.fromJson THREW during migration\n'
                'data=$data\nerr=$parseErr\n$parseSt');
            return null;
          }
        }

        // ── 4. Last resort: scan all users and match by email ──────
        // Only runs when BOTH the UID lookup and the email-indexed
        // query fail — e.g. the `email` field is missing from the
        // Firestore doc entirely. Expensive but only triggers once
        // per broken account.
        AppLogger.warning(
            'fetchUserById: email query found nothing. '
            'Running full-collection scan for $email (last resort)...');
        try {
          final allSnap =
              await _firestore.collection('users').limit(500).get();
          AppLogger.debug(
              'fetchUserById: scan returned ${allSnap.docs.length} docs');

          for (final d in allSnap.docs) {
            final storedEmail = (d.data()['email'] as String? ?? '').toLowerCase();
            if (storedEmail == email.toLowerCase()) {
              AppLogger.info(
                  'fetchUserById: Full scan matched doc ${d.id} for email $email');
              final data = Map<String, dynamic>.from(d.data());
              data['userId'] = userId;
              // Migrate the found document to the correct UID path.
              try {
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .set(data, SetOptions(merge: true));
                if (d.id != userId) {
                  await _firestore.collection('users').doc(d.id).delete();
                }
                AppLogger.info('fetchUserById: Scan-based migration done.');
              } catch (migrErr) {
                AppLogger.warning('fetchUserById: Scan migration failed: $migrErr');
              }
              try {
                return UserModel.fromJson(data);
              } catch (parseErr) {
                AppLogger.error('fetchUserById: scan fromJson failed: $parseErr');
                return null;
              }
            }
          }
          AppLogger.warning(
              'fetchUserById: FULL SCAN found no document matching email=$email '
              '(uid=$userId). User has no Firestore profile.');
        } on FirebaseException catch (fe) {
          AppLogger.error(
              'fetchUserById: full scan failed code=${fe.code} msg=${fe.message}');
        }
      } else {
        AppLogger.warning('User document not found: $userId (no email for fallback)');
      }
      return null;
    } catch (e, st) {
      AppLogger.error('Error fetching user data for $userId: $e\n$st');
      return null;
    }
  }

  /// Save user data to Firestore
  Future<void> saveUser(UserModel user) async {
    if (!_isFirebaseAvailable) return;
    try {
      AppLogger.debug('Saving user data for: ${user.userId}');

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
          try {
            final data = Map<String, dynamic>.from(doc.data()!);
            data['userId'] = data['userId'] ?? doc.id;
            return UserModel.fromJson(data);
          } catch (e) {
            AppLogger.error('userStream: Error parsing user doc ${doc.id}: $e');
            return null;
          }
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
      AppLogger.debug('Updating user role for: $userId to $newRole');

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
      AppLogger.debug('Updating profile for: $userId');
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
      AppLogger.debug('Updating location for user: $userId');
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
            list.add(UserModel.fromJson({...d.data(), 'userId': d.data()['userId'] ?? d.id}));
          } catch (e) {
            AppLogger.debug(
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
            list.add(UserModel.fromJson({...d.data(), 'userId': d.data()['userId'] ?? d.id}));
          } catch (e) {
            AppLogger.debug(
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
            list.add(UserModel.fromJson({...d.data(), 'userId': d.data()['userId'] ?? d.id}));
          } catch (e) {
            AppLogger.debug(
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
            list.add(UserModel.fromJson({...d.data(), 'userId': d.data()['userId'] ?? d.id}));
          } catch (e) {
            AppLogger.debug(
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
            list.add(UserModel.fromJson({...d.data(), 'userId': d.data()['userId'] ?? d.id}));
          } catch (e) {
            AppLogger.debug(
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
          list.add(UserModel.fromJson({...d.data(), 'userId': d.data()['userId'] ?? d.id}));
        } catch (e) {
          AppLogger.debug(
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
          list.add(UserModel.fromJson({...d.data(), 'userId': d.data()['userId'] ?? d.id}));
        } catch (e) {
          AppLogger.debug(
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
