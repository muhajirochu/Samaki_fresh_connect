// End-to-end smoke test for admin screens across light + dark
// themes and English + Kiswahili locales.
//
// Pumps every admin screen with mocked providers, asserts that
// the expected labels render, and verifies the locale / theme
// switching actually flips what the user sees.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:samakifresh_connect/config/dark_theme.dart';
import 'package:samakifresh_connect/config/light_theme.dart';
import 'package:samakifresh_connect/constants/app_colors.dart';
import 'package:samakifresh_connect/l10n/app_localizations.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/user_model.dart';
import 'package:samakifresh_connect/providers/admin_provider.dart';
import 'package:samakifresh_connect/providers/auth_provider.dart';
import 'package:samakifresh_connect/providers/locale_provider.dart';
import 'package:samakifresh_connect/providers/theme_provider.dart';
import 'package:samakifresh_connect/screens/admin/admin_dashboard_screen.dart';
import 'package:samakifresh_connect/screens/admin/manage_sellers_screen.dart';
import 'package:samakifresh_connect/screens/admin/manage_buyers_screen.dart';

UserModel _adminUser() {
  final now = DateTime.now();
  return UserModel(
    userId: 'admin-1',
    email: 'admin@samakifresh.com',
    fullName: 'Admin User',
    phoneNumber: '+255700000000',
    role: UserRole.admin,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap({
  required Widget child,
  required ThemeData theme,
  required AppThemeMode mode,
  required Locale locale,
  String? path,
}) {
  return ProviderScope(
    overrides: [
      currentUserStreamProvider.overrideWith(
        (ref) => Stream.value(_adminUser()),
      ),
      themeControllerProvider.overrideWith(
        (ref) => ThemeModeNotifier(mode, 'admin-1'),
      ),
      localeProvider.overrideWith((ref) => locale),
      adminUserCountsProvider.overrideWith(
        (ref) => Stream.value(<String, int>{
              'buyer': 12,
              'streetSeller': 3,
              'admin': 1,
            }),
      ),
      adminAllSellersProvider.overrideWith(
        (ref) => Stream.value(<UserModel>[
              UserModel(
                userId: 'seller-1',
                email: 'asha@samakifresh.com',
                fullName: 'Asha Seller',
                phoneNumber: '+255700000001',
                role: UserRole.streetSeller,
                isActive: true,
                isApproved: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ]),
      ),
      adminAllBuyersProvider
          .overrideWith((ref) => Stream.value(const <UserModel>[])),
      adminAllListingsProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminAllOrdersProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminRecentActivityProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminTotalSellersProvider.overrideWith((ref) => Stream.value(3)),
      adminTotalBuyersProvider.overrideWith((ref) => Stream.value(12)),
      adminTotalListingsProvider.overrideWith((ref) => Stream.value(7)),
      adminActiveListingsCountProvider.overrideWith((ref) => Stream.value(5)),
      adminTotalOrdersProvider.overrideWith((ref) => Stream.value(42)),
      adminPendingOrdersProvider.overrideWith((ref) => Stream.value(7)),
      adminCompletedOrdersProvider.overrideWith((ref) => Stream.value(30)),
      adminCancelledOrdersProvider.overrideWith((ref) => Stream.value(5)),
      adminDailyOrdersProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminWeeklyOrdersProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminMonthlyOrdersProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminDailyRevenueProvider.overrideWith((ref) => Stream.value(0.0)),
      adminWeeklyRevenueProvider.overrideWith((ref) => Stream.value(0.0)),
      adminMonthlyRevenueProvider.overrideWith((ref) => Stream.value(0.0)),
      adminPlatformRevenueProvider
          .overrideWith((ref) => Stream.value(125000.0)),
      adminTodaysOrdersProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminAllCategoriesProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminActiveCategoriesProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
    ],
    child: MaterialApp.router(
      theme: theme,
      darkTheme: buildDarkTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: GoRouter(
        initialLocation: path ?? '/',
        routes: [
          GoRoute(
            path: '/',
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

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Widget screen,
  required ThemeData theme,
  required Locale locale,
  AppThemeMode mode = AppThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    _wrap(
      child: screen,
      theme: theme,
      mode: mode,
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Admin dashboard — light theme, English', (tester) async {
    await _pumpScreen(
      tester,
      screen: const AdminDashboardScreen(),
      theme: buildLightTheme(),
      locale: const Locale('en'),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.totalSellers), findsOneWidget);
    expect(find.text(l10n.totalBuyers), findsOneWidget);
    expect(find.text(l10n.totalOrders), findsOneWidget);
    // Scroll down to reach the quick-action list which holds the
    // "Manage Street Sellers" tile.
    await tester.scrollUntilVisible(
      find.text(l10n.manageStreetSellers),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n.manageStreetSellers), findsAtLeastNWidgets(1));
    expect(find.text('Asha Seller'), findsNothing); // dashboard hides
  });

  testWidgets('Admin dashboard — dark theme, Kiswahili', (tester) async {
    await _pumpScreen(
      tester,
      screen: const AdminDashboardScreen(),
      theme: buildDarkTheme(),
      locale: const Locale('sw'),
      mode: AppThemeMode.dark,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('sw'));
    expect(find.text(l10n.totalSellers), findsOneWidget);
    expect(find.text(l10n.totalBuyers), findsOneWidget);
    // The header gradient should render with a primary colour.
    final BuildContext ctx = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });

  testWidgets('Manage Sellers — light + English', (tester) async {
    await _pumpScreen(
      tester,
      screen: const ManageSellersScreen(),
      theme: buildLightTheme(),
      locale: const Locale('en'),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.manageStreetSellers), findsOneWidget);
    expect(find.text('Asha Seller'), findsOneWidget);
    expect(find.text(l10n.searchSellers), findsOneWidget);
  });

  testWidgets('Manage Sellers — light + Kiswahili', (tester) async {
    await _pumpScreen(
      tester,
      screen: const ManageSellersScreen(),
      theme: buildLightTheme(),
      locale: const Locale('sw'),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('sw'));
    expect(find.text(l10n.manageStreetSellers), findsOneWidget);
    expect(find.text('Asha Seller'), findsOneWidget);
    expect(find.text(l10n.searchSellers), findsOneWidget);
  });

  testWidgets('Manage Buyers — empty state', (tester) async {
    await _pumpScreen(
      tester,
      screen: const ManageBuyersScreen(),
      theme: buildLightTheme(),
      locale: const Locale('en'),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.manageBuyers), findsOneWidget);
    // Empty list shows a centred empty state (no search bar).
    expect(find.text('No buyers registered yet'), findsOneWidget);
  });

  testWidgets('Admin dashboard theme switch — flips brightness',
      (tester) async {
    // Start light.
    await _pumpScreen(
      tester,
      screen: const AdminDashboardScreen(),
      theme: buildLightTheme(),
      locale: const Locale('en'),
    );
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light);

    // Now swap to dark by rebuilding the widget tree with a different
    // theme — this mirrors what the global `themeModeProvider`
    // change does in production.
    await tester.pumpWidget(
      _wrap(
        child: const AdminDashboardScreen(),
        theme: buildDarkTheme(),
        locale: const Locale('en'),
        mode: AppThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark);
  });
}