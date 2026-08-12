import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/enums/notification_type.dart';
import '../models/enums/order_status.dart';
import '../models/order_model.dart';
import '../services/delivery_service.dart';
import '../services/notification_service.dart';
import '../services/order_tracking_service.dart';
import '../services/seller_location_tracker.dart';
import '../utils/logger.dart';
import 'notification_provider.dart';

final orderTrackingProvider = Provider<OrderTrackingStateNotifier>((ref) {
  final service = ref.watch(orderTrackingServiceProvider);
  final notifSvc = ref.watch(notificationServiceProvider);
  final deliverySvc = ref.watch(deliveryServiceProvider);
  return OrderTrackingStateNotifier(service, notifSvc, deliverySvc);
});

class OrderTrackingStateNotifier {
  final OrderTrackingService _service;
  final NotificationService _notifSvc;
  final DeliveryService _deliverySvc;

  OrderTrackingStateNotifier(this._service, this._notifSvc, this._deliverySvc);

  Timer? _shareTimer;
  String? _sharingForOrderId;

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

    // Spin up a delivery doc the moment the seller starts preparing
    // the order — gives analytics and post-hoc tracking a record
    // independent of the order's status state machine.
    if (newStatus == OrderStatus.preparing) {
      try {
        await _deliverySvc.createDeliveryForOrder(order);
      } catch (e) {
        AppLogger.warning('createDeliveryForOrder failed: $e');
      }
    }
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

  /// Starts mirroring the seller's latest GPS fix into
  /// `orders/{orderId}.streetSellerLocation` while delivery is in
  /// flight. Idempotent — calling again with a different orderId
  /// cancels the previous timer and re-binds.
  void startSharingLocation({
    required String orderId,
    required SellerLocationTracker tracker,
    Duration interval = const Duration(seconds: 10),
  }) {
    if (_sharingForOrderId == orderId && _shareTimer != null) return;
    stopSharingLocation();
    _sharingForOrderId = orderId;
    _shareTimer = Timer.periodic(interval, (_) async {
      final pos = tracker.lastPosition;
      if (pos == null) return;
      try {
        await _service.updateSellerLocation(
          orderId,
          GeoPoint(pos.latitude, pos.longitude),
        );
      } catch (e) {
        AppLogger.warning('Live seller position mirror failed: $e');
      }
    });
  }

  /// Cancels the live mirror. Safe to call when not running.
  void stopSharingLocation() {
    _shareTimer?.cancel();
    _shareTimer = null;
    _sharingForOrderId = null;
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
