// Widget test for [BuyerFishSearchScreen].
//
// We override the upstream `fishSearchProvider` (now a singleton
// instead of a family`) plus the upstream streams it listens to, so
// the screen renders deterministically. Localisation delegates are
// injected so the screen can resolve strings via
// `AppLocalizations.of(context)`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/fish_listing_model.dart';
import 'package:samakifresh_connect/models/fish_search_result.dart';
import 'package:samakifresh_connect/models/street_seller_model.dart';
import 'package:samakifresh_connect/providers/fish_search_provider.dart';
import 'package:samakifresh_connect/providers/listing_provider.dart';
import 'package:samakifresh_connect/providers/seller_location_provider.dart';
import 'package:samakifresh_connect/screens/buyer/buyer_fish_search_screen.dart';
import 'package:samakifresh_connect/services/location_service.dart';

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
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 24)),
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

const _fallbackLocation = BuyerLocation(
  latitude: -6.20,
  longitude: 39.20,
  source: 'profile',
);

Widget _wrap({
  required List<Override> overrides,
  String? initialQuery,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BuyerFishSearchScreen(initialQuery: initialQuery),
    ),
  );
}

void main() {
  testWidgets('renders an empty hint when the query is empty',
      (tester) async {
    await tester.pumpWidget(_wrap(
      overrides: [
        activeListingsProvider.overrideWith((ref) => Stream.value([])),
        activeStreetSellersProviderRemote
            .overrideWith((ref) => Stream.value([])),
        currentBuyerLocationProvider.overrideWith((ref) async => _fallbackLocation),
      ],
    ));
    // Seed the (empty) query.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Start typing to search'), findsOneWidget);
  });

  testWidgets('renders a result card for a matching query',
      (tester) async {
    final results = <FishSearchResult>[
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

    await tester.pumpWidget(_wrap(
      overrides: [
        activeListingsProvider
            .overrideWith((ref) => Stream.value([_listing(id: 'l1')])),
        activeStreetSellersProviderRemote
            .overrideWith((ref) => Stream.value([_seller()])),
        currentBuyerLocationProvider
            .overrideWith((ref) async => _fallbackLocation),
        fishSearchProvider.overrideWith((ref) => Stream.value(results)),
      ],
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
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(_wrap(
      overrides: [
        activeListingsProvider.overrideWith((ref) => Stream.value([])),
        activeStreetSellersProviderRemote
            .overrideWith((ref) => Stream.value([])),
        currentBuyerLocationProvider
            .overrideWith((ref) async => _fallbackLocation),
        fishSearchProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      initialQuery: 'mackerel',
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining(l10n.noSellersHave('mackerel')),
        findsOneWidget);
  });
}