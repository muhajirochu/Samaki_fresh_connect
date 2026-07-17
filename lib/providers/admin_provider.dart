// Admin providers — single source of truth for the admin dashboard
// stats, moderation lists, and supporting streams (categories,
// activity logs, sales-by-period).
//
// Every stream here is consumed by either the dashboard tiles or a
// dedicated admin screen (Manage Sellers / Buyers, Fish
// Categories, All Listings, Transactions, Reports, Activity Logs,
// Admin Settings). All counts update live because the underlying
// Firestore queries use `.snapshots()`.

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/activity_log_model.dart';
import '../models/fish_category_model.dart';
import '../models/fish_listing_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/activity_log_service.dart';
import '../services/email_sms_service.dart';
import '../services/fish_category_service.dart';
import '../services/fish_listing_service.dart';
import '../services/order_service.dart';
import '../services/user_service.dart';
import 'auth_provider.dart';
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

final adminCategoryServiceProvider = Provider<FishCategoryService>(
  (ref) => FishCategoryService(),
);

final adminActivityLogServiceProvider = Provider<ActivityLogService>(
  (ref) => ActivityLogService(),
);

/// Convenience: the current signed-in admin's uid, or null if the
/// active user is not an admin. Lets audit-trail writes stamp the
/// actor field without screens having to do the role check twice.
final adminCurrentUidProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final role = user?.role.name;
  if (role == 'admin') return user?.userId;
  return null;
});

// ── Dashboard stat providers (11 tiles) ──────────────────────────

final adminUserCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final service = ref.watch(adminUserServiceProvider);
  return service.streamUserCountsByRole();
});

/// Convenience: total users = sum of all roles. Drives the "Total
/// Users" tile.
final adminTotalUsersProvider = StreamProvider<int>((ref) {
  return ref.watch(adminUserCountsProvider).when(
        data: (counts) {
          final total = counts.values.fold<int>(0, (a, b) => a + b);
          return Stream.value(total);
        },
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

final adminTotalSellersProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminUserServiceProvider);
  return service.streamUserCountByRole('streetSeller');
});

final adminTotalBuyersProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminUserServiceProvider);
  return service.streamUserCountByRole('buyer');
});

final adminTotalListingsProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminListingServiceProvider);
  return service.streamTotalListingsCount();
});

final adminActiveListingsCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminListingServiceProvider);
  return service.streamActiveListingsCount();
});

final adminTotalOrdersProvider = StreamProvider<int>((ref) {
  return ref.watch(adminAllOrdersProvider).when(
        data: (orders) => Stream.value(orders.length),
        loading: () => Stream.value(0),
        error: (_, __) => Stream.value(0),
      );
});

final adminPendingOrdersProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  return service.streamOrdersCountByStatus('pending');
});

final adminCompletedOrdersProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  return service.streamOrdersCountByStatus('completed');
});

final adminCancelledOrdersProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  return service.streamOrdersCountByStatus('cancelled');
});

final adminTodaysOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  return service.streamTodaysOrders();
});

// ── Sales-by-period providers ────────────────────────────────────

/// All orders placed today — backs the dashboard's Daily Sales tile
/// AND the Reports screen's "today" bucket.
final adminDailyOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(adminTodaysOrdersProvider).when(
        data: (orders) => Stream.value(orders),
        loading: () => Stream.value(<OrderModel>[]),
        error: (_, __) => Stream.value(<OrderModel>[]),
      );
});

/// Orders in the current calendar week (Mon → today).
final adminWeeklyOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  return service.streamOrdersInRange(monday, now.add(const Duration(days: 1)));
});

/// Orders in the current calendar month (1st → today).
final adminMonthlyOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  return service.streamOrdersInRange(firstOfMonth, now.add(const Duration(days: 1)));
});

/// Daily / weekly / monthly revenue — `finalPrice * quantityKg`
/// across delivered orders only. Matches the platform-revenue
/// derivation in [adminPlatformRevenueProvider].
final adminDailyRevenueProvider = StreamProvider<double>((ref) {
  return ref.watch(adminDailyOrdersProvider).when(
        data: (orders) {
          final delivered =
              orders.where((o) => o.orderStatus == 'delivered').toList();
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

final adminWeeklyRevenueProvider = StreamProvider<double>((ref) {
  return ref.watch(adminWeeklyOrdersProvider).when(
        data: (orders) {
          final delivered =
              orders.where((o) => o.orderStatus == 'delivered').toList();
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

final adminMonthlyRevenueProvider = StreamProvider<double>((ref) {
  return ref.watch(adminMonthlyOrdersProvider).when(
        data: (orders) {
          final delivered =
              orders.where((o) => o.orderStatus == 'delivered').toList();
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

// ── Admin lists ───────────────────────────────────────────────────

final adminAllOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final service = ref.watch(adminOrderServiceProvider);
  return service.streamAllOrders();
});

final adminAllUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(adminUserServiceProvider);
  return service.streamAllUsers();
});

final adminAllSellersProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(adminUserServiceProvider);
  return service.streamAllSellersFull();
});

final adminAllBuyersProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(adminUserServiceProvider);
  return service.streamAllBuyers();
});

final adminAllListingsProvider = StreamProvider<List<FishListingModel>>((ref) {
  final service = ref.watch(adminListingServiceProvider);
  return service.streamAllListings();
});

// ── Categories ────────────────────────────────────────────────────

final adminAllCategoriesProvider = StreamProvider<List<FishCategoryModel>>(
  (ref) {
    final service = ref.watch(adminCategoryServiceProvider);
    return service.streamAllCategories();
  },
);

final adminActiveCategoriesProvider = StreamProvider<List<FishCategoryModel>>(
  (ref) {
    final service = ref.watch(adminCategoryServiceProvider);
    return service.streamActiveCategories();
  },
);

// ── Activity logs ─────────────────────────────────────────────────

final adminRecentActivityProvider = StreamProvider<List<ActivityLogModel>>(
  (ref) {
    final service = ref.watch(adminActivityLogServiceProvider);
    return service.streamRecent(limit: 25);
  },
);

// ── Aggregates ────────────────────────────────────────────────────

/// Live platform revenue — sum of `finalPrice * quantityKg` across
/// every delivered order. Returns 0.0 when the underlying order
/// stream is still loading or no delivered orders exist yet.
final adminPlatformRevenueProvider = StreamProvider<double>((ref) {
  return ref.watch(adminAllOrdersProvider).when(
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

// ── Mutation controllers ──────────────────────────────────────────

/// Approve / revoke a seller. Caller must already be admin.
Future<void> adminApproveSeller(WidgetRef ref, String sellerId) async {
  final adminUid = ref.read(adminCurrentUidProvider);
  if (adminUid == null) return;
  final userService = ref.read(adminUserServiceProvider);
  final logService = ref.read(adminActivityLogServiceProvider);
  await userService.approveSeller(sellerId, adminUid);
  ref.invalidate(adminAllSellersProvider);
  ref.invalidate(adminAllUsersProvider);
  ref.invalidate(adminUserCountsProvider);
  await logService.write(
    type: 'adminAction',
    actorUid: adminUid,
    actorRole: 'admin',
    targetType: 'user',
    targetId: sellerId,
    title: 'Approved seller',
    subtitle: 'Seller $sellerId was approved.',
  );
}

Future<void> adminRevokeSellerApproval(WidgetRef ref, String sellerId) async {
  final adminUid = ref.read(adminCurrentUidProvider);
  if (adminUid == null) return;
  final userService = ref.read(adminUserServiceProvider);
  final logService = ref.read(adminActivityLogServiceProvider);
  await userService.revokeSellerApproval(sellerId, adminUid);
  ref.invalidate(adminAllSellersProvider);
  ref.invalidate(adminAllUsersProvider);
  await logService.write(
    type: 'adminAction',
    actorUid: adminUid,
    actorRole: 'admin',
    targetType: 'user',
    targetId: sellerId,
    title: 'Revoked seller approval',
    subtitle: 'Seller $sellerId approval was revoked.',
  );
}

Future<void> adminSuspendUser(
  WidgetRef ref,
  String userId, {
  String? reason,
}) async {
  final adminUid = ref.read(adminCurrentUidProvider);
  if (adminUid == null) return;
  final userService = ref.read(adminUserServiceProvider);
  final logService = ref.read(adminActivityLogServiceProvider);
  await userService.suspendUser(userId, adminUid);
  ref.invalidate(adminAllUsersProvider);
  ref.invalidate(adminAllSellersProvider);
  ref.invalidate(adminAllBuyersProvider);
  ref.invalidate(adminUserCountsProvider);
  await logService.write(
    type: 'adminAction',
    actorUid: adminUid,
    actorRole: 'admin',
    targetType: 'user',
    targetId: userId,
    title: 'Suspended user',
    subtitle: reason != null && reason.isNotEmpty
        ? 'Reason: $reason'
        : 'User $userId was suspended.',
    metadata: reason != null && reason.isNotEmpty
        ? <String, dynamic>{'reason': reason}
        : null,
  );
}

Future<void> adminReactivateUser(WidgetRef ref, String userId) async {
  final adminUid = ref.read(adminCurrentUidProvider);
  if (adminUid == null) return;
  final userService = ref.read(adminUserServiceProvider);
  final logService = ref.read(adminActivityLogServiceProvider);
  await userService.reactivateUser(userId, adminUid);
  ref.invalidate(adminAllUsersProvider);
  ref.invalidate(adminAllSellersProvider);
  ref.invalidate(adminAllBuyersProvider);
  ref.invalidate(adminUserCountsProvider);
  await logService.write(
    type: 'adminAction',
    actorUid: adminUid,
    actorRole: 'admin',
    targetType: 'user',
    targetId: userId,
    title: 'Reactivated user',
    subtitle: 'User $userId was reactivated.',
  );
}
