/// Centralized route paths and names for the Samaki Fresh Connect app.
///
/// Every screen navigation should reference one of these constants
/// instead of typing the path string inline. Two helpers —
/// [AppRoutes] (template strings) and [AppRouteNames] (typed route
/// names) — keep the rest of the codebase go_router-only and prevent
/// typos in the rare places where the path needs to be interpolated.
///
/// [AppRoutesExtensions.dashboardFor] is the single source of truth
/// for the `UserRole → dashboard path` mapping, used by the auth
/// redirect, the splash, and every sign-in surface.
library;

import '../models/enums/user_role.dart';

class AppRoutes {
  const AppRoutes._();

  // ── Auth ────────────────────────────────────────────────────────
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  // ── Dashboards ──────────────────────────────────────────────────
  static const dashboardBuyer = '/dashboard/buyer';
  static const dashboardStreetSeller = '/dashboard/street_seller';
  static const dashboardAdmin = '/dashboard/admin';

  // ── Buyer ───────────────────────────────────────────────────────
  static const buyerMap = '/buyer/map';
  static const buyerSearch = '/buyer/search';
  static const buyerNotifications = '/buyer/notifications';
  static const buyerWishlist = '/buyer/wishlist';
  static const buyerRequests = '/buyer/requests';
  static const buyerCart = '/buyer/cart';
  static const buyerSellerTrackingPath = '/buyer/seller/:sellerId';
  static String buyerSellerTracking(String sellerId) =>
      '/buyer/seller/$sellerId';

  // ── Listings ────────────────────────────────────────────────────
  static const listings = '/listings';
  static const listingsCreate = '/listings/create';
  static const listingsMine = '/listings/mine';
  static const listingDetailPath = '/listings/:id';
  static const listingEditPath = '/listings/:id/edit';
  static String listingDetail(String id) => '/listings/$id';
  static String listingEdit(String id) => '/listings/$id/edit';

  // ── Orders ──────────────────────────────────────────────────────
  static const orders = '/orders';
  static const orderDetailPath = '/orders/:id';
  static String orderDetail(String id) => '/orders/$id';

  // ── Profile / Settings ──────────────────────────────────────────
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const settings = '/settings';
  static const languageSelector = '/settings/language';

  // ── Admin ───────────────────────────────────────────────────────
  static const adminSellers = '/admin/sellers';
  static const adminListings = '/admin/listings';
  static const adminTransactions = '/admin/transactions';
  static const adminBuyers = '/admin/buyers';
  static const adminCategories = '/admin/categories';
  static const adminReports = '/admin/reports';
  static const adminLogs = '/admin/logs';
  static const adminSettings = '/admin/settings';
  static const adminUserProfilePath = '/admin/users/:userId';
  static const adminOrderDetailPath = '/admin/orders/:orderId';
  static String adminUserProfile(String userId) => '/admin/users/$userId';
  static String adminOrderDetail(String orderId) => '/admin/orders/$orderId';

  // ── Notifications (role-aware) ─────────────────────────────────────
  // The TopAppBar's notifications bell already routes admins and
  // street sellers to `/admin/notifications` and
  // `/seller/notifications` respectively. Both paths have a real
  // GoRoute below so tapping the bell no longer falls into the
  // "Page not found" errorBuilder.
  static const adminNotifications = '/admin/notifications';
  static const sellerNotifications = '/seller/notifications';
  static const sellerContacts = '/seller/contacts';

  // ── Catch-all for unknown URLs ────────────────────────────────────────
  // Any path that doesn't match a registered route bounces here and
  // is redirected to `/login`. Keeps users out of the "Page not
  // found" errorBuilder.
  static const catchAll = '/:pathMatch(.*)';
}

/// Pure role → dashboard-path mapping. Used by the auth redirect,
/// splash, login and register screens so the mapping exists in
/// exactly one place.
extension AppRoutesExtensions on AppRoutes {
  static String dashboardFor(UserRole role) {
    switch (role) {
      case UserRole.buyer:
        return AppRoutes.dashboardBuyer;
      case UserRole.streetSeller:
        return AppRoutes.dashboardStreetSeller;
      case UserRole.admin:
        return AppRoutes.dashboardAdmin;
    }
  }
}

/// Route *names* used with `context.goNamed(...)` /
/// `context.pushNamed(...)`. Using names instead of paths keeps the
/// code decoupled from the URL shape — rename a path in
/// [AppRoutes] and every caller still resolves the right screen.
class AppRouteNames {
  const AppRouteNames._();

  // ── Auth ────────────────────────────────────────────────────────
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';

  // ── Dashboards ──────────────────────────────────────────────────
  static const dashboardBuyer = 'dashboardBuyer';
  static const dashboardStreetSeller = 'dashboardStreetSeller';
  static const dashboardAdmin = 'dashboardAdmin';

  // ── Buyer ───────────────────────────────────────────────────────
  static const buyerMap = 'buyerMap';
  static const buyerSearch = 'buyerSearch';
  static const buyerNotifications = 'buyerNotifications';
  static const buyerWishlist = 'buyerWishlist';
  static const buyerRequests = 'buyerRequests';
  static const buyerCart = 'buyerCart';
  static const buyerSellerTracking = 'buyerSellerTracking';

  // ── Listings ────────────────────────────────────────────────────
  static const listings = 'listings';
  static const listingsCreate = 'listingsCreate';
  static const listingsMine = 'listingsMine';
  static const listingDetail = 'listingDetail';
  static const listingEdit = 'listingEdit';

  // ── Orders ──────────────────────────────────────────────────────
  static const orders = 'orders';
  static const orderDetail = 'orderDetail';

  // ── Profile / Settings ──────────────────────────────────────────
  static const profile = 'profile';
  static const profileEdit = 'profileEdit';
  static const settings = 'settings';
  static const languageSelector = 'languageSelector';

  // ── Admin ───────────────────────────────────────────────────────
  static const adminSellers = 'adminSellers';
  static const adminListings = 'adminListings';
  static const adminTransactions = 'adminTransactions';
  static const adminBuyers = 'adminBuyers';
  static const adminCategories = 'adminCategories';
  static const adminReports = 'adminReports';
  static const adminLogs = 'adminLogs';
  static const adminSettings = 'adminSettings';
  static const adminUserProfile = 'adminUserProfile';
  static const adminOrderDetail = 'adminOrderDetail';

  // Notifications
  static const adminNotifications = 'adminNotifications';
  static const sellerNotifications = 'sellerNotifications';
  static const sellerContacts = 'sellerContacts';
}
