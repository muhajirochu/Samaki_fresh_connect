import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/enums/order_status.dart';
import '../models/order_model.dart';


final orderTrackingServiceProvider = Provider<OrderTrackingService>((ref) {
  return OrderTrackingService(FirebaseFirestore.instance);
});

class OrderTrackingService {
  final FirebaseFirestore _firestore;

  OrderTrackingService(this._firestore);

  CollectionReference<OrderModel> get _ordersRef =>
      _firestore.collection('orders').withConverter<OrderModel>(
            fromFirestore: (snapshot, _) => OrderModel.fromJson(
              {'orderId': snapshot.id, ...snapshot.data()!},
            ),
            toFirestore: (order, _) {
              final json = order.toJson();
              json.remove('orderId');
              return json;
            },
          );

  /// Create a new order
  Future<String> createOrder(OrderModel order) async {
    final docRef = _ordersRef.doc();
    
    // Fetch latest location of buyer and seller to populate order coordinates
    GeoPoint? buyerLoc;
    GeoPoint? sellerLoc;
    
    try {
      if (order.buyerId.isNotEmpty) {
        final buyerDoc = await _firestore.collection('users').doc(order.buyerId).get();
        if (buyerDoc.exists) {
          final data = buyerDoc.data();
          if (data != null && data['location'] != null) {
            final loc = data['location'] as Map<String, dynamic>;
            if (loc['latitude'] != null && loc['longitude'] != null) {
              buyerLoc = GeoPoint((loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble());
            }
          }
        }
      }
      
      if (order.streetSellerId.isNotEmpty) {
        final sellerDoc = await _firestore.collection('users').doc(order.streetSellerId).get();
        if (sellerDoc.exists) {
          final data = sellerDoc.data();
          if (data != null && data['location'] != null) {
            final loc = data['location'] as Map<String, dynamic>;
            if (loc['latitude'] != null && loc['longitude'] != null) {
              sellerLoc = GeoPoint((loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble());
            }
          }
        }
      }
    } catch (e) {
      // Ignore failures fetching location, fallback to provided values
    }

    final newOrder = order.copyWith(
      orderId: docRef.id,
      buyerLocation: buyerLoc ?? order.buyerLocation,
      streetSellerLocation: sellerLoc ?? order.streetSellerLocation,
    );
    
    await docRef.set(newOrder);
    return docRef.id;
  }

  /// Get a single order as a stream
  Stream<OrderModel?> streamOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((snapshot) => snapshot.data());
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _ordersRef.doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update pickup code and status
  Future<void> setPickupCode(String orderId, String code) async {
    await _ordersRef.doc(orderId).update({
      'pickupCode': code,
      'status': OrderStatus.readyForPickup.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Complete an order (called after verifying pickup code)
  Future<void> completeOrder(String orderId) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update street seller's live location
  Future<void> updateSellerLocation(String orderId, GeoPoint location) async {
    await _ordersRef.doc(orderId).update({
      'streetSellerLocation': location,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream buyer orders
  Stream<List<OrderModel>> streamBuyerOrders(String buyerId) {
    return _ordersRef
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  /// Stream street seller orders
  Stream<List<OrderModel>> streamSellerOrders(String sellerId) {
    return _ordersRef
        .where('streetSellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  /// Stream pending street seller orders
  Stream<List<OrderModel>> streamSellerPendingOrders(String sellerId) {
    return _ordersRef
        .where('streetSellerId', isEqualTo: sellerId)
        .where('status', isEqualTo: OrderStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((d) => d.data()).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<OrderModel>> streamAllOrders() {
    return _ordersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  Stream<int> streamOrdersCountByStatus(String statusName) {
    return _ordersRef
        .where('status', isEqualTo: statusName)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<OrderModel>> streamTodaysOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _ordersRef
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  Stream<List<OrderModel>> streamOrdersInRange(DateTime start, DateTime end) {
    return _ordersRef
        .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('createdAt', isLessThan: end.toIso8601String())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }
}
