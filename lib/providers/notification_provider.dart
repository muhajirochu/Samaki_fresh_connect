// Notifications + wishlist providers.
//
// ── Session isolation ────────────────────────────────────────────────────────
// All providers here are gated on `currentBuyerSessionProvider`. If the
// auth user is null / not a buyer, every stream returns empty data.
//
// ── Real-time ───────────────────────────────────────────────────────────────
//   - `notificationsProvider` → Firestore snapshot of the user's
//     `notifications` documents, newest first.
//   - `wishlistProvider` → Firestore snapshot of the user's wishlist.
//   - `wishlistMatchEventsProvider` is the cross-stream watcher: when a
//     new fish item appears that matches a wishlist entry whose
//     notification is stale (>6h), we fire a `fish_available_now`
//     notification and a local push.

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/enums/fish_type.dart';
import '../models/enums/notification_type.dart';
import '../models/fish_item_model.dart';
import '../models/wishlist_model.dart';
import '../services/notification_service.dart';
import '../services/wishlist_service.dart';
import 'buyer_provider.dart';

// ── Service singletons ───────────────────────────────────────────────────────
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final wishlistServiceProvider = Provider<WishlistService>(
  (ref) => WishlistService(),
);

// ── Notifications stream ─────────────────────────────────────────────────────

final notificationsProvider = StreamProvider<List<NotificationItem>>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return const Stream.empty();
  final svc = ref.watch(notificationServiceProvider);
  return svc.streamForUser(session.buyerId);
});

final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return Stream.value(0);
  final svc = ref.watch(notificationServiceProvider);
  return svc.unreadCount(session.buyerId);
});

// ── Session-agnostic variants ─────────────────────────────────────────────────
// Mirror the buyer-scoped streams above but keyed on a userId parameter
// instead of `currentBuyerSessionProvider`, so sellers (and any other role)
// also see their notifications. Same shape, same code — just a different
// session gate.

final notificationsForAnyUserProvider =
    StreamProvider.family<List<NotificationItem>, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();
  final svc = ref.watch(notificationServiceProvider);
  return svc.streamForUser(userId);
});

final unreadCountForAnyUserProvider =
    StreamProvider.family<int, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(0);
  final svc = ref.watch(notificationServiceProvider);
  return svc.unreadCount(userId);
});

// ── Wishlist stream ─────────────────────────────────────────────────────────

final wishlistProvider = StreamProvider<List<WishlistEntry>>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return const Stream.empty();
  final svc = ref.watch(wishlistServiceProvider);
  return svc.streamFor(session.buyerId);
});

// ── Cross-stream trigger ────────────────────────────────────────────────────

/// A wishlist entry that just found a matching live listing. Surfaced so
/// the UI can pop a banner / toast.
class WishlistMatch {
  final WishlistEntry entry;
  final FishItemModel item;
  const WishlistMatch({required this.entry, required this.item});
}

/// Cross-references the wishlist against the live fish feed. Whenever a
/// matching listing appears that hasn't been notified on in the last 6h,
/// we fire:
///   1. Cloud `notifications/` doc (visible on the bell icon).
///   2. Local push so the banner shows even when the app is backgrounded.
///   3. Wishlist update marking this listing as notified.
final wishlistMatchEventsProvider = StreamProvider<WishlistMatch?>((ref) {
  final session = ref.watch(currentBuyerSessionProvider);
  if (session == null) return const Stream.empty();

  final controller = StreamController<WishlistMatch?>.broadcast();
  final notifSvc = ref.read(notificationServiceProvider);
  final wishSvc = ref.read(wishlistServiceProvider);

  List<WishlistEntry> wishlist = const [];
  List<FishItemModel> fish = const [];
  bool evaluating = false;

  Future<void> evaluate() async {
    if (evaluating) return;
    evaluating = true;
    try {
      if (wishlist.isEmpty || fish.isEmpty) return;
      final now = DateTime.now();
      for (final w in wishlist) {
        final matches = fish.where((f) =>
            f.isBuyable &&
            f.fishType == w.fishType &&
            (w.maxPricePerKg == null || f.pricePerKg <= w.maxPricePerKg!));
        if (matches.isEmpty) continue;
        final candidate = matches.first;
        if (!w.isStale(now)) continue;
        if (w.lastNotifiedListingId == candidate.listingId) continue;
        await notifSvc.writeNotification(
          userId: session.buyerId,
          title: '${candidate.displayName} available now!',
          body: 'You wanted ${candidate.displayName} — a seller has it.',
          type: NotificationType.fishAvailableNow,
          relatedId: candidate.listingId,
        );
        await notifSvc.showLocal(
          title: '🐟 ${candidate.displayName} available',
          body: 'A nearby seller just listed the fish you wanted.',
          type: NotificationType.fishAvailableNow,
        );
        await wishSvc.markNotified(
          buyerId: session.buyerId,
          entryId: w.id,
          listingId: candidate.listingId,
        );
        controller.add(WishlistMatch(entry: w, item: candidate));
        return; // one per evaluation
      }
    } finally {
      evaluating = false;
    }
  }

  final wishlistSub = ref.listen<AsyncValue<List<WishlistEntry>>>(
    wishlistProvider,
    (_, next) {
      wishlist = next.valueOrNull ?? const [];
      unawaited(evaluate());
    },
    fireImmediately: true,
  );
  final fishSub = ref.listen<AsyncValue<List<FishItemModel>>>(
    buyerFishFeedProvider,
    (_, next) {
      fish = next.valueOrNull ?? const [];
      unawaited(evaluate());
    },
    fireImmediately: true,
  );

  ref.onDispose(() {
    wishlistSub.close();
    fishSub.close();
    controller.close();
  });

  return controller.stream;
});

// ── Write controllers ───────────────────────────────────────────────────────

class BuyerNotificationController extends StateNotifier<int> {
  BuyerNotificationController(this._ref) : super(0);
  final Ref _ref;

  String? _requireSession() => _ref.read(currentBuyerSessionProvider)?.buyerId;

  Future<void> markAsRead(String notificationId) async {
    await _ref.read(notificationServiceProvider).markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    final id = _requireSession();
    if (id == null) return;
    await _ref.read(notificationServiceProvider).markAllAsRead(id);
  }
}

final buyerNotificationControllerProvider =
    StateNotifierProvider<BuyerNotificationController, int>(
  (ref) => BuyerNotificationController(ref),
);

class WishlistController extends StateNotifier<WishlistEntry?> {
  WishlistController(this._ref) : super(null);
  final Ref _ref;

  String? _requireSession() => _ref.read(currentBuyerSessionProvider)?.buyerId;

  Future<void> addFish(FishType type, {double? maxPricePerKg}) async {
    final id = _requireSession();
    if (id == null) return;
    final entry = WishlistEntry(
      id: type.value,
      fishType: type,
      addedAt: DateTime.now(),
      maxPricePerKg: maxPricePerKg,
    );
    await _ref.read(wishlistServiceProvider).add(id, entry);
    state = entry;
  }

  Future<void> remove(FishType type) async {
    final id = _requireSession();
    if (id == null) return;
    await _ref.read(wishlistServiceProvider).remove(id, type.value);
    if (state?.fishType == type) state = null;
  }
}

final wishlistControllerProvider =
    StateNotifierProvider<WishlistController, WishlistEntry?>(
  (ref) => WishlistController(ref),
);
