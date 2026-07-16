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
import '../screens/buyer/buyer_wishlist_screen.dart';
import '../screens/street_seller/street_seller_dashboard_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_sellers_screen.dart';
import '../screens/admin/admin_all_listings_screen.dart';
import '../screens/admin/admin_transactions_screen.dart';
import '../screens/common/fish_listings_screen.dart';
import '../screens/fisherman/create_listing_screen.dart';
import '../screens/common/fish_listing_detail_screen.dart';
import '../screens/common/edit_listing_screen.dart';
import '../screens/common/my_listings_screen.dart';
import '../screens/common/my_orders_screen.dart';
import '../screens/common/order_detail_screen.dart';
import '../screens/common/profile_screen.dart';
import '../screens/common/edit_profile_screen.dart';
import '../screens/common/settings_screen.dart';
import '../features/map/screens/map_screen.dart';

// GoRouter requires a listenable to re-evaluate redirect on auth change.
// We use a ProviderContainer to read providers outside widget tree.
final _container = ProviderContainer();

final appRouter = GoRouter(
  initialLocation: '/splash',
  // BUG-11 fix: auth guard redirect
  redirect: (context, state) {
    final authState = _container.read(authStateProvider);
    final isLoggedIn = authState.valueOrNull != null || mockUser != null;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/splash';

    // If not logged in and trying to access protected route → login
    if (!isLoggedIn && !isAuthRoute) return '/login';

    // If logged in and trying to access auth route → redirect to appropriate dashboard
    if (isLoggedIn && isAuthRoute) {
       final userModel = mockUser ?? _container.read(currentUserStreamProvider).valueOrNull;
       
       if (userModel != null) {
          switch (userModel.role.name) {
            case 'streetSeller': return '/dashboard/street_seller';
            case 'admin': return '/dashboard/admin';
            default: return '/dashboard/buyer';
          }
       }
       // If the user hasn't fully loaded, we stay on the splash screen
       if (state.matchedLocation == '/splash') return null;
       return '/dashboard/buyer'; // Fallback if data hasn't loaded yet
    }

    return null;
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
              onPressed: () => context.go('/splash'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  },
  routes: [
    // ── Auth & Onboarding ─────────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // ── Role-based Dashboards ─────────────────────────────────────────────────
    GoRoute(
      path: '/dashboard/buyer',
      builder: (context, state) => const BuyerDashboardScreen(),
    ),

    // ── Buyer: Map / OSM routing (Phase 2) ───────────────────────────────
    GoRoute(
      path: '/buyer/map',
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
      path: '/buyer/search',
      builder: (context, state) {
        final q = state.uri.queryParameters['q'];
        return BuyerFishSearchScreen(initialQuery: q);
      },
    ),
    GoRoute(
      path: '/map-foundation',
      builder: (context, state) => const MapScreen(),
    ),

    // ── Buyer: Notifications + Wishlist (Phase 4) ────────────────────
    GoRoute(
      path: '/buyer/notifications',
      builder: (context, state) => const BuyerNotificationsScreen(),
    ),
    GoRoute(
      path: '/buyer/wishlist',
      builder: (context, state) => const BuyerWishlistScreen(),
    ),
    GoRoute(
      path: '/buyer/requests',
      builder: (context, state) => const BuyerRequestsScreen(),
    ),
    GoRoute(
      path: '/dashboard/street_seller',
      builder: (context, state) => const StreetSellerDashboardScreen(),
    ),
    GoRoute(
      path: '/dashboard/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),

    // ── Admin management screens ────────────────────────────────────
    GoRoute(
      path: '/admin/sellers',
      builder: (context, state) => const ManageSellersScreen(),
    ),
    GoRoute(
      path: '/admin/listings',
      builder: (context, state) => const AdminAllListingsScreen(),
    ),
    GoRoute(
      path: '/admin/transactions',
      builder: (context, state) => const AdminTransactionsScreen(),
    ),

    // ── Fish Listings ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/listings',
      builder: (context, state) => const FishListingsScreen(),
    ),
    GoRoute(
      path: '/listings/create',
      builder: (context, state) => const CreateListingScreen(),
    ),
    GoRoute(
      path: '/listings/mine',
      builder: (context, state) => const MyListingsScreen(),
    ),
    GoRoute(
      path: '/listings/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FishListingDetailScreen(listingId: id);
      },
    ),
    GoRoute(
      path: '/listings/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditListingScreen(listingId: id);
      },
    ),

    // ── Orders ────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/orders',
      builder: (context, state) => const MyOrdersScreen(),
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrderDetailScreen(orderId: id);
      },
    ),

    // ── Profile ───────────────────────────────────────────────────────────────
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),

    // ── Settings (theme switcher etc.) ───────────────────────────────────────
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

/// Parse the optional `?fishType=` query param on `/buyer/map` into a
/// [FishType] enum. Unknown / missing values return null (UI shows all).
FishType? _parseFishTypeParam(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return FishTypeExtension.fromString(raw);
}
