// Hardcoded fallback list of demo sellers.
//
// Used when Firestore is unreachable (network down, project paused,
// emulator cold-start before the seeder ran). The buyer's map must
// always show *something* on first launch — otherwise the user sees
// an empty map and concludes the app is broken.
//
// Mirrors `_demoSellerPlacements` in `services/demo_seeder.dart`. When
// you change one, change the other.

import '../models/enums/fish_type.dart';
import '../models/enums/listing_status.dart';
import '../models/fish_item_model.dart';
import '../models/street_seller_model.dart';

/// Reference timestamp used in the const sellers above. We use a fixed
/// epoch so the const constructors compile cleanly; the real `createdAt`
/// from Firestore will overwrite these on first read.
final DateTime _kFallbackEpoch = DateTime(2026, 7, 3, 12);

StreetSellerModel _seller({
  required String id,
  required String name,
  required String phone,
  required String street,
  required double lat,
  required double lng,
  required String market,
  required String region,
}) {
  return StreetSellerModel(
    sellerId: id,
    fullName: name,
    phoneNumber: phone,
    latitude: lat,
    longitude: lng,
    marketName: market,
    regionName: region,
    streetName: street,
    isActive: true,
    isOnline: false,
    isVerified: true,
    averageRating: 4.5,
    totalRatings: 12,
    totalOrders: 38,
    createdAt: _kFallbackEpoch,
    updatedAt: _kFallbackEpoch,
  );
}

FishItemModel _fish({
  required String sellerId,
  required FishType type,
  required double kg,
  required double price,
  required String description,
  required double lat,
  required double lng,
  required int index,
}) {
  return FishItemModel(
    itemId: 'fallback-$sellerId-$index',
    listingId: 'fallback-listing-$sellerId-$index',
    sellerId: sellerId,
    fishType: type,
    quantityKg: kg,
    pricePerKg: price,
    totalPrice: kg * price,
    imageUrls: const [],
    description: description,
    isBrokerApproved: true,
    status: ListingStatus.active,
    latitude: lat,
    longitude: lng,
    createdAt: _kFallbackEpoch,
    expiresAt: _kFallbackEpoch.add(const Duration(hours: 24)),
  );
}

/// All demo sellers placed across Zanzibar. Coordinates are real —
/// they correspond to actual Stone Town / Nungwi / Paje / Makunduchi
/// landmarks so distance calculations feel right.
List<StreetSellerModel> fallbackSellers() {
  return [
    // ── Stone Town (5 sellers, ~1 km cluster) ───────────────────────────
    _seller(
      id: 'demo-fatma-tuna',
      name: 'Fatma Tuna Specialist',
      phone: '+255770000001',
      street: 'Creek Road',
      lat: -6.1608,
      lng: 39.2040,
      market: 'Stone Town',
      region: 'Mjini Magharibi',
    ),
    _seller(
      id: 'demo-babu-tilapia',
      name: 'Babu Tilapia',
      phone: '+255770000002',
      street: 'Mizingani Road',
      lat: -6.1616,
      lng: 39.2010,
      market: 'Stone Town',
      region: 'Mjini Magharibi',
    ),
    _seller(
      id: 'demo-sara-fish',
      name: 'Sara Mixed Fish',
      phone: '+255770000003',
      street: 'Shangani Street',
      lat: -6.1642,
      lng: 39.2055,
      market: 'Stone Town',
      region: 'Mjini Magharibi',
    ),
    _seller(
      id: 'demo-kwame-market',
      name: 'Kwame Market Stall',
      phone: '+255770000004',
      street: 'Darajani Market',
      lat: -6.1599,
      lng: 39.1999,
      market: 'Stone Town',
      region: 'Mjini Magharibi',
    ),
    _seller(
      id: 'demo-mama-zainab',
      name: 'Mama Zainab',
      phone: '+255770000005',
      street: 'Kenyatta Road',
      lat: -6.1665,
      lng: 39.2025,
      market: 'Stone Town',
      region: 'Mjini Magharibi',
    ),

    // ── Outer islands (6 sellers) ────────────────────────────────────────
    _seller(
      id: 'demo-nungwi-catch',
      name: 'Hassan Nungwi Catch',
      phone: '+255770000006',
      street: 'Nungwi Beach Road',
      lat: -5.7265,
      lng: 39.2967,
      market: 'Nungwi',
      region: 'Kaskazini A',
    ),
    _seller(
      id: 'demo-kendwa-lobster',
      name: 'Salma Kendwa Seafood',
      phone: '+255770000007',
      street: 'Kendwa Rocks Lane',
      lat: -5.7489,
      lng: 39.2833,
      market: 'Kendwa',
      region: 'Kaskazini A',
    ),
    _seller(
      id: 'demo-paje-surf',
      name: 'Yusuf Paje Surfside',
      phone: '+255770000008',
      street: 'Paje Beach Road',
      lat: -6.2675,
      lng: 39.5433,
      market: 'Paje',
      region: 'Kusini',
    ),
    _seller(
      id: 'demo-jambiani-tide',
      name: 'Mama Rehema Jambiani',
      phone: '+255770000009',
      street: 'Jambiani Village Square',
      lat: -6.3147,
      lng: 39.5519,
      market: 'Jambiani',
      region: 'Kusini',
    ),
    _seller(
      id: 'demo-makunduchi-deep',
      name: 'Juma Makunduchi Deep',
      phone: '+255770000010',
      street: 'Makunduchi Main Road',
      lat: -6.3675,
      lng: 39.5567,
      market: 'Makunduchi',
      region: 'Kusini',
    ),
    _seller(
      id: 'demo-pwani-fresh',
      name: 'Asha Pwani Mchangani',
      phone: '+255770000011',
      street: 'Pwani Mchangani Beach',
      lat: -5.8528,
      lng: 39.3667,
      market: 'Pwani Mchangani',
      region: 'Kaskazini A',
    ),
  ];
}

/// Flat list of fallback fish items across all sellers. Each item has
/// a stable `sellerId` so buyers can join on it.
List<FishItemModel> fallbackFish() {
  final list = <FishItemModel>[];

  // Fatma
  list.addAll([
    _fish(
      sellerId: 'demo-fatma-tuna',
      type: FishType.tuna,
      kg: 12,
      price: 14000,
      description: 'Fresh-caught tuna this morning',
      lat: -6.1608,
      lng: 39.2040,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-fatma-tuna',
      type: FishType.mackerel,
      kg: 6,
      price: 8000,
      description: 'Smoked mackerel, ready to cook',
      lat: -6.1608,
      lng: 39.2040,
      index: 1,
    ),
  ]);

  // Babu
  list.addAll([
    _fish(
      sellerId: 'demo-babu-tilapia',
      type: FishType.tilapia,
      kg: 18,
      price: 6500,
      description: 'Whole tilapia, fresh from the lake',
      lat: -6.1616,
      lng: 39.2010,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-babu-tilapia',
      type: FishType.tuna,
      kg: 4,
      price: 15000,
      description: 'Limited tuna stock — first come',
      lat: -6.1616,
      lng: 39.2010,
      index: 1,
    ),
  ]);

  // Sara
  list.addAll([
    _fish(
      sellerId: 'demo-sara-fish',
      type: FishType.sardine,
      kg: 25,
      price: 3000,
      description: 'Bulk sardines — best for frying',
      lat: -6.1642,
      lng: 39.2055,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-sara-fish',
      type: FishType.snapper,
      kg: 8,
      price: 12000,
      description: 'Whole snapper, gutted and iced',
      lat: -6.1642,
      lng: 39.2055,
      index: 1,
    ),
  ]);

  // Kwame
  list.addAll([
    _fish(
      sellerId: 'demo-kwame-market',
      type: FishType.tuna,
      kg: 9,
      price: 13000,
      description: 'Tuna chunks — caught 4 hours ago',
      lat: -6.1599,
      lng: 39.1999,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-kwame-market',
      type: FishType.grouper,
      kg: 5,
      price: 11000,
      description: 'Kambale (grouper), excellent grilling fish',
      lat: -6.1599,
      lng: 39.1999,
      index: 1,
    ),
  ]);

  // Mama Zainab
  list.addAll([
    _fish(
      sellerId: 'demo-mama-zainab',
      type: FishType.snapper,
      kg: 10,
      price: 12500,
      description: 'Snapper fillets, fresh on ice',
      lat: -6.1665,
      lng: 39.2025,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-mama-zainab',
      type: FishType.mackerel,
      kg: 14,
      price: 7500,
      description: 'Whole mackerel, just landed',
      lat: -6.1665,
      lng: 39.2025,
      index: 1,
    ),
  ]);

  // Outer-island sellers
  list.addAll([
    _fish(
      sellerId: 'demo-nungwi-catch',
      type: FishType.grouper,
      kg: 14,
      price: 14000,
      description: 'Kambale kubwa — northern reef catch',
      lat: -5.7265,
      lng: 39.2967,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-nungwi-catch',
      type: FishType.snapper,
      kg: 9,
      price: 15500,
      description: 'Snapper from the north tip of Zanzibar',
      lat: -5.7265,
      lng: 39.2967,
      index: 1,
    ),
  ]);
  list.addAll([
    _fish(
      sellerId: 'demo-kendwa-lobster',
      type: FishType.tuna,
      kg: 18,
      price: 13500,
      description: 'Big-eye tuna, Kendwa deep-water catch',
      lat: -5.7489,
      lng: 39.2833,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-kendwa-lobster',
      type: FishType.snapper,
      kg: 7,
      price: 14500,
      description: 'Red snapper, fresh from Kendwa reef',
      lat: -5.7489,
      lng: 39.2833,
      index: 1,
    ),
  ]);
  list.addAll([
    _fish(
      sellerId: 'demo-paje-surf',
      type: FishType.mackerel,
      kg: 22,
      price: 7000,
      description: 'East-coast mackerel, smoked and fresh',
      lat: -6.2675,
      lng: 39.5433,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-paje-surf',
      type: FishType.sardine,
      kg: 30,
      price: 2800,
      description: 'Sardines from Paje — perfect for frying',
      lat: -6.2675,
      lng: 39.5433,
      index: 1,
    ),
  ]);
  list.addAll([
    _fish(
      sellerId: 'demo-jambiani-tide',
      type: FishType.snapper,
      kg: 11,
      price: 13000,
      description: 'Snapper from Jambiani lagoon',
      lat: -6.3147,
      lng: 39.5519,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-jambiani-tide',
      type: FishType.tilapia,
      kg: 16,
      price: 6000,
      description: 'Tilapia, sweet-water farmed in Jambiani',
      lat: -6.3147,
      lng: 39.5519,
      index: 1,
    ),
  ]);
  list.addAll([
    _fish(
      sellerId: 'demo-makunduchi-deep',
      type: FishType.tuna,
      kg: 25,
      price: 12500,
      description: 'Yellowfin tuna, southern Zanzibar deep catch',
      lat: -6.3675,
      lng: 39.5567,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-makunduchi-deep',
      type: FishType.grouper,
      kg: 8,
      price: 15000,
      description: 'Kambale from the southern reefs',
      lat: -6.3675,
      lng: 39.5567,
      index: 1,
    ),
  ]);
  list.addAll([
    _fish(
      sellerId: 'demo-pwani-fresh',
      type: FishType.tilapia,
      kg: 14,
      price: 6800,
      description: 'Tilapia, fresh from the lagoon',
      lat: -5.8528,
      lng: 39.3667,
      index: 0,
    ),
    _fish(
      sellerId: 'demo-pwani-fresh',
      type: FishType.mackerel,
      kg: 10,
      price: 7800,
      description: 'Mackerel landed at Pwani this morning',
      lat: -5.8528,
      lng: 39.3667,
      index: 1,
    ),
  ]);

  return list;
}