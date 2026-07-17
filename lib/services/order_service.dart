import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/order_model.dart';
import '../utils/logger.dart';

class OrderService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool get _isAvailable => Firebase.apps.isNotEmpty;

  static const String _collection = 'orders';

  /// Place a new order
  Future<String> createOrder(OrderModel order) async {
    if (!_isAvailable) throw StateError('Firebase not available');
    try {
      AppLogger.info('Creating order for buyer: ${order.buyerId}');
      final data = order.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await _firestore.collection(_collection).add(data);
      await docRef.update({'orderId': docRef.id});
      AppLogger.info('Order created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating order: $e');
      rethrow;
    }
  }

  /// Stream orders for a buyer
  Stream<List<OrderModel>> streamOrdersByBuyer(String buyerId) {
    if (!_isAvailable) return Stream.value([]);
    return _firestore
        .collection(_collection)
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => OrderModel.fromJson(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream orders for a street seller
  Stream<List<OrderModel>> streamOrdersByStreetSeller(String sellerId) {
    if (!_isAvailable) return Stream.value([]);
    return _firestore
        .collection(_collection)
        .where('streetSellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => OrderModel.fromJson(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetch a single order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    if (!_isAvailable) return null;
    try {
      final doc = await _firestore.collection(_collection).doc(orderId).get();
      if (!doc.exists) return null;
      return OrderModel.fromJson(doc.data()!);
    } catch (e) {
      AppLogger.error('Error fetching order $orderId: $e');
      return null;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    Map<String, dynamic>? extraFields,
  }) async {
    if (!_isAvailable) return;
    try {
      final fields = <String, dynamic>{'orderStatus': status};
      if (extraFields != null) fields.addAll(extraFields);
      await _firestore.collection(_collection).doc(orderId).update(fields);
      AppLogger.info('Order $orderId status → $status');
    } catch (e) {
      AppLogger.error('Error updating order status: $e');
      rethrow;
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'cancelled', extraFields: {
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Confirm pickup
  Future<void> confirmPickup(String orderId) async {
    await updateOrderStatus(orderId, 'pickedUp', extraFields: {
      'pickupConfirmed': true,
    });
  }

  /// Confirm delivery
  Future<void> confirmDelivery(String orderId) async {
    await updateOrderStatus(orderId, 'delivered', extraFields: {
      'deliveryConfirmed': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream every order in the system — used by the admin dashboard
  /// and the Transactions screen. Backed by Firestore snapshots so
  /// totals stay current as new orders arrive. Sorted newest first
  /// so the admin always sees the most recent activity at the top.
  Stream<List<OrderModel>> streamAllOrders() {
    if (!_isAvailable) return Stream.value(<OrderModel>[]);
    try {
      return _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => OrderModel.fromJson(d.data()))
              .toList(growable: false));
    } catch (e) {
      AppLogger.error('Error streaming all orders: $e');
      return Stream.value(<OrderModel>[]);
    }
  }

  /// Stream orders created today — used by the admin dashboard's
  /// "Orders Today" stat tile. A query against `createdAt` with a
  /// start bound equal to today's midnight (local) lets Firestore
  /// serve the count from the day-bucket index.
  Stream<List<OrderModel>> streamTodaysOrders() {
    if (!_isAvailable) return Stream.value(<OrderModel>[]);
    try {
      final midnight = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      return _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: midnight)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => OrderModel.fromJson(d.data()))
              .toList(growable: false));
    } catch (e) {
      AppLogger.error("Error streaming today's orders: $e");
      return Stream.value(<OrderModel>[]);
    }
  }

  /// Stream orders filtered by their [orderStatus] field. Used by
  /// the admin Orders Management screen to drive the
  /// Pending / Completed / Cancelled / All tabs.
  ///
  /// Note: this query relies on the `orderStatus + createdAt`
  /// composite index in `firestore.indexes.json`.
  Stream<List<OrderModel>> streamOrdersByStatus(String orderStatus) {
    if (!_isAvailable) return Stream.value(<OrderModel>[]);
    try {
      return _firestore
          .collection(_collection)
          .where('orderStatus', isEqualTo: orderStatus)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => OrderModel.fromJson(d.data()))
              .toList(growable: false));
    } catch (e) {
      AppLogger.error('Error streaming orders by status $orderStatus: $e');
      return Stream.value(<OrderModel>[]);
    }
  }

  /// Stream orders created between [start] (inclusive) and [end]
  /// (exclusive). Used by the admin Sales Reports screen to compute
  /// Daily / Weekly / Monthly sales totals.
  Stream<List<OrderModel>> streamOrdersInRange(DateTime start, DateTime end) {
    if (!_isAvailable) return Stream.value(<OrderModel>[]);
    try {
      return _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => OrderModel.fromJson(d.data()))
              .toList(growable: false));
    } catch (e) {
      AppLogger.error('Error streaming orders in range: $e');
      return Stream.value(<OrderModel>[]);
    }
  }

  /// Admin override for order status. Used by the dispute-resolution
  /// flow when the admin needs to push an order to a specific
  /// state regardless of the buyer / seller participant logic.
  Future<void> adminUpdateOrderStatus(
    String orderId,
    String newStatus, {
    String? note,
  }) async {
    await updateOrderStatus(orderId, newStatus, extraFields: {
      if (note != null && note.isNotEmpty) 'adminNote': note,
      'adminLastTouchedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Count of orders currently in a specific [orderStatus]. Used
  /// by the admin dashboard's Pending / Completed / Cancelled
  /// stat tiles. Cheaper than fetching the full list — Firestore
  /// returns the doc count in a single round-trip.
  Stream<int> streamOrdersCountByStatus(String orderStatus) {
    if (!_isAvailable) return Stream.value(0);
    try {
      return _firestore
          .collection(_collection)
          .where('orderStatus', isEqualTo: orderStatus)
          .snapshots()
          .map((snap) => snap.docs.length);
    } catch (e) {
      AppLogger.error(
        'Error streaming orders count by status $orderStatus: $e',
      );
      return Stream.value(0);
    }
  }

  /// Client-side search across the full orders list. Cheap enough
  /// for admin use (orders capped at `streamAllOrders` limit) and
  /// avoids Firestore composite-index sprawl.
  Future<List<OrderModel>> searchOrders(String rawQuery) async {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return <OrderModel>[];
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get()
        .then((snap) => snap.docs
            .map((d) => OrderModel.fromJson(d.data()))
            .where((o) =>
                o.orderId.toLowerCase().contains(q) ||
                o.buyerId.toLowerCase().contains(q) ||
                (o.streetSellerId?.toLowerCase().contains(q) ?? false))
            .toList(growable: false));
  }

  /// Admin-side dispute resolution. Sets `disputeAction` and
  /// `disputeResolvedBy` so the audit trail makes the resolution
  /// authority obvious. Caller is responsible for writing the
  /// `activityLogs/{id}` entry — this service intentionally does
  /// not couple to the log service so it stays drop-in usable.
  Future<void> disputeResolution({
    required String orderId,
    required String action,
    required String resolvedByUid,
    String? note,
  }) async {
    await updateOrderStatus(orderId, action, extraFields: {
      if (note != null && note.isNotEmpty) 'adminNote': note,
      'disputeAction': action,
      'disputeResolvedBy': resolvedByUid,
      'disputeResolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
