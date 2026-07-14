// Widget test for [BuyerFishSearchScreen].
//
// We override the upstream providers with canned data so the screen
// renders the "no results" empty state for an empty query and a
// single result card for a non-empty one.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:samakifresh_connect/models/fish_listing_model.dart';
import 'package:samakifresh_connect/models/fish_search_result.dart';
import 'package:samakifresh_connect/models/street_seller_model.dart';
import 'package:samakifresh_connect/providers/fish_search_provider.dart';
import 'package:samakifresh_connect/screens/buyer/buyer_fish_search_screen.dart';

FishListingModel _listing({
  required String id,
  String fishType = 'tuna',
}) {
  return FishListingModel(
    listingId: id,
    sellerId: 's1',
    fishType: fishType,
    quantityKg: 4.0,
    pricePerKg: 1500,
    totalPrice: 6000,
    imageUrls: const [],
    status: 'active',
    createdAt: DateTime(2026, 7, 3, 12),
    expiresAt: DateTime(2026, 7, 4, 12),
  );
}

StreetSellerModel _seller({String id = 's1'}) {
  return StreetSellerModel(
    sellerId: id,
    fullName: 'Mama Salma',
    phoneNumber: '+255000000000',
    latitude: -6.20,
    longitude: 39.20,
    isOnline: true,
    isActive: true,
    createdAt: DateTime(2026, 7, 3, 12),
    updatedAt: DateTime(2026, 7, 3, 12),
  );
}

// Typed list of search results — exercises the same shape the
// provider emits.
final _emptyResults = <FishSearchResult>[];

final _oneResult = <FishSearchResult>[
  FishSearchResult(
    fishType: 'tuna',
    displayName: 'Tuna',
    listings: [
      FishListingWithSeller(
        listing: _listing(id: 'l1'),
        seller: _seller(),
        distanceKm: 1.2,
      ),
    ],
  ),
];

Widget _wrap({required List<Override> overrides, String? initialQuery}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: BuyerFishSearchScreen(initialQuery: initialQuery),
    ),
  );
}

/// Replaces the family parameter with a stubbed result. The family
/// uses `String` (the query) as the key.
List<Override> _stubForQuery(String query, List<FishSearchResult> results) {
  return [
    fishSearchProvider(query).overrideWith(
      (ref) => Stream.value(results),
    ),
  ];
}

void main() {
  testWidgets('renders an empty hint when the query is empty',
      (tester) async {
    await tester.pumpWidget(_wrap(
      overrides: _stubForQuery('', _emptyResults),
      initialQuery: '',
    ));
    await tester.pumpAndSettle();

    expect(find.text('Start typing to search'), findsOneWidget);
  });

  testWidgets('renders a result card for a matching query',
      (tester) async {
    await tester.pumpWidget(_wrap(
      overrides: _stubForQuery('tuna', _oneResult),
      initialQuery: 'tuna',
    ));
    await tester.pumpAndSettle();

    // The header shows the fish name and the count.
    expect(find.text('Tuna'), findsOneWidget);
    expect(find.textContaining('1 seller'), findsOneWidget);
    // The seller row shows the seller's full name.
    expect(find.text('Mama Salma'), findsOneWidget);
    // The distance.
    expect(find.text('1.2 km'), findsOneWidget);
  });

  testWidgets('renders the empty hint for "no sellers" matches',
      (tester) async {
    await tester.pumpWidget(_wrap(
      overrides: _stubForQuery('mackerel', _emptyResults),
      initialQuery: 'mackerel',
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('No sellers have "mackerel"'), findsOneWidget);
  });
}