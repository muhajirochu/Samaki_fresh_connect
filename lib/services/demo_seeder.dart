// Demo seeder — used in development to bootstrap two helper accounts
// (a buyer and an admin) so a developer can sign in immediately
// without going through the registration flow.
//
// Street-seller demo accounts and the demo marketplace were
// intentionally removed: real street sellers must register themselves
// through the app's registration flow so the marketplace grows from
// real sign-ups, not seeded fixtures.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class DemoSeeder {
  /// Creates the dev-only `buyer@samakifresh.com` and
  /// `admin@samakifresh.com` accounts if they don't already exist.
  /// Idempotent — safe to call on every cold start.
  static Future<void> seedDemoAccounts() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    for (final demo in demoAccounts) {
      try {
        try {
          final credential = await auth.signInWithEmailAndPassword(
            email: demo.email,
            password: demo.password,
          );
          final uid = credential.user?.uid;
          AppLogger.info('Demo account ${demo.email} already exists.');
          // Make sure the user doc is up to date with the role + display
          // name even if the account was created in an earlier app
          // version that didn't seed these fields.
          if (uid != null) {
            await _ensureUserDoc(firestore, uid, demo);
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' ||
              e.code == 'invalid-credential' ||
              e.code == 'wrong-password') {
            final userCredential =
                await auth.createUserWithEmailAndPassword(
              email: demo.email,
              password: demo.password,
            );
            final uid = userCredential.user?.uid;
            if (uid != null) {
              await _ensureUserDoc(firestore, uid, demo);
              AppLogger.info(
                  'Successfully created demo account: ${demo.email}');
            }
          }
        }
      } catch (e) {
        AppLogger.error('Failed to seed demo account ${demo.email}: $e');
      }
    }

    await auth.signOut();
  }

  /// Writes the `users/{uid}` doc with role, display name, and a
  /// default Stone Town location (only the buyer gets a location —
  /// the admin has no map presence).
  static Future<void> _ensureUserDoc(
    FirebaseFirestore firestore,
    String uid,
    DemoSeed demo,
  ) async {
    final now = DateTime.now();
    final userModel = UserModel(
      userId: uid,
      email: demo.email,
      fullName: demo.name,
      phoneNumber: '0700000000',
      role: demo.role,
      isActive: true,
      location: demo.role == UserRole.buyer
          ? const {
              'latitude': -6.1629,
              'longitude': 39.2026,
              'marketName': 'Stone Town',
              'regionName': 'Mjini Magharibi',
            }
          : null,
      createdAt: now,
      updatedAt: now,
    );
    final data = userModel.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await firestore.collection('users').doc(uid).set(data);
  }
}

/// Dev-only seed record. Street-seller seeds were removed; new
/// street sellers sign up through the registration screen.
class DemoSeed {
  final String email;
  final String password;
  final UserRole role;
  final String name;
  const DemoSeed({
    required this.email,
    required this.password,
    required this.role,
    required this.name,
  });
}

/// Dev-only accounts seeded on cold start. Mirrors the public list in
/// `lib/screens/auth/login_screen.dart`.
const List<DemoSeed> demoAccounts = [
  DemoSeed(
    email: 'buyer@samakifresh.com',
    password: 'password123',
    role: UserRole.buyer,
    name: 'Fatma Buyer',
  ),
  DemoSeed(
    email: 'admin@samakifresh.com',
    password: 'password123',
    role: UserRole.admin,
    name: 'Admin User',
  ),
];