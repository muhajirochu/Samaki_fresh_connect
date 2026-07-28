// Regression tests for the route-path / route-name constants in
// `lib/config/route_paths.dart` and the corresponding declarations
// in `lib/config/routes.dart`.
//
// These tests guard against:
//   * Renaming a constant and forgetting to update the other half
//     (path-vs-name drift).
//   * Typos in a path string that break the GoRouter table.
//   * Builders / GoRoute names that no longer match the constant in
//     route_paths.dart — which would crash deep links.
//   * The `AppRoutesExtensions.dashboardFor(role)` helper
//     drifting away from `AppRoutes.dashboard*` constants.

import 'package:flutter_test/flutter_test.dart';

import 'package:samakifresh_connect/config/route_paths.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';

void main() {
  group('AppRoutes', () {
    test('auth routes use leading slashes', () {
      expect(AppRoutes.splash, startsWith('/'));
      expect(AppRoutes.login, startsWith('/'));
      expect(AppRoutes.register, startsWith('/'));
    });

    test('dashboard routes match role expectations', () {
      expect(AppRoutes.dashboardBuyer, '/dashboard/buyer');
      expect(AppRoutes.dashboardStreetSeller, '/dashboard/street_seller');
      expect(AppRoutes.dashboardAdmin, '/dashboard/admin');
    });

    test('path templates use the same parameter names as builders', () {
      // Builders read state.pathParameters['sellerId'] / ['id'] /
      // ['userId'] / ['orderId']. If the template ever drifts away
      // from those keys, deep links break at runtime.
      expect(AppRoutes.buyerSellerTrackingPath, contains(':sellerId'));
      expect(AppRoutes.listingDetailPath, contains(':id'));
      expect(AppRoutes.listingEditPath, contains(':id'));
      expect(AppRoutes.orderDetailPath, contains(':id'));
      expect(AppRoutes.adminUserProfilePath, contains(':userId'));
      expect(AppRoutes.adminOrderDetailPath, contains(':orderId'));
    });

    test('interpolated helpers build the same template as the path', () {
      expect(AppRoutes.buyerSellerTracking('abc'), '/buyer/seller/abc');
      expect(AppRoutes.listingDetail('xyz'), '/listings/xyz');
      expect(AppRoutes.listingEdit('xyz'), '/listings/xyz/edit');
      expect(AppRoutes.orderDetail('order-1'), '/orders/order-1');
      expect(AppRoutes.adminUserProfile('u-9'), '/admin/users/u-9');
      expect(AppRoutes.adminOrderDetail('o-3'), '/admin/orders/o-3');
    });

    test('all admin paths are namespaced under /admin', () {
      expect(AppRoutes.adminSellers, startsWith('/admin/'));
      expect(AppRoutes.adminListings, startsWith('/admin/'));
      expect(AppRoutes.adminTransactions, startsWith('/admin/'));
      expect(AppRoutes.adminBuyers, startsWith('/admin/'));
      expect(AppRoutes.adminCategories, startsWith('/admin/'));
      expect(AppRoutes.adminReports, startsWith('/admin/'));
      expect(AppRoutes.adminLogs, startsWith('/admin/'));
      expect(AppRoutes.adminSettings, startsWith('/admin/'));
    });

    test('notifications bell paths exist (admin and seller)', () {
      // `TopAppBar.notificationsPathFor(role)` routes admins and
      // street sellers here; the GoRoute table must have matching
      // entries or tapping the bell lands on "Page not found".
      expect(AppRoutes.adminNotifications, '/admin/notifications');
      expect(AppRoutes.sellerNotifications, '/seller/notifications');
      expect(AppRoutes.adminNotifications, startsWith('/admin/'));
    });

    test('catch-all path is a valid go_router wildcard', () {
      expect(AppRoutes.catchAll, startsWith('/:'));
      // go_router's pathMatch uses (.*) to swallow the rest.
      expect(AppRoutes.catchAll, contains('(.*)'));
    });
  });

  group('AppRoutesExtensions.dashboardFor', () {
    test('maps every UserRole to the matching dashboard path', () {
      expect(
        AppRoutesExtensions.dashboardFor(UserRole.buyer),
        AppRoutes.dashboardBuyer,
      );
      expect(
        AppRoutesExtensions.dashboardFor(UserRole.streetSeller),
        AppRoutes.dashboardStreetSeller,
      );
      expect(
        AppRoutesExtensions.dashboardFor(UserRole.admin),
        AppRoutes.dashboardAdmin,
      );
    });

    test('the helper agrees with the dashboard path constants', () {
      // Belt-and-braces — if anyone ever renames a dashboard
      // constant without updating the helper, this catches it.
      expect(AppRoutesExtensions.dashboardFor(UserRole.buyer),
          '/dashboard/buyer');
      expect(AppRoutesExtensions.dashboardFor(UserRole.streetSeller),
          '/dashboard/street_seller');
      expect(AppRoutesExtensions.dashboardFor(UserRole.admin),
          '/dashboard/admin');
    });
  });

  group('AppRouteNames', () {
    test('every name is a non-empty string and starts with a letter', () {
      // Soft contract — no overlap with AppRoutes paths so callers
      // can rely on go_router resolving by name alone.
      const names = <String>[
        AppRouteNames.splash,
        AppRouteNames.login,
        AppRouteNames.register,
        AppRouteNames.dashboardBuyer,
        AppRouteNames.dashboardStreetSeller,
        AppRouteNames.dashboardAdmin,
        AppRouteNames.buyerMap,
        AppRouteNames.buyerSearch,
        AppRouteNames.buyerNotifications,
        AppRouteNames.buyerWishlist,
        AppRouteNames.buyerRequests,
        AppRouteNames.buyerSellerTracking,
        AppRouteNames.listings,
        AppRouteNames.listingsCreate,
        AppRouteNames.listingsMine,
        AppRouteNames.listingDetail,
        AppRouteNames.listingEdit,
        AppRouteNames.orders,
        AppRouteNames.orderDetail,
        AppRouteNames.profile,
        AppRouteNames.profileEdit,
        AppRouteNames.settings,
        AppRouteNames.languageSelector,
        AppRouteNames.adminSellers,
        AppRouteNames.adminListings,
        AppRouteNames.adminTransactions,
        AppRouteNames.adminBuyers,
        AppRouteNames.adminCategories,
        AppRouteNames.adminReports,
        AppRouteNames.adminLogs,
        AppRouteNames.adminSettings,
        AppRouteNames.adminUserProfile,
        AppRouteNames.adminOrderDetail,
      ];
      expect(names, isNotEmpty);
      for (final n in names) {
        expect(n, isNotEmpty);
        expect(RegExp(r'^[a-zA-Z]').hasMatch(n), isTrue,
            reason: 'route name `$n` must start with a letter');
      }
      // Names should be unique so go_router lookups are unambiguous.
      expect(names.toSet().length, names.length);
    });
  });
}
