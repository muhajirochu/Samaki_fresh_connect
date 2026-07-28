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
      final list = <OrderModel>[];
      for (final d in snap.docs) {
        try {
          list.add(OrderModel.fromJson(d.data()));
        } catch (e) {
          // A malformed order doc must not kill the whole "My
          // Orders" feed — drop it and keep the rest.
          AppLogger.warning(
              'streamOrdersByBuyer: dropping malformed doc ${d.id}: $e');
        }
      }
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
      final list = <OrderModel>[];
      for (final d in snap.docs) {
        try {
          list.add(OrderModel.fromJson(d.data()));
        } catch (e) {
          AppLogger.warning(
              'streamOrdersByStreetSeller: dropping malformed doc ${d.id}: $e');
        }
      }
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

  /// Seller accepts a buyer's pending order AND atomically marks the
  /// associated listing as sold. Both writes are seller-owned (the
  /// order has `streetSellerId == request.auth.uid`, the listing has
  /// `sellerId == request.auth.uid`), so the Firestore rules permit
  /// each write. A `WriteBatch` keeps them atomic — if either fails,
  /// neither is committed, so a partially-confirmed order can never
  /// be observed (the listing would still be `active`).
  Future<void> confirmOrderAndMarkListingSold({
    required String orderId,
    required String listingId,
  }) async {
    if (!_isAvailable) return;
    try {
      final batch = _firestore.batch();
      final orderRef = _firestore.collection(_collection).doc(orderId);
      batch.update(orderRef, {
        'orderStatus': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      // fishListings is a different collection from `orders`; we
      // hard-code the path here rather than threading the service
      // reference through the constructor to keep the batch atomic
      // on a single `commit()`.
      final listingRef = FirebaseFirestore.instance
          .collection('fishListings')
          .doc(listingId);
      batch.update(listingRef, {
        'status': 'sold',
        'soldAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      AppLogger.info(
          'Confirmed order $orderId + sold listing $listingId (atomic)');
    } catch (e) {
      AppLogger.error(
          'confirmOrderAndMarkListingSold failed for order $orderId: $e');
      rethrow;
    }
  }

  /// Seller rejects a buyer's pending order. The order transitions
  /// `pending → cancelled` and the listing is left untouched (it
  /// stays `active` so other buyers can still place orders against
  /// it). The Firestore rule at match /orders/{orderId} allows the
  /// seller to perform this transition when the same `fieldUnchanged`
  /// guards as the `pending → confirmed` path apply.
  Future<void> rejectPendingOrder(String orderId) async {
    if (!_isAvailable) return;
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'orderStatus': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'seller',
      });
      AppLogger.info('Seller rejected pending order $orderId');
    } catch (e) {
      AppLogger.error('rejectPendingOrder failed for $orderId: $e');
      rethrow;
    }
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
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed single-field `createdAt DESC` index is
      // available.
      return _firestore
          .collection(_collection)
          .snapshots()
          .map((snap) {
        final list = <OrderModel>[];
        for (final d in snap.docs) {
          try {
            list.add(OrderModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamAllOrders: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
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
          .snapshots()
          .map((snap) {
        final list = <OrderModel>[];
        for (final d in snap.docs) {
          try {
            list.add(OrderModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                "streamTodaysOrders: dropping malformed doc ${d.id}: $e");
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e) {
      AppLogger.error("Error streaming today's orders: $e");
      return Stream.value(<OrderModel>[]);
    }
  }

  /// Stream orders filtered by their [orderStatus] field. Used by
  /// the admin Orders Management screen to drive the
  /// Pending / Completed / Cancelled / All tabs.
  Stream<List<OrderModel>> streamOrdersByStatus(String orderStatus) {
    if (!_isAvailable) return Stream.value(<OrderModel>[]);
    try {
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(orderStatus, createdAt DESC)` composite
      // index is available.
      return _firestore
          .collection(_collection)
          .where('orderStatus', isEqualTo: orderStatus)
          .snapshots()
          .map((snap) {
        final list = <OrderModel>[];
        for (final d in snap.docs) {
          try {
            list.add(OrderModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamOrdersByStatus: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
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
      // No `.orderBy(...)` — sorting in memory keeps the stream alive
      // until the deployed `(createdAt ASC)` composite index is
      // available.
      return _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end)
          .snapshots()
          .map((snap) {
        final list = <OrderModel>[];
        for (final d in snap.docs) {
          try {
            list.add(OrderModel.fromJson(d.data()));
          } catch (e) {
            AppLogger.warning(
                'streamOrdersInRange: dropping malformed doc ${d.id}: $e');
          }
        }
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
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
        .limit(500)
        .get()
        .then((snap) {
      final list = <OrderModel>[];
      for (final d in snap.docs) {
        try {
          list.add(OrderModel.fromJson(d.data()));
        } catch (e) {
          AppLogger.warning(
              'searchOrders: dropping malformed doc ${d.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.where((o) =>
          o.orderId.toLowerCase().contains(q) ||
          o.buyerId.toLowerCase().contains(q) ||
          (o.streetSellerId?.toLowerCase().contains(q) ?? false)).toList();
    });
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
