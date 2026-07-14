import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  static Future<void> seedDemoAccounts() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Map demo email → real Firebase UID. Populated as we sign in to
    // each account so the marketplace seed step can link each seller's
    // user doc to their street-seller mirror doc.
    final emailToUid = <String, String>{};

    for (final demo in demoAccounts) {
      try {
        try {
          final credential = await auth.signInWithEmailAndPassword(
            email: demo.email,
            password: demo.password,
          );
          final uid = credential.user?.uid;
          if (uid != null) emailToUid[demo.email] = uid;
          AppLogger.info('Demo account ${demo.email} already exists.');
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
              emailToUid[demo.email] = uid;
              final now = DateTime.now();
              final userModel = UserModel(
                userId: uid,
                email: demo.email,
                fullName: demo.name,
                phoneNumber: '0700000000',
                role: demo.role,
                isActive: true,
                // Pre-seed buyer-with-location so its dashboard geo
                // search radius isn't empty on first run. Street
                // sellers get the location of their shop so the
                // dashboard renders correctly on first launch.
                location: demo.role == UserRole.streetSeller &&
                        _sellerEmailToId.containsKey(demo.email)
                    ? null // populated below by the marketplace seeder
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
          }
        }
      } catch (e) {
        AppLogger.error('Failed to seed demo account ${demo.email}: $e');
      }
    }

    await auth.signOut();

    // Now seed the demo marketplace — sellers + listings — so the
    // buyer's map has data immediately on first run. This is the
    // critical fix for the "buyer can't find fish the seller just
    // posted" problem; without these docs the buyer's geo query
    // returns nothing.
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
            'isOnline': false,
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
