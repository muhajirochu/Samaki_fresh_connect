import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/delivery_model.dart';
import '../models/order_model.dart';

final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  return DeliveryService(FirebaseFirestore.instance);
});

/// Manages the `deliveries/{orderId}` collection. One delivery doc per
/// order, created automatically when a seller accepts an order and
/// transitions it to `preparing`.
class DeliveryService {
  static const String _collection = 'deliveries';

  final FirebaseFirestore _firestore;
  DeliveryService(this._firestore);

  CollectionReference<DeliveryModel> get _ref =>
      _firestore.collection(_collection).withConverter<DeliveryModel>(
            fromFirestore: (s, _) => DeliveryModel.fromJson({
              'deliveryId': s.id,
              ...s.data()!,
            }),
            toFirestore: (d, _) {
              final j = d.toJson();
              j.remove('deliveryId');
              return j;
            },
          );

  /// Creates the delivery doc for [order]. Idempotent — uses the
  /// `orderId` as the deterministic doc id and `set(merge: true)`.
  Future<String> createDeliveryForOrder(OrderModel order) async {
    final docId = order.orderId;
    final model = DeliveryModel(
      deliveryId: docId,
      orderId: order.orderId,
      sellerId: order.streetSellerId,
      buyerId: order.buyerId,
      pickupLocation: order.streetSellerLocation,
      dropoffLocation: order.buyerLocation,
      status: 'pending',
    );
    await _ref.doc(docId).set(model, SetOptions(merge: true));
    return docId;
  }

  Future<void> markPickedUp(String deliveryId, DateTime at) =>
      _ref.doc(deliveryId).update({
        'status': 'picked_up',
        'pickedUpAt': Timestamp.fromDate(at),
      });

  Future<void> markDelivered(String deliveryId, DateTime at) =>
      _ref.doc(deliveryId).update({
        'status': 'delivered',
        'deliveredAt': Timestamp.fromDate(at),
      });

  Stream<DeliveryModel?> streamDeliveryForOrder(String orderId) =>
      _ref.doc(orderId).snapshots().map((s) => s.data());
}
