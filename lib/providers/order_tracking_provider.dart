import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/enums/notification_type.dart';
import '../models/enums/order_status.dart';
import '../models/order_model.dart';
import '../services/notification_service.dart';
import '../services/order_tracking_service.dart';
import 'notification_provider.dart';

final orderTrackingProvider = Provider<OrderTrackingStateNotifier>((ref) {
  final service = ref.watch(orderTrackingServiceProvider);
  final notifSvc = ref.watch(notificationServiceProvider);
  return OrderTrackingStateNotifier(service, notifSvc);
});

class OrderTrackingStateNotifier {
  final OrderTrackingService _service;
  final NotificationService _notifSvc;

  OrderTrackingStateNotifier(this._service, this._notifSvc);

  /// Generates a random 4 digit pickup code
  String generatePickupCode() {
    final rng = Random();
    return (1000 + rng.nextInt(9000)).toString();
  }

  /// Sets the pickup code for an order and notifies buyer
  Future<void> generateAndSetPickupCode(OrderModel order) async {
    final code = generatePickupCode();
    await _service.setPickupCode(order.orderId, code);
    await _notifyBuyer(
      order.buyerId,
      order.orderId,
      'Order Ready for Pickup',
      'Your order is ready. Use code $code to pick it up.',
    );
  }

  /// Verifies pickup code and completes order if correct
  Future<bool> verifyPickupCode(OrderModel order, String inputCode) async {
    if (inputCode == order.pickupCode) {
      await _service.completeOrder(order.orderId);
      await _notifyBuyer(
        order.buyerId,
        order.orderId,
        'Order Completed',
        'Your order has been completed successfully!',
      );
      return true;
    }
    return false;
  }

  /// Updates status and notifies buyer
  Future<void> updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    await _service.updateOrderStatus(order.orderId, newStatus);
    String title = 'Order Status Updated';
    String body = 'Your order is now ${newStatus.name}.';
    if (newStatus == OrderStatus.arriving) {
      title = 'Order Arriving Soon';
      body = 'The seller is on the way with your order!';
    } else if (newStatus == OrderStatus.cancelled) {
      title = 'Order Cancelled';
      body = 'Your order was cancelled.';
    }
    await _notifyBuyer(order.buyerId, order.orderId, title, body);
  }

  Future<void> _notifyBuyer(String buyerId, String orderId, String title, String body) async {
    await _notifSvc.writeNotification(
      userId: buyerId,
      title: title,
      body: body,
      type: NotificationType.orderStatusChanged,
      relatedId: orderId,
    );
    await _notifSvc.showLocal(
      title: '🚚 $title',
      body: body,
      type: NotificationType.orderStatusChanged,
    );
  }
}

/// Provider to stream a specific order's real-time data
final orderStreamProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final service = ref.watch(orderTrackingServiceProvider);
  return service.streamOrder(orderId);
});

/// Streams all active and past orders for a buyer
final buyerOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, buyerId) {
  final service = ref.watch(orderTrackingServiceProvider);
  return service.streamBuyerOrders(buyerId);
});

/// Streams all active and past orders for a street seller
final sellerOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, sellerId) {
  final service = ref.watch(orderTrackingServiceProvider);
  return service.streamSellerOrders(sellerId);
});

/// Streams pending orders for a street seller
final sellerPendingOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, sellerId) {
  final service = ref.watch(orderTrackingServiceProvider);
  return service.streamSellerPendingOrders(sellerId);
});
