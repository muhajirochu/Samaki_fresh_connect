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
}
