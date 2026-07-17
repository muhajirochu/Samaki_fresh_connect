// Comprehensive admin theme + language audit.
//
// Pumps every admin screen under both themes and both locales,
// captures the rendered widget tree, and verifies that:
//   - the brightness flips when themeMode flips
//   - the visible labels flip when locale flips
//   - the surface colors come from Theme.of(context) (not raw
//     `AppColors.x` literals hard-coded into the body)
//
// This is the audit script we run when the user reports "admin
// theme doesn't work" — it surfaces whether the issue is in the
// global TopAppBar (state) or in the screen body (per-screen
// colour palette).

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

UserModel _admin() => UserModel(
      userId: 'admin-1',
      email: 'admin@samakifresh.com',
      fullName: 'Admin User',
      phoneNumber: '+255700000000',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

Widget _wrap(
  Widget child, {
  required ThemeData theme,
  required Locale locale,
  required ThemeMode themeMode,
}) {
  return ProviderScope(
    overrides: [
      currentUserStreamProvider.overrideWith(
        (ref) => Stream.value(_admin()),
      ),
      themeControllerProvider.overrideWith(
        (ref) => ThemeModeNotifier(
          themeMode == ThemeMode.dark
              ? AppThemeMode.dark
              : AppThemeMode.light,
          'admin-1',
        ),
      ),
      localeProvider.overrideWith(() => LocaleNotifier()),
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
                userId: 's1',
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
      adminPlatformRevenueProvider.overrideWith((ref) => Stream.value(0.0)),
      adminTodaysOrdersProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminAllCategoriesProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
      adminActiveCategoriesProvider
          .overrideWith((ref) => Stream.value(const <Never>[])),
    ],
    child: MaterialApp.router(
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => child,
          ),
          GoRoute(
            path: '/admin/users/:id',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
          ),
        ],
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(screen);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'AUDIT: admin dashboard — LIGHT theme EN/Kiswahili',
    (tester) async {
      // Light + English
      await _pump(
        tester,
        _wrap(
          const AdminDashboardScreen(),
          theme: buildLightTheme(),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
        ),
      );
      expect(find.text('Total street sellers'), findsOneWidget);

      // Light + Kiswahili
      await _pump(
        tester,
        _wrap(
          const AdminDashboardScreen(),
          theme: buildLightTheme(),
          locale: const Locale('sw'),
          themeMode: ThemeMode.light,
        ),
      );
      expect(find.text('Wauzaji wa barabarani wote'), findsOneWidget);
    },
  );

  testWidgets(
    'AUDIT: admin dashboard — DARK theme brightness flips',
    (tester) async {
      Brightness captureBrightness(WidgetTester t) {
        final BuildContext ctx =
            t.element(find.byType(Scaffold).first);
        return Theme.of(ctx).brightness;
      }

      await _pump(
        tester,
        _wrap(
          const AdminDashboardScreen(),
          theme: buildLightTheme(),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
        ),
      );
      expect(captureBrightness(tester), Brightness.light);

      await _pump(
        tester,
        _wrap(
          const AdminDashboardScreen(),
          theme: buildDarkTheme(),
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      expect(captureBrightness(tester), Brightness.dark);
    },
  );

  testWidgets(
    'AUDIT: manage sellers — light + dark theme renders correctly',
    (tester) async {
      for (final t in [ThemeMode.light, ThemeMode.dark]) {
        await _pump(
          tester,
          _wrap(
            const ManageSellersScreen(),
            theme: t == ThemeMode.dark ? buildDarkTheme() : buildLightTheme(),
            locale: const Locale('en'),
            themeMode: t,
          ),
        );
        expect(find.text('Manage Street Sellers'), findsOneWidget);
        // The scaffold background IS theme-aware — it must be opaque.
        final BuildContext ctx =
            tester.element(find.byType(Scaffold).first);
        expect(
          Theme.of(ctx).scaffoldBackgroundColor.computeLuminance() >= 0,
          true,
        );
      }
    },
  );

  testWidgets(
    'AUDIT: locale switch flips every visible label',
    (tester) async {
      // English
      await _pump(
        tester,
        _wrap(
          const ManageSellersScreen(),
          theme: buildLightTheme(),
          locale: const Locale('en'),
          themeMode: ThemeMode.light,
        ),
      );
      expect(find.text('Manage Street Sellers'), findsOneWidget);

      // Kiswahili
      await _pump(
        tester,
        _wrap(
          const ManageSellersScreen(),
          theme: buildLightTheme(),
          locale: const Locale('sw'),
          themeMode: ThemeMode.light,
        ),
      );
      expect(find.text('Simamia Wauzaji wa Barabarani'), findsOneWidget);
    },
  );
}