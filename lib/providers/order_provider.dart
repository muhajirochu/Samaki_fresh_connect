import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../utils/logger.dart';

// ── Service provider ──────────────────────────────────────────────────────────
final orderServiceProvider = Provider<OrderService>(
  (ref) => OrderService(),
);

// ── Orders by buyer ───────────────────────────────────────────────────────────
final buyerOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, buyerId) {
  final service = ref.watch(orderServiceProvider);
  return service.streamOrdersByBuyer(buyerId);
});

// ── Orders by street seller ───────────────────────────────────────────────────
final streetSellerOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, sellerId) {
  final service = ref.watch(orderServiceProvider);
  return service.streamOrdersByStreetSeller(sellerId);
});

/// All orders the user participates in — as buyer OR as seller.
///
/// Street sellers buy stock from other sellers (and vice versa), so a
/// single-role split hides orders they actually own. Use this
/// provider anywhere the user expects to see their full transaction
/// history.
final ordersForUserProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  final service = ref.watch(orderServiceProvider);
  // Fetch the two streams independently and merge. Each child
  // .map(...) tolerates a single malformed doc (logged + skipped)
  // so one bad row can't black-hole the whole screen.
  final buyer = service.streamOrdersByBuyer(userId);
  final seller = service.streamOrdersByStreetSeller(userId);

  // Re-emit whenever either child emits. Combining the two lists
  // and de-duplicating by orderId keeps the UI stable as the two
  // snapshots land at different times.
  StreamController<List<OrderModel>>? controller;
  List<OrderModel>? lastBuyer;
  List<OrderModel>? lastSeller;

  void emit() {
    final b = lastBuyer;
    final s = lastSeller;
    if (b == null || s == null) return;
    final byId = <String, OrderModel>{};
    for (final o in b) {
      byId[o.orderId] = o;
    }
    for (final o in s) {
      byId[o.orderId] = o;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final c = controller;
    if (c != null && !c.isClosed) c.add(merged);
  }

  controller = StreamController<List<OrderModel>>.broadcast(
    onListen: () {
      buyer.listen((data) {
        lastBuyer = data;
        emit();
      }, onError: (Object e, StackTrace s) {
        AppLogger.warning('ordersForUser: buyer stream error: $e');
      });
      seller.listen((data) {
        lastSeller = data;
        emit();
      }, onError: (Object e, StackTrace s) {
        AppLogger.warning('ordersForUser: seller stream error: $e');
      });
    },
  );
  ref.onDispose(() => controller?.close());
  return controller.stream;
});

// ── Single order detail ───────────────────────────────────────────────────────
final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final service = ref.watch(orderServiceProvider);
  return service.getOrderById(orderId);
});
