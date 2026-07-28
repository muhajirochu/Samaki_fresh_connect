// Pure unit tests for `resolveAuthRedirect` — the auth redirect
// resolver in `lib/config/auth_redirect.dart`. Zero Riverpod / widget
// dependencies, so the test is a plain function-by-function table of
// (state → expected redirect).
//
// These tests are the regression guard for the
// "logout navigates to Page not found" bug:
//   * every protected route, when visited signed-out, lands on /login;
//   * every auth route, when visited signed-in, lands on the user's
//     role dashboard (no longer silently demoted to buyer);
//   * /splash is exempt from redirect in either direction;
//   * unknown URLs are bounced by the router's catch-all (not by
//     this function — this function returns null for unknown paths
//     because the router has no user/hasAuthUser context for them).

import 'package:flutter_test/flutter_test.dart';

import 'package:samakifresh_connect/config/auth_redirect.dart';
import 'package:samakifresh_connect/config/route_paths.dart';
import 'package:samakifresh_connect/models/enums/user_role.dart';
import 'package:samakifresh_connect/models/user_model.dart';

UserModel _user(UserRole role) => UserModel(
      userId: 'u-${role.name}',
      email: '${role.name}@example.com',
      fullName: '${role.name} User',
      phoneNumber: '+255700000000',
      role: role,
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('signed-out users', () {
    test('any protected route is bounced to /login', () {
      // The single "signed out + not auth route" rule covers every
      // protected prefix in one shot — no per-prefix list to maintain.
      final protectedLocations = <String>[
        AppRoutes.dashboardBuyer,
        AppRoutes.dashboardStreetSeller,
        AppRoutes.dashboardAdmin,
        AppRoutes.buyerMap,
        AppRoutes.buyerSearch,
        AppRoutes.buyerNotifications,
        AppRoutes.buyerWishlist,
        AppRoutes.buyerRequests,
        AppRoutes.buyerSellerTracking('abc'),
        AppRoutes.listings,
        AppRoutes.listingsCreate,
        AppRoutes.listingsMine,
        AppRoutes.listingDetail('xyz'),
        AppRoutes.listingEdit('xyz'),
        AppRoutes.orders,
        AppRoutes.orderDetail('order-1'),
        AppRoutes.profile,
        AppRoutes.profileEdit,
        AppRoutes.settings,
        AppRoutes.languageSelector,
        AppRoutes.adminSellers,
        AppRoutes.adminListings,
        AppRoutes.adminTransactions,
        AppRoutes.adminBuyers,
        AppRoutes.adminCategories,
        AppRoutes.adminReports,
        AppRoutes.adminLogs,
        AppRoutes.adminSettings,
        AppRoutes.adminUserProfile('u-9'),
        AppRoutes.adminOrderDetail('o-3'),
        AppRoutes.adminNotifications,
        AppRoutes.sellerNotifications,
      ];
      for (final loc in protectedLocations) {
        final result = resolveAuthRedirect(
          user: null,
          hasAuthUser: false,
          location: loc,
        );
        expect(
          result,
          AppRoutes.login,
          reason: 'signed-out visit to $loc must redirect to /login',
        );
      }
    });

    test('auth routes are not redirected', () {
      for (final loc in [AppRoutes.login, AppRoutes.register]) {
        expect(
          resolveAuthRedirect(user: null, hasAuthUser: false, location: loc),
          isNull,
          reason: 'signed-out visit to $loc must stay put',
        );
      }
    });
  });

  group('signed-in users', () {
    test('buyer on /login is sent to /dashboard/buyer', () {
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.buyer),
          hasAuthUser: true,
          location: AppRoutes.login,
        ),
        AppRoutes.dashboardBuyer,
      );
    });

    test('streetSeller on /login is sent to /dashboard/street_seller', () {
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.streetSeller),
          hasAuthUser: true,
          location: AppRoutes.login,
        ),
        AppRoutes.dashboardStreetSeller,
      );
    });

    test('admin on /login is sent to /dashboard/admin', () {
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.admin),
          hasAuthUser: true,
          location: AppRoutes.login,
        ),
        AppRoutes.dashboardAdmin,
      );
    });

    test('non-admin on /admin/* is bounced to their own dashboard', () {
      // Buyer trying to visit any admin path lands on the buyer
      // dashboard (NOT on /admin/* and NOT on the buyer dashboard
      // because of the admin guard).
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.buyer),
          hasAuthUser: true,
          location: AppRoutes.adminSellers,
        ),
        AppRoutes.dashboardBuyer,
      );
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.streetSeller),
          hasAuthUser: true,
          location: AppRoutes.adminListings,
        ),
        AppRoutes.dashboardStreetSeller,
      );
    });

    test('admin on /admin/* is allowed through (no redirect)', () {
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.admin),
          hasAuthUser: true,
          location: AppRoutes.adminSellers,
        ),
        isNull,
      );
    });

    test('logged-in user on a regular route is not redirected', () {
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.buyer),
          hasAuthUser: true,
          location: AppRoutes.profile,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.streetSeller),
          hasAuthUser: true,
          location: AppRoutes.listingsCreate,
        ),
        isNull,
      );
    });
  });

  group('edge cases', () {
    test('/splash is exempt in both directions', () {
      expect(
        resolveAuthRedirect(
          user: null,
          hasAuthUser: false,
          location: AppRoutes.splash,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          user: _user(UserRole.buyer),
          hasAuthUser: true,
          location: AppRoutes.splash,
        ),
        isNull,
      );
    });

    test('hasAuthUser with no user doc returns null (wait for the stream)',
        () {
      // Auth says signed-in but the user doc hasn't loaded yet
      // (e.g. between Firebase signIn() and Firestore saveUser()).
      // Stay put — the AuthRefreshNotifier will re-run the redirect
      // once the stream emits. Today this returned dashboardBuyer,
      // silently demoting admins / sellers on cold start.
      expect(
        resolveAuthRedirect(
          user: null,
          hasAuthUser: true,
          location: AppRoutes.login,
        ),
        isNull,
      );
    });
  });
}