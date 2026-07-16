// Admin providers — single source of truth for the admin dashboard
// stats and moderation lists.
//
// Every stream here is consumed by either the dashboard tiles or a
// dedicated admin screen (Manage Street Sellers, All Listings,
// Transactions). All counts update live because the underlying
// Firestore queries use `.snapshots()` so the admin never has to
// pull-to-refresh to see fresh data.

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/fish_listing_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/email_sms_service.dart';
import '../services/fish_listing_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import 'listing_provider.dart';
import 'order_provider.dart';

// ── Service providers ─────────────────────────────────────────────
final emailSmsServiceProvider = Provider<EmailSmsService>((ref) {
  return EmailSmsService();
});

final adminUserServiceProvider = Provider<UserService>((ref) => UserService());

final adminListingServiceProvider = Provider<FishListingService>(
  (ref) => ref.watch(fishListingServiceProvider),
);

final adminOrderServiceProvider = Provider<OrderService>(
  (ref) => ref.watch(orderServiceProvider),
);

// ── Live dashboard counters ────────────────────────────────────────

/// Live count of users grouped by role — drives the "Total Users"
/// stat tile on the admin dashboard.
final adminUserCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final service = ref.watch(adminUserServiceProvider);
  return service.streamUserCountsByRole();
});

/// Live count of currently-active listings — drives the "Active
/// Listings" stat tile.
final adminActiveListingsCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminListingServiceProvider);
  return service.streamActiveListingsCount();
});

/// Live list of orders created today — drives the "Orders Today"
/// stat tile. The list is rendered as a count, but exposing the
/// list makes it trivial to drill through to a detail screen later.
final adminTodaysOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  return service.streamTodaysOrders();
});

/// Live list of every order in the system — drives the admin
/// Transactions screen. Newest first so the latest activity is
/// always at the top.
final adminAllOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  return service.streamAllOrders();
});

// ── Admin lists ────────────────────────────────────────────────────

/// Live list of every user in the system — drives the Manage Street
/// Sellers screen. The screen filters client-side by `role` so the
/// same stream powers a future "All Users" view.
final adminAllUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(adminUserServiceProvider);
  return service.streamAllUsers();
});

/// Live list of every listing in the system — drives the admin
/// All Listings moderation screen. Includes sold, expired and
/// inactive listings so the admin can review the full catalogue.
final adminAllListingsProvider = StreamProvider<List<FishListingModel>>((ref) {
  final service = ref.watch(adminListingServiceProvider);
  return service.streamAllListings();
});

// ── Aggregates ─────────────────────────────────────────────────────

/// Live platform revenue — sum of `finalPrice * quantityKg` across
/// every delivered order. Delivered orders are the only ones that
/// count as platform revenue; pending/cancelled orders are excluded.
///
/// Returns 0.0 when the underlying order stream is still loading
/// or when no delivered orders exist yet.
final adminPlatformRevenueProvider = StreamProvider<double>((ref) {
  return ref
      .watch(adminAllOrdersProvider)
      .when(
        data: (orders) {
          final delivered =
              orders.where((o) => o.orderStatus == 'delivered').toList();
          if (delivered.isEmpty) return Stream.value(0.0);
          return Stream.value(
            delivered.fold<double>(
              0,
              (acc, o) => acc + (o.finalPrice * o.quantityKg),
            ),
          );
        },
        loading: () => Stream.value(0.0),
        error: (_, __) => Stream.value(0.0),
      );
});