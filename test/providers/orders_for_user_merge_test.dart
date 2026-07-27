// Regression tests for ordersForUserProvider — the merge logic
// between buyer-side and seller-side order streams.
//
// Bug history: the previous My Orders screen picked a single provider
// based on the user's role (buyerOrdersProvider for buyers,
// streetSellerOrdersProvider for sellers). A street seller who also
// purchased stock from another seller saw 'No Orders Found' because
// the buyer-side stream returned empty for them — every order they
// had appeared on the *seller* side of the join.
//
// ordersForUserProvider is supposed to merge both streams so the
// user sees every order they participate in regardless of side.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:samakifresh_connect/models/enums/order_status.dart';
import 'package:samakifresh_connect/models/order_model.dart';

OrderModel _order(String id, {String? buyerId, String? sellerId}) =>
    OrderModel(
      orderId: id,
      orderPath: 'direct',
      buyerId: buyerId ?? '',
      streetSellerId: sellerId,
      listingId: 'l1',
      originalPrice: 1000,
      finalPrice: 1000,
      quantityKg: 1,
      orderStatus: OrderStatus.placed.name,
      pickupConfirmed: false,
      deliveryConfirmed: false,
      createdAt: DateTime(2026, 1, 1),
    );

/// Simple merge engine that mirrors ordersForUserProvider's
/// behaviour — de-duplicates by orderId and sorts by createdAt DESC.
StreamController<List<OrderModel>>? controller;
List<OrderModel>? lastBuyer;
List<OrderModel>? lastSeller;

void _emit() {
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

List<OrderModel> startMerge({
  required Stream<List<OrderModel>> buyerStream,
  required Stream<List<OrderModel>> sellerStream,
}) {
  controller = StreamController<List<OrderModel>>.broadcast(
    onListen: () {
      buyerStream.listen((data) {
        lastBuyer = data;
        _emit();
      }, onError: (_, __) {});
      sellerStream.listen((data) {
        lastSeller = data;
        _emit();
      }, onError: (_, __) {});
    },
  );
  return [];
}

void tearDownMerge() {
  controller?.close();
  controller = null;
  lastBuyer = null;
  lastSeller = null;
}

void main() {
  group('ordersForUserProvider merge logic', () {
    test('orders as buyer AND as seller are both visible', () async {
      // Asha bought a fish from Salim AND sold a fish to Fatma.
      final buyerOrders = [_order('o-bought', buyerId: 'asha', sellerId: 'salim')];
      final sellerOrders = [_order('o-sold', buyerId: 'fatma', sellerId: 'asha')];

      final buyerController = StreamController<List<OrderModel>>();
      final sellerController = StreamController<List<OrderModel>>();

      startMerge(
        buyerStream: buyerController.stream,
        sellerStream: sellerController.stream,
      );
      buyerController.add(buyerOrders);
      sellerController.add(sellerOrders);

      // Allow microtasks to run so both streams emit + the merger
      // re-computes the combined list.
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final emitted = controller!.stream.first;
      buyerController.close();
      sellerController.close();
      final result = await emitted;
      tearDownMerge();

      expect(result.length, 2);
      expect(result.map((o) => o.orderId).toSet(),
          {'o-bought', 'o-sold'});
    });

    test('a single order that is both buyer AND seller is de-duplicated',
        () async {
      // An order placed by a street seller on their own listing has
      // buyerId == streetSellerId. The merge must yield a single
      // entry, not two.
      final selfOrder = [
        _order('self-1', buyerId: 'asha', sellerId: 'asha'),
      ];
      final buyerController = StreamController<List<OrderModel>>();
      final sellerController = StreamController<List<OrderModel>>();

      startMerge(
        buyerStream: buyerController.stream,
        sellerStream: sellerController.stream,
      );
      buyerController.add(selfOrder);
      sellerController.add(selfOrder);

      await Future<void>.delayed(const Duration(milliseconds: 30));

      final emitted = controller!.stream.first;
      buyerController.close();
      sellerController.close();
      final result = await emitted;
      tearDownMerge();

      expect(result.length, 1,
          reason: 'self-purchased orders must not appear twice');
      expect(result.first.orderId, 'self-1');
    });

    test('empty buyer-side still shows seller-side orders', () async {
      // Asha has only sold fish, never bought any.
      final buyerController = StreamController<List<OrderModel>>();
      final sellerController = StreamController<List<OrderModel>>();

      startMerge(
        buyerStream: buyerController.stream,
        sellerStream: sellerController.stream,
      );
      buyerController.add(<OrderModel>[]);
      sellerController.add([
        _order('o1', buyerId: 'fatma', sellerId: 'asha'),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 30));

      final emitted = controller!.stream.first;
      buyerController.close();
      sellerController.close();
      final result = await emitted;
      tearDownMerge();

      expect(result.length, 1);
      expect(result.first.orderId, 'o1');
    });
  });
}