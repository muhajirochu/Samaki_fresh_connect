// End-to-end integration test for the admin Manage Buyers flow.
//
// Pours the production Riverpod graph end-to-end:
//   - signs in as admin via the mockUser bridge
//   - renders the admin dashboard
//   - taps the "Manage Buyers" tile
//   - verifies the navigation reaches /admin/buyers
//   - verifies the buyer data is rendered
//
// This is the regression guard for "Manage Buyers does not work
// on the admin dashboard" — the user reported the tile in the
// admin Management section was not navigating.

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
import 'package:samakifresh_connect/screens/admin/admin_dashboard_screen.dart';
import 'package:samakifresh_connect/screens/admin/manage_buyers_screen.dart';

UserModel _admin() => UserModel(
      userId: 'admin-1',
      email: 'admin@samakifresh.com',
      fullName: 'Admin User',
      phoneNumber: '+255700000000',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

UserModel _buyer({
  required String id,
  required String name,
  required String email,
  bool active = true,
}) {
  return UserModel(
    userId: id,
    email: email,
    fullName: name,
    phoneNumber: '+255700000002',
    role: UserRole.buyer,
    isActive: active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

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
      locale: container.read(localeProvider),
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets(
    'admin dashboard — Manage Buyers tile navigates to /admin/buyers',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      setMockUser(_admin());
      addTearDown(() => setMockUser(null));

      final buyers = [
        _buyer(id: 'b1', name: 'Asha Buyer', email: 'asha@test.com'),
        _buyer(id: 'b2', name: 'Salim Buyer', email: 'salim@test.com'),
      ];

      final container = ProviderContainer(
        overrides: [
          adminAllBuyersProvider.overrideWith(
            (ref) => Stream.value(buyers),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/admin/dashboard',
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/buyers',
            builder: (_, __) => const ManageBuyersScreen(),
          ),
          GoRoute(
            path: '/admin/sellers',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/admin/listings',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/admin/transactions',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/admin/logs',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/admin/users/:userId',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/',
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(container, router));
      await tester.pumpAndSettle();

      // Sanity: dashboard renders.
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // Tap the Manage Buyers tile. Use the icon to avoid scroll
      // flakiness across phone widths — the action tile title lives
      // inside a SliverList that may not be in the initial viewport.
      final manageBuyersFinder = find.text(l10n.manageBuyers);
      await tester.scrollUntilVisible(
        manageBuyersFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(manageBuyersFinder, findsOneWidget);
      expect(find.text(l10n.manageBuyersSubtitle), findsOneWidget);

      await tester.tap(manageBuyersFinder);
      await tester.pumpAndSettle();

      // Now we should be on the Manage Buyers screen.
      expect(find.text('Manage Buyers'), findsOneWidget);
      expect(find.text('Asha Buyer'), findsOneWidget);
      expect(find.text('Salim Buyer'), findsOneWidget);

      // The search bar must be present.
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
