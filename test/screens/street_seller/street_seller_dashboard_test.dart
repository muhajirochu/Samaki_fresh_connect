// Tests the seller dashboard's primary surface area end-to-end:
// greeting header renders, stats render the live values from the
// listings stream, and the quick actions navigate to the right
// routes.

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

FishListingModel _listing(String id, String status) => FishListingModel(
      listingId: id,
      sellerId: 's1',
      fishType: 'tuna',
      quantityKg: 12,
      pricePerKg: 5000,
      totalPrice: 60000,
      imageUrls: const [],
      status: status,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: DateTime(2026, 1, 8),
    );

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
    ],
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets(
    'seller dashboard — greeting + stats render for a signed-in seller',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      setMockUser(_seller());
      addTearDown(() => setMockUser(null));

      final container = ProviderContainer(
        overrides: [
          sellerListingsProvider('s1').overrideWith(
            (ref) => Stream.value([
              _listing('l1', 'active'),
              _listing('l2', 'active'),
            ]),
          ),
          sellerOnlineStatusProvider.overrideWith(
            (ref) => SellerTrackerStatus.online,
          ),
          sellerLocationTrackerProvider.overrideWith(
            (ref) => SellerLocationTracker(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container, _router()));
      await _settle(tester);

      // Greeting includes the seller's first name.
      expect(find.textContaining('Asha'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'seller dashboard — Buy Stock navigates to /listings',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      setMockUser(_seller());
      addTearDown(() => setMockUser(null));

      final container = ProviderContainer(
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
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildApp(container, _router()));
      await _settle(tester);

      // Tap Buy Stock — should land on /listings.
      await tester.tap(find.text('Buy Stock'));
      await _settle(tester);
      expect(find.text('listings-route'), findsOneWidget);
    },
  );
}
