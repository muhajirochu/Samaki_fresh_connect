import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

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

// ── Single order detail ───────────────────────────────────────────────────────
final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final service = ref.watch(orderServiceProvider);
  return service.getOrderById(orderId);
});
