import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/enums/fish_type.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/buyer/buyer_dashboard_screen.dart';
import '../screens/buyer/buyer_fish_search_screen.dart';
import '../screens/buyer/buyer_map_screen.dart';
import '../screens/buyer/buyer_notifications_screen.dart';
import '../screens/buyer/buyer_requests_screen.dart';
import '../screens/buyer/buyer_seller_tracking_screen.dart';
import '../screens/buyer/buyer_wishlist_screen.dart';
import '../screens/street_seller/street_seller_dashboard_screen.dart';
import '../screens/admin/admin_shell_screen.dart';
import '../screens/admin/manage_sellers_screen.dart';
import '../screens/admin/manage_buyers_screen.dart';
import '../screens/admin/admin_user_profile_screen.dart';
import '../screens/admin/admin_all_listings_screen.dart';
import '../screens/admin/admin_transactions_screen.dart';
import '../screens/admin/admin_order_detail_screen.dart';
import '../screens/admin/fish_categories_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/admin_activity_logs_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/common/fish_listings_screen.dart';
import '../screens/street_seller/create_listing_screen.dart';
import '../screens/common/fish_listing_detail_screen.dart';
import '../screens/common/edit_listing_screen.dart';
import '../screens/common/my_listings_screen.dart';
import '../screens/common/my_orders_screen.dart';
import '../screens/common/order_detail_screen.dart';
import '../screens/common/profile_screen.dart';
import '../screens/common/edit_profile_screen.dart';
import '../screens/common/settings_screen.dart';
import '../screens/common/language_selector_screen.dart';
import 'auth_redirect.dart';
import 'route_paths.dart';

// ── Router provider ───────────────────────────────────────────────────────────
//
// `routerProvider` builds the GoRouter inside a Riverpod scope so:
//   • It can `ref.watch(authRefreshProvider)` and feed it to
//     `refreshListenable` — the redirect re-runs on every auth flip,
//     so sign-out / sign-in / account swap land on the right route.
//   • Tests can override `routerInitialLocationProvider` to start
//     the router at any path (instead of `/splash`).
//
// The router instance is stable across theme/locale rebuilds because
// `authRefreshProvider` is a plain Provider<ChangeNotifier> (NOT a
// ChangeNotifierProvider) — its `notifyListeners` does NOT cause
// `routerProvider` to re-emit.
final routerInitialLocationProvider =
    Provider<String>((_) => AppRoutes.splash);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(authRefreshProvider);
  final initial = ref.read(routerInitialLocationProvider);

  return GoRouter(
    initialLocation: initial,
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = mockUser ?? ref.read(currentUserStreamProvider).valueOrNull;
      final hasAuthUser =
          user != null || ref.read(authStateProvider).valueOrNull != null;
      return resolveAuthRedirect(
        user: user,
        hasAuthUser: hasAuthUser,
        location: state.matchedLocation,
      );
    },
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(state.uri.toString()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.splash),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
    routes: _appRoutes,
  );
});

// ── Route table ───────────────────────────────────────────────────────────────
//
// Kept at top level (not inside the provider body) so it is built
// exactly once per process. This is the single place every screen
// gets wired into go_router.
final List<GoRoute> _appRoutes = [
  // ── Auth & Onboarding ────────────────────────────────────────
  GoRoute(
    path: AppRoutes.splash,
    name: AppRouteNames.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: AppRoutes.login,
    name: AppRouteNames.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AppRoutes.register,
    name: AppRouteNames.register,
    builder: (context, state) => const RegisterScreen(),
  ),

  // ── Role-based Dashboards ────────────────────────────────────
  GoRoute(
    path: AppRoutes.dashboardBuyer,
    name: AppRouteNames.dashboardBuyer,
    builder: (context, state) => const BuyerDashboardScreen(),
  ),
  GoRoute(
    path: AppRoutes.dashboardStreetSeller,
    name: AppRouteNames.dashboardStreetSeller,
    builder: (context, state) => const StreetSellerDashboardScreen(),
  ),
  GoRoute(
    path: AppRoutes.dashboardAdmin,
    name: AppRouteNames.dashboardAdmin,
    builder: (context, state) => const AdminShellScreen(),
  ),

  // ── Buyer: Map / Search / Tracking ──────────────────────────
  GoRoute(
    path: AppRoutes.buyerMap,
    name: AppRouteNames.buyerMap,
    builder: (context, state) {
      final initialType = state.uri.queryParameters['fishType'];
      final initialQuery = state.uri.queryParameters['q'];
      final initialSellerId = state.uri.queryParameters['sellerId'];
      return BuyerMapScreen(
        initialFishType: _parseFishTypeParam(initialType),
        initialSearchQuery: initialQuery,
        initialSellerId: initialSellerId,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.buyerSearch,
    name: AppRouteNames.buyerSearch,
    builder: (context, state) {
      final q = state.uri.queryParameters['q'];
      return BuyerFishSearchScreen(initialQuery: q);
    },
  ),
  GoRoute(
    path: AppRoutes.buyerNotifications,
    name: AppRouteNames.buyerNotifications,
    builder: (context, state) => const BuyerNotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutes.buyerWishlist,
    name: AppRouteNames.buyerWishlist,
    builder: (context, state) => const BuyerWishlistScreen(),
  ),
  GoRoute(
    path: AppRoutes.buyerRequests,
    name: AppRouteNames.buyerRequests,
    builder: (context, state) => const BuyerRequestsScreen(),
  ),
  GoRoute(
    path: AppRoutes.buyerSellerTrackingPath,
    name: AppRouteNames.buyerSellerTracking,
    builder: (context, state) => BuyerSellerTrackingScreen(
      sellerId: state.pathParameters['sellerId']!,
    ),
  ),

  // ── Fish Listings ────────────────────────────────────────────
  GoRoute(
    path: AppRoutes.listings,
    name: AppRouteNames.listings,
    builder: (context, state) => const FishListingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.listingsCreate,
    name: AppRouteNames.listingsCreate,
    builder: (context, state) => const CreateListingScreen(),
  ),
  GoRoute(
    path: AppRoutes.listingsMine,
    name: AppRouteNames.listingsMine,
    builder: (context, state) => const MyListingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.listingDetailPath,
    name: AppRouteNames.listingDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return FishListingDetailScreen(listingId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.listingEditPath,
    name: AppRouteNames.listingEdit,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return EditListingScreen(listingId: id);
    },
  ),

  // ── Orders ────────────────────────────────────────────────────
  GoRoute(
    path: AppRoutes.orders,
    name: AppRouteNames.orders,
    builder: (context, state) => const MyOrdersScreen(),
  ),
  GoRoute(
    path: AppRoutes.orderDetailPath,
    name: AppRouteNames.orderDetail,
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return OrderDetailScreen(orderId: id);
    },
  ),

  // ── Profile / Settings ────────────────────────────────────────
  GoRoute(
    path: AppRoutes.profile,
    name: AppRouteNames.profile,
    builder: (context, state) => const ProfileScreen(),
  ),
  GoRoute(
    path: AppRoutes.profileEdit,
    name: AppRouteNames.profileEdit,
    builder: (context, state) => const EditProfileScreen(),
  ),
  GoRoute(
    path: AppRoutes.settings,
    name: AppRouteNames.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.languageSelector,
    name: AppRouteNames.languageSelector,
    builder: (context, state) => const LanguageSelectorScreen(),
  ),

  // ── Admin management screens ─────────────────────────────────
  GoRoute(
    path: AppRoutes.adminSellers,
    name: AppRouteNames.adminSellers,
    builder: (context, state) => const ManageSellersScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminListings,
    name: AppRouteNames.adminListings,
    builder: (context, state) => const AdminAllListingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminTransactions,
    name: AppRouteNames.adminTransactions,
    builder: (context, state) => const AdminTransactionsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminBuyers,
    name: AppRouteNames.adminBuyers,
    builder: (context, state) => const ManageBuyersScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminCategories,
    name: AppRouteNames.adminCategories,
    builder: (context, state) => const FishCategoriesScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminReports,
    name: AppRouteNames.adminReports,
    builder: (context, state) => const AdminReportsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminLogs,
    name: AppRouteNames.adminLogs,
    builder: (context, state) => const AdminActivityLogsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminSettings,
    name: AppRouteNames.adminSettings,
    builder: (context, state) => const AdminSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminUserProfilePath,
    name: AppRouteNames.adminUserProfile,
    builder: (context, state) {
      final id = state.pathParameters['userId']!;
      return AdminUserProfileScreen(userId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.adminOrderDetailPath,
    name: AppRouteNames.adminOrderDetail,
    builder: (context, state) {
      final id = state.pathParameters['orderId']!;
      return AdminOrderDetailScreen(orderId: id);
    },
  ),

  // ── Role-aware notifications ─────────────────────────────────
  // The TopAppBar bell routes admins and street sellers here.
  // `BuyerNotificationsScreen`'s `buyerNotificationControllerProvider`
  // is buyer-scoped, so non-buyers see an empty non-crashing list.
  GoRoute(
    path: AppRoutes.adminNotifications,
    name: AppRouteNames.adminNotifications,
    builder: (context, state) => const BuyerNotificationsScreen(),
  ),
  GoRoute(
    path: AppRoutes.sellerNotifications,
    name: AppRouteNames.sellerNotifications,
    builder: (context, state) => const BuyerNotificationsScreen(),
  ),

  // ── Catch-all ─────────────────────────────────────────────────
  // Any path that doesn't match a registered route bounces here
  // and is redirected to `/login`. Keeps users out of the
  // "Page not found" errorBuilder for typos / stale deep links.
  GoRoute(
    path: AppRoutes.catchAll,
    redirect: (_, __) => AppRoutes.login,
  ),
];

/// Parse the optional `?fishType=` query param on `/buyer/map` into a
/// [FishType] enum. Unknown / missing values return null (UI shows all).
FishType? _parseFishTypeParam(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return FishTypeExtension.fromString(raw);
}