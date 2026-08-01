import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';
import '../utils/logger.dart';

// Inline geohash helper (precision 7 ~ 153 m cell, Base32 alphabet).
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

class DemoSeeder {
  /// Maps demo seller email → demo seller id used in the
  /// `streetSellers/{docId}` mirror doc. Allows the same email to
  /// resolve to the same seller-mirror doc, so when the seller signs
  /// in and the tracker writes `streetSellers/{uid}` patches, the
  /// buyer's map sees them.
  static const Map<String, String> _sellerEmailToId = {
    // Stone Town
    'fatma@samakifresh.com': 'fatma-tuna',
    'babu@samakifresh.com': 'babu-tilapia',
    'sara@samakifresh.com': 'sara-fish',
    'kwame@samakifresh.com': 'kwame-market',
    'mama@samakifresh.com': 'mama-zainab',
    // Outer islands
    'hassan@samakifresh.com': 'nungwi-catch',
    'salma@samakifresh.com': 'kendwa-lobster',
    'yusuf@samakifresh.com': 'paje-surf',
    'rehema@samakifresh.com': 'jambiani-tide',
    'juma@samakifresh.com': 'makunduchi-deep',
    'asha-pwani@samakifresh.com': 'pwani-fresh',
  };

  /// Hardcoded endpoint of the running Firebase Auth emulator.
  ///
  /// The emulator runs on `10.0.2.2` (the host loopback) on the
  /// Android emulator and `127.0.0.1` on Linux desktop. We use the
  /// emulator's REST API to create demo accounts WITHOUT touching
  /// the Firebase Auth client's `currentUser` — the previous
  /// `createUserWithEmailAndPassword` flow would hijack any
  /// already-signed-in user's session.
  static String get _emulatorAuthHost {
    // Same logic as main.dart's host selection.
    return '10.0.2.2';
  }

  static String get _emulatorAuthUrl =>
      'http://$_emulatorAuthHost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp';

  /// Create a Firebase Auth account via the emulator's REST API
  /// without disturbing the current `auth.currentUser` session.
  /// Returns the new user's UID, or null if the account already
  /// exists or creation failed.
  static Future<String?> _createAuthUserViaRestApi({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse(_emulatorAuthUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data['localId'] as String?;
      } else if (resp.statusCode == 400) {
        // EMAIL_EXISTS, INVALID_EMAIL, WEAK_PASSWORD, etc. — treat
        // as "already exists" so the seeder can move on.
        return null;
      } else {
        AppLogger.warning(
            'Auth emulator returned ${resp.statusCode}: ${resp.body}');
        return null;
      }
    } catch (e) {
      AppLogger.warning('Failed to create auth user via emulator REST: $e');
      return null;
    }
  }

  static Future<void> seedDemoAccounts() async {
    final firestore = FirebaseFirestore.instance;

    // HARD FIX: We use the Auth emulator REST API to create demo
    // accounts (see `_createAuthUserViaRestApi`), so the seeder no
    // longer hijacks an already-signed-in user's session. Note we
    // no longer touch `FirebaseAuth.instance.currentUser` at all.

    // Map demo email → real Firebase UID. Populated as we discover
    // or create each account so the marketplace seed step can link
    // each seller's user doc to their street-seller mirror doc.
    final emailToUid = <String, String>{};


    // Combine the explicit demo accounts (buyer, admin) with all the
    // street sellers defined in our placement map. Previously, the
    // sellers were only seeded into Firestore but never given Firebase
    // Auth accounts, making it impossible to log in as them!
    final Map<String, DemoAccount> allDemosMap = {
      for (final demo in demoAccounts) demo.email: demo,
      for (final email in _sellerEmailToId.keys)
        email: DemoAccount(
          email: email,
          password: 'password123',
          role: UserRole.streetSeller,
          name: email.split('@').first,
          icon: Icons.storefront_rounded,
          color: const Color(0xFFF57C00),
        )
    };
    final allDemos = allDemosMap.values.toList();

    for (final demo in allDemos) {
      try {
        // First, check if a user doc already exists in Firestore for
        // this demo email. This avoids the expensive sign-in round-trip
        // on every cold start and — critically — doesn't destroy the
        // current user's session.
        final existingQuery = await firestore
            .collection('users')
            .where('email', isEqualTo: demo.email)
            .limit(1)
            .get();

        if (existingQuery.docs.isNotEmpty) {
          // Demo user already exists in Firestore — grab their UID
          // for the marketplace seed step.
          final docId = existingQuery.docs.first.id;
          emailToUid[demo.email] = docId;
          AppLogger.info(
              'Demo account ${demo.email} already exists (uid=$docId).');
          continue;
        }

        // Demo user doesn't exist yet — create them.
        try {
          // HARD FIX: use the Auth emulator REST API instead of
          // `auth.createUserWithEmailAndPassword`. The client-side
          // helper would sign the new user in immediately, hijacking
          // any existing session; the REST API leaves auth.currentUser
          // untouched.
          final uid = await _createAuthUserViaRestApi(
            email: demo.email,
            password: demo.password,
          );
          if (uid != null) {
            emailToUid[demo.email] = uid;
            final now = DateTime.now();
            final userModel = UserModel(
              userId: uid,
              email: demo.email,
              fullName: demo.name,
              phoneNumber: '0700000000',
              role: demo.role,
              isActive: true,
              location: demo.role == UserRole.streetSeller &&
                      _sellerEmailToId.containsKey(demo.email)
                  ? null
                  : const {
                      'latitude': -6.1629,
                      'longitude': 39.2026,
                      'marketName': 'Stone Town',
                      'regionName': 'Mjini Magharibi',
                    },
              createdAt: now,
              updatedAt: now,
            );
            final data = userModel.toJson();
            data['createdAt'] = FieldValue.serverTimestamp();
            data['updatedAt'] = FieldValue.serverTimestamp();
            await firestore.collection('users').doc(uid).set(data);
            AppLogger.info(
                'Successfully created demo account: ${demo.email}');
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Auth account exists but Firestore doc was missing —
            // sign in to get the UID so we can create the doc.
            try {
              // Use the REST API to look up the existing Auth UID
              // without touching the current session. We sign up
              // (which will return EMAIL_EXISTS since it already
              // exists) and read the localId from the error… but
              // the emulator doesn't expose that. Fall back to
              // querying Firestore by email — the doc had to have
              // been created on first sign-up, so the UID is the
              // doc id.
              await _createAuthUserViaRestApi(
                email: demo.email,
                password: demo.password,
              );
              final existingByEmail = await firestore
                  .collection('users')
                  .where('email', isEqualTo: demo.email)
                  .limit(1)
                  .get();
              if (existingByEmail.docs.isNotEmpty) {
                final uid = existingByEmail.docs.first.id;
                emailToUid[demo.email] = uid;
                // Create the missing Firestore user doc
                final data = <String, dynamic>{
                  'userId': uid,
                  'email': demo.email,
                  'fullName': demo.name,
                  'phoneNumber': '0700000000',
                  'role': demo.role.name,
                  'isActive': true,
                  'isApproved': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (demo.role != UserRole.streetSeller ||
                    !_sellerEmailToId.containsKey(demo.email)) {
                  data['location'] = const {
                    'latitude': -6.1629,
                    'longitude': 39.2026,
                    'marketName': 'Stone Town',
                    'regionName': 'Mjini Magharibi',
                  };
                }
                await firestore
                    .collection('users')
                    .doc(uid)
                    .set(data, SetOptions(merge: true));
                AppLogger.info(
                    'Created missing Firestore doc for demo: ${demo.email}');
              }
            } catch (signInError) {
              AppLogger.error(
                  'Could not sign in to existing demo ${demo.email}: $signInError');
            }
          } else {
            AppLogger.error(
                'Failed to create demo account ${demo.email}: ${e.code}');
          }
        }
      } catch (e) {
        AppLogger.error('Failed to seed demo account ${demo.email}: $e');
      }
    }

    // No sign-out / restore: the REST API doesn't touch the
    // current session, so nothing to unwind.

    // Now seed the demo marketplace — sellers + listings — so the
    // buyer's map has data immediately on first run.
    await _seedMarketplace(firestore, emailToUid);
  }

  /// Sample sellers placed inside ~5 km of Stone Town so the buyer's
  /// 10-km radius query always finds them. Each seller has a real
  /// `streetSellers/{uid}` mirror doc with `geohash`, plus a few
  /// `fishListings/{auto}` docs with proper `latitude`/`longitude`.
  ///
  /// [emailToUid] is used to link the seller-mirror doc id with the
  /// seller's real Firebase Auth UID so the live tracker (which
  /// writes to `streetSellers/{auth.currentUser.uid}`) actually
  /// updates the doc that the buyer sees.
  static Future<void> _seedMarketplace(
    FirebaseFirestore firestore,
    Map<String, String> emailToUid,
  ) async {
    try {
      const sellers = _demoSellerPlacements;
      for (final s in sellers) {
        // Find this demo seller's email so we can wire up the user
        // doc and the seller-mirror doc by the *real* Firebase Auth
        // UID rather than the demo-* string.
        final sellerEmail = _sellerEmailToId.entries
            .firstWhere(
              (entry) => entry.value == s.id,
              orElse: () => const MapEntry('', ''),
            )
            .key;
        final realUid = sellerEmail.isEmpty ? null : emailToUid[sellerEmail];

        // The mirror doc id:
        //   - Use the real Firebase UID when the seller has signed in
        //     so the live tracker writes to the same doc the buyer reads.
        //   - Fall back to `demo-<id>` for any seller that doesn't
        //     have a matching demo account yet.
        final mirrorDocId = realUid ?? 'demo-${s.id}';
        final sellerDocId = realUid ?? 'demo-${s.id}';

        final geo = _encodeGeohash(s.lat, s.lng);
        final mirrorRef = firestore
            .collection('streetSellers')
            .doc(mirrorDocId);
        await mirrorRef.set(
          {
            'sellerId': sellerDocId,
            'fullName': s.name,
            'phoneNumber': s.phone,
            'profilePictureUrl': null,
            'latitude': s.lat,
            'longitude': s.lng,
            'location': {
              'latitude': s.lat,
              'longitude': s.lng,
              'geohash': geo,
            },
            'geo': GeoPoint(s.lat, s.lng),
            'geohash': geo,
            'marketName': 'Stone Town',
            'regionName': 'Mjini Magharibi',
            'streetName': s.street,
            'isActive': true,
            'isOnline': true,
            'isVerified': true,
            'averageRating': 4.5,
            'totalRatings': 12,
            'totalOrders': 38,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        AppLogger.info(
            'Seeded demo seller ${s.name} (doc=$mirrorDocId, uid=$realUid)');

        // Mirror the location onto the user doc too — the street-
        // seller dashboard reads `user.location` to render its own
        // header. We do this *after* the seller-mirror doc so the
        // write order is obvious in the logs.
        if (realUid != null) {
          await firestore.collection('users').doc(realUid).set({
            'location': {
              'latitude': s.lat,
              'longitude': s.lng,
              'geohash': geo,
              'marketName': 'Stone Town',
              'regionName': 'Mjini Magharibi',
            },
            'latitude': s.lat,
            'longitude': s.lng,
            'geohash': geo,
            'geo': GeoPoint(s.lat, s.lng),
            'locationUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Create a mock users document so they appear in the Admin Dashboard
          await firestore.collection('users').doc(sellerDocId).set({
            'userId': sellerDocId,
            'email': '${s.id}@samakifresh.com',
            'fullName': s.name,
            'phoneNumber': s.phone,
            'role': 'streetSeller',
            'isActive': true,
            'isApproved': true,
            'location': {
              'latitude': s.lat,
              'longitude': s.lng,
              'geohash': geo,
              'marketName': 'Stone Town',
              'regionName': 'Mjini Magharibi',
            },
            'latitude': s.lat,
            'longitude': s.lng,
            'geohash': geo,
            'geo': GeoPoint(s.lat, s.lng),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'locationUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // Each seller carries a small set of fish listings. Demo
        // listings use the *mirror*'s doc id as `sellerId` so the
        // buyer's join-on-FishItemModel.sellerId works correctly out
        // of the box.
        for (final fish in s.fish) {
          final fGeo = _encodeGeohash(s.lat, s.lng);
          await firestore.collection('fishListings').add({
            'listingId': '', // filled by service convention
            'sellerId': sellerDocId,
            'fishType': fish.type,
            'customFishName': '',
            'quantityKg': fish.kg,
            'pricePerKg': fish.price,
            'totalPrice': fish.kg * fish.price,
            'imageUrls': <String>[],
            'description': fish.description,
            // Phase-1 buyer view uses these flags as the only gate.
            'isBrokerApproved': true,
            'dalaliApproved': true,
            'status': 'active',
            'latitude': s.lat,
            'longitude': s.lng,
            'location': {
              'latitude': s.lat,
              'longitude': s.lng,
              'geohash': fGeo,
            },
            'geo': GeoPoint(s.lat, s.lng),
            'geohash': fGeo,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt':
                Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
          });
        }
      }
      AppLogger.info('Demo marketplace seeded (sellers + listings).');
    } catch (e) {
      AppLogger.error('Marketplace seed failed: $e');
    }
  }
}

class _DemoSellerSeed {
  final String id;
  final String name;
  final String phone;
  final String street;
  final double lat;
  final double lng;
  final List<_DemoFish> fish;
  const _DemoSellerSeed({
    required this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.lat,
    required this.lng,
    required this.fish,
  });
}

class _DemoFish {
  final String type;
  final double kg;
  final double price;
  final String description;
  const _DemoFish({
    required this.type,
    required this.kg,
    required this.price,
    required this.description,
  });
}

// Five sellers spread over ~5 km of Stone Town so the buyer's 10-km
// radius query always has neighbours. Tuna is repeated across multiple
// sellers so the "buyer searches Tuna" path is well-exercised.
const List<_DemoSellerSeed> _demoSellerPlacements = [
  _DemoSellerSeed(
    id: 'fatma-tuna',
    name: 'Fatma Tuna Specialist',
    phone: '+255770000001',
    street: 'Creek Road',
    lat: -6.1608,
    lng: 39.2040,
    fish: [
      _DemoFish(
        type: 'tuna',
        kg: 12.0,
        price: 14000,
        description: 'Fresh-caught tuna this morning',
      ),
      _DemoFish(
        type: 'mackerel',
        kg: 6.0,
        price: 8000,
        description: 'Smoked mackerel, ready to cook',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'babu-tilapia',
    name: 'Babu Tilapia',
    phone: '+255770000002',
    street: 'Mizingani Road',
    lat: -6.1616,
    lng: 39.2010,
    fish: [
      _DemoFish(
        type: 'tilapia',
        kg: 18.0,
        price: 6500,
        description: 'Whole tilapia, fresh from the lake',
      ),
      _DemoFish(
        type: 'tuna',
        kg: 4.0,
        price: 15000,
        description: 'Limited tuna stock — first come',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'sara-fish',
    name: 'Sara Mixed Fish',
    phone: '+255770000003',
    street: 'Shangani Street',
    lat: -6.1642,
    lng: 39.2055,
    fish: [
      _DemoFish(
        type: 'sardine',
        kg: 25.0,
        price: 3000,
        description: 'Bulk sardines — best for frying',
      ),
      _DemoFish(
        type: 'snapper',
        kg: 8.0,
        price: 12000,
        description: 'Whole snapper, gutted and iced',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'kwame-market',
    name: 'Kwame Market Stall',
    phone: '+255770000004',
    street: 'Darajani Market',
    lat: -6.1599,
    lng: 39.1999,
    fish: [
      _DemoFish(
        type: 'tuna',
        kg: 9.0,
        price: 13000,
        description: 'Tuna chunks — caught 4 hours ago',
      ),
      _DemoFish(
        type: 'grouper',
        kg: 5.0,
        price: 11000,
        description: 'Kambale (grouper), excellent grilling fish',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'mama-zainab',
    name: 'Mama Zainab',
    phone: '+255770000005',
    street: 'Kenyatta Road',
    lat: -6.1665,
    lng: 39.2025,
    fish: [
      _DemoFish(
        type: 'snapper',
        kg: 10.0,
        price: 12500,
        description: 'Snapper fillets, fresh on ice',
      ),
      _DemoFish(
        type: 'mackerel',
        kg: 14.0,
        price: 7500,
        description: 'Whole mackerel, just landed',
      ),
    ],
  ),

  // ── Outer-island sellers (further from Stone Town) ─────────────────────────
  // These give the buyer a real distance gradient: ~37 km (Paje),
  // ~40 km (Jambiani), ~45 km (Makunduchi), ~50 km (Nungwi/Kendwa).
  // Each one stocks a different mix so the dashboard's "Fish Available"
  // count is high and the buyer's nearest-seller tile shows real
  // distance comparisons.
  _DemoSellerSeed(
    id: 'nungwi-catch',
    name: 'Hassan Nungwi Catch',
    phone: '+255770000006',
    street: 'Nungwi Beach Road',
    lat: -5.7265,
    lng: 39.2967,
    fish: [
      _DemoFish(
        type: 'grouper',
        kg: 14.0,
        price: 14000,
        description: 'Kambale kubwa — northern reef catch',
      ),
      _DemoFish(
        type: 'snapper',
        kg: 9.0,
        price: 15500,
        description: 'Snapper from the north tip of Zanzibar',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'kendwa-lobster',
    name: 'Salma Kendwa Seafood',
    phone: '+255770000007',
    street: 'Kendwa Rocks Lane',
    lat: -5.7489,
    lng: 39.2833,
    fish: [
      _DemoFish(
        type: 'tuna',
        kg: 18.0,
        price: 13500,
        description: 'Big-eye tuna, Kendwa deep-water catch',
      ),
      _DemoFish(
        type: 'snapper',
        kg: 7.0,
        price: 14500,
        description: 'Red snapper, fresh from Kendwa reef',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'paje-surf',
    name: 'Yusuf Paje Surfside',
    phone: '+255770000008',
    street: 'Paje Beach Road',
    lat: -6.2675,
    lng: 39.5433,
    fish: [
      _DemoFish(
        type: 'mackerel',
        kg: 22.0,
        price: 7000,
        description: 'East-coast mackerel, smoked and fresh',
      ),
      _DemoFish(
        type: 'sardine',
        kg: 30.0,
        price: 2800,
        description: 'Sardines from Paje — perfect for frying',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'jambiani-tide',
    name: 'Mama Rehema Jambiani',
    phone: '+255770000009',
    street: 'Jambiani Village Square',
    lat: -6.3147,
    lng: 39.5519,
    fish: [
      _DemoFish(
        type: 'snapper',
        kg: 11.0,
        price: 13000,
        description: 'Snapper from Jambiani lagoon',
      ),
      _DemoFish(
        type: 'tilapia',
        kg: 16.0,
        price: 6000,
        description: 'Tilapia, sweet-water farmed in Jambiani',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'makunduchi-deep',
    name: 'Juma Makunduchi Deep',
    phone: '+255770000010',
    street: 'Makunduchi Main Road',
    lat: -6.3675,
    lng: 39.5567,
    fish: [
      _DemoFish(
        type: 'tuna',
        kg: 25.0,
        price: 12500,
        description: 'Yellowfin tuna, southern Zanzibar deep catch',
      ),
      _DemoFish(
        type: 'grouper',
        kg: 8.0,
        price: 15000,
        description: 'Kambale from the southern reefs',
      ),
    ],
  ),
  _DemoSellerSeed(
    id: 'pwani-fresh',
    name: 'Asha Pwani Mchangani',
    phone: '+255770000011',
    street: 'Pwani Mchangani Beach',
    lat: -5.8528,
    lng: 39.3667,
    fish: [
      _DemoFish(
        type: 'tilapia',
        kg: 14.0,
        price: 6800,
        description: 'Tilapia, fresh from the lagoon',
      ),
      _DemoFish(
        type: 'mackerel',
        kg: 10.0,
        price: 7800,
        description: 'Mackerel landed at Pwani this morning',
      ),
    ],
  ),
];
