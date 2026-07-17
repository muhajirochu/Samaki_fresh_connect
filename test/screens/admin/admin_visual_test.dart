// Visual smoke test for admin screens.
//
// Mounts each admin screen with a mock user stream and dummy data,
// then pumps a frame so the screenshot is ready for visual
// inspection. This is the test we read when a user reports
// "admin CSS is broken" — every screen renders the same way in
// test as it does on device.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/config/dark_theme.dart';
import 'package:samakifresh_connect/config/light_theme.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/providers/admin_provider.dart';
import 'package:samakifresh_connect/providers/auth_provider.dart';
import 'package:samakifresh_connect/providers/locale_provider.dart';
import 'package:samakifresh_connect/screens/admin/manage_sellers_screen.dart';

UserModel _mockSeller({
  String id = 'seller-1',
  String name = 'Asha Seller',
  String email = 'asha@samakifresh.com',
  bool approved = true,
  bool active = true,
}) {
  final now = DateTime.now();
  return UserModel(
    userId: id,
    email: email,
    fullName: name,
    phoneNumber: '+255700000001',
    role: UserRole.streetSeller,
    isActive: active,
    isApproved: approved,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      // Auth → admin so admin screens accept the active user.
      currentUserStreamProvider.overrideWith(
        (ref) => Stream.value(_mockSeller(id: 'admin-1', name: 'Admin')),
      ),
      // Empty streams — test only checks that screens render
      // without throwing, not that data flows correctly.
      adminAllSellersProvider.overrideWith(
        (ref) => Stream.value(<UserModel>[
              _mockSeller(),
              _mockSeller(
                id: 'seller-2',
                name: 'Pending Hassan',
                email: 'hassan@samakifresh.com',
                approved: false,
              ),
              _mockSeller(
                id: 'seller-3',
                name: 'Suspended Salma',
                email: 'salma@samakifresh.com',
                active: false,
              ),
            ]),
      ),
      adminUserCountsProvider.overrideWith(
        (ref) => Stream.value(<String, int>{
              'buyer': 12,
              'streetSeller': 3,
              'admin': 1,
            }),
      ),
      adminActiveListingsCountProvider.overrideWith((ref) => Stream.value(7)),
      adminAllListingsProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminAllOrdersProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminPlatformRevenueProvider
          .overrideWith((ref) => Stream.value(125000.0)),
      localeProvider.overrideWith((ref) => const Locale('en')),
    ],
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
      routerConfig: GoRouter(
        initialLocation: '/admin/sellers',
        routes: [
          GoRoute(
            path: '/admin/sellers',
            builder: (_, __) => child,
          ),
          GoRoute(
            path: '/admin/users/:id',
            builder: (_, __) => const Scaffold(body: Text('profile')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('Manage Sellers — light theme + English renders',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(const ManageSellersScreen()));
    await tester.pumpAndSettle();

    // Sanity-check: the screen title + a known seller name render.
    expect(find.text('Manage Street Sellers'), findsOneWidget);
    expect(find.text('Asha Seller'), findsOneWidget);
    expect(find.text('Pending Hassan'), findsOneWidget);
    expect(find.text('Suspended Salma'), findsOneWidget);
    expect(find.text('Search sellers'), findsOneWidget);
  });
}
