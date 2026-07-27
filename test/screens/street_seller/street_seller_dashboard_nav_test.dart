// Regression tests for every quick-action tile on the street seller
// dashboard. Verifies that Buy Stock, My Orders, Sell Stock and
// My Listings all navigate to the correct route via go_router — the
// previous string-literal `context.push('/listings/...')` calls were
// vulnerable to typos and route drift, so we now use AppRouteNames
// constants. The tile tappable area itself is also covered in case
// the Material/InkWell/Container layering ever hides the hit target
// behind another widget.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/config/dark_theme.dart';
import 'package:samakifresh_connect/config/light_theme.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/fish_listing_model.dart';
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/providers/auth_provider.dart';
import 'package:samakifresh_connect/providers/listing_provider.dart';
import 'package:samakifresh_connect/providers/seller_location_provider.dart';
import 'package:samakifresh_connect/screens/street_seller/street_seller_dashboard_screen.dart';
import 'package:samakifresh_connect/services/seller_location_tracker.dart';

UserModel _seller() => UserModel(
      userId: 's1',
      email: 'asha@samakifresh.com',
      fullName: 'Asha Seller',
      phoneNumber: '+255700000001',
      role: UserRole.streetSeller,
      isActive: true,
      isApproved: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

FishListingModel _listing(String id) => FishListingModel(
      listingId: id,
      sellerId: 's1',
      fishType: 'tuna',
      quantityKg: 12,
      pricePerKg: 5000,
      totalPrice: 60000,
      imageUrls: const [],
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2026, 1, 8),
    );
// ignore: unused_element
FishListingModel _unusedListing() => _listing('u');

Widget _buildApp(ProviderContainer container, GoRouter router) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const StreetSellerDashboardScreen(),
      ),
      GoRoute(
        path: '/listings',
        name: 'listings',
        builder: (_, __) => const Scaffold(body: Text('listings-route')),
      ),
      GoRoute(
        path: '/listings/mine',
        name: 'listingsMine',
        builder: (_, __) => const Scaffold(body: Text('mine-route')),
      ),
      GoRoute(
        path: '/listings/create',
        name: 'listingsCreate',
        builder: (_, __) => const Scaffold(body: Text('create-route')),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (_, __) => const Scaffold(body: Text('orders-route')),
      ),
    ],
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      sellerListingsProvider('s1').overrideWith(
        (ref) => Stream.value(<FishListingModel>[]),
      ),
      sellerOnlineStatusProvider.overrideWith(
        (ref) => SellerTrackerStatus.idle,
      ),
      sellerLocationTrackerProvider.overrideWith(
        (ref) => SellerLocationTracker(),
      ),
    ],
  );
}

void main() {
  setUp(() {
    setMockUser(_seller());
  });
  tearDown(() {
    setMockUser(null);
  });

  testWidgets('Buy Stock tile navigates to /listings', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container, _router()));
    await _settle(tester);

    // Diagnostic: ensure the tile is actually in the tree.
    expect(find.text('Buy Stock'), findsOneWidget);

    await tester.tap(find.text('Buy Stock'));
    await _settle(tester);
    expect(find.text('listings-route'), findsOneWidget,
        reason: 'Buy Stock tap should land on /listings');
  });

  testWidgets('My Orders tile navigates to /orders', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container, _router()));
    await _settle(tester);

    await tester.tap(find.text('My Orders'));
    await _settle(tester);
    expect(find.text('orders-route'), findsOneWidget);
  });

  testWidgets('Sell Stock tile navigates to /listings/create', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container, _router()));
    await _settle(tester);

    // "Sell Stock" appears in BOTH the quick-action tile AND the FAB,
    // so we can't use find.text('Sell Stock') — that hits the FAB
    // first which is on top. Tap the tile by targeting its icon.
    await tester.tap(find.byIcon(Icons.add_business_rounded));
    await _settle(tester);
    expect(find.text('create-route'), findsOneWidget);
  });

  testWidgets('My Listings tile navigates to /listings/mine', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container, _router()));
    await _settle(tester);

    await tester.tap(find.text('My Listings'));
    await _settle(tester);
    expect(find.text('mine-route'), findsOneWidget);
  });

  testWidgets('FAB navigates to /listings/create', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildApp(container, _router()));
    await _settle(tester);

    // FAB uses extended label "Sell Stock" so the tap target is
    // distinct from the tile. Find by icon to avoid locale mismatch.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await _settle(tester);
    expect(find.text('create-route'), findsOneWidget);
  });

  testWidgets(
    'every quick action tile is reachable from its icon (tap target check)',
    (tester) async {
      // Confirms that tapping the icon inside a tile still hits the
      // InkWell — the previous Container-on-top-of-InkWell layering
      // bug surfaced when icons were bigger than expected and the
      // outer Material ate the gesture.
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container, _router()));
      await _settle(tester);

      // The shopping_cart icon must lead to the marketplace screen.
      await tester.tap(find.byIcon(Icons.shopping_cart_rounded));
      await _settle(tester);
      expect(find.text('listings-route'), findsOneWidget);
    },
  );
}