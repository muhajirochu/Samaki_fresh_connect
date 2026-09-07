// Payout Service — Held Payment & Commission Calculation.
//
// Manages the lifecycle of a payment after the Sandbox gateway succeeds:
//
//   holdPayment()       — marks the payment as HELD, order as CONFIRMED.
//
//   confirmReceived()   — called when the BUYER confirms they received the fish.
//                         Calculates the 5% platform commission, writes the
//                         payout breakdown, creates a TransactionModel record,
//                         marks payment as RELEASED, and sets buyerConfirmed = true.
//
//   releasePaymentForCompletedOrder() — legacy method kept for compatibility.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/enums/order_status.dart';
import '../models/enums/payment_status.dart';
import '../models/enums/payout_status.dart';
import '../models/transaction_model.dart';
import '../utils/logger.dart';

// ── Constants ──────────────────────────────────────────────────────────────

const double kPlatformCommissionRate = 0.05; // 5 %
const double kSellerPayoutRate = 0.95;       // 95 %

// ── Service ────────────────────────────────────────────────────────────────

final payoutServiceProvider = Provider<PayoutService>((ref) {
  return PayoutService(FirebaseFirestore.instance);
});

class PayoutService {
  final FirebaseFirestore _firestore;

  PayoutService(this._firestore);

  DocumentReference<Map<String, dynamic>> _orderRef(String orderId) =>
      _firestore.collection('orders').doc(orderId);

  CollectionReference<Map<String, dynamic>> get _txnRef =>
      _firestore.collection('transactions');

  // ── holdPayment ───────────────────────────────────────────────────────────

  /// Called immediately after the Sandbox payment succeeds.
  /// Marks the payment as HELD. The seller does NOT receive payout yet.
  Future<void> holdPayment({
    required String orderId,
    required double totalAmount,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    try {
      await _orderRef(orderId).update({
        'status': OrderStatus.confirmed.name,
        'paymentStatus': PaymentStatus.held.name,
        'payoutStatus': PayoutStatus.held.name,
        'isPaid': true,
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('PayoutService: payment held for order $orderId');
    } catch (e) {
      AppLogger.error('PayoutService.holdPayment failed: $e');
      rethrow;
    }
  }

  // ── confirmReceived ───────────────────────────────────────────────────────

  /// Called when the BUYER confirms they received the fish correctly.
  /// Accepts optional comment and photo URL for feedback record.
  /// This is the ONLY trigger that releases payout to the StreetSeller.
  Future<bool> confirmReceived({
    required String orderId,
    required double totalAmount,
    required String paymentMethod,
    required String paymentReference,
    String buyerComment = '',
    String buyerFeedbackImageUrl = '',
  }) async {
    try {
      // ── Fetch order to verify state ────────────────────────────────────
      final snap = await _orderRef(orderId).get();
      if (!snap.exists) {
        AppLogger.warning('PayoutService.confirmReceived: order $orderId not found');
        return false;
      }
      final data = snap.data()!;

      // Guard: prevent double-confirmation
      final alreadyConfirmed = data['buyerConfirmed'] as bool? ?? false;
      if (alreadyConfirmed) {
        AppLogger.warning('PayoutService.confirmReceived: order $orderId already confirmed');
        return false;
      }

      // Guard: must be in a state where delivery was underway
      final statusStr = data['status'] as String? ?? '';
      if (statusStr != 'outForDelivery' &&
          statusStr != 'readyForPickup' &&
          statusStr != 'completed') {
        AppLogger.warning('PayoutService.confirmReceived: order $orderId in wrong state: $statusStr');
        return false;
      }

      // ── Commission calculation (server-side) ───────────────────────────
      final platformCommission = totalAmount * kPlatformCommissionRate;
      final sellerPayout = totalAmount * kSellerPayoutRate;

      // ── Atomic order update ────────────────────────────────────────────
      await _orderRef(orderId).update({
        'status': OrderStatus.completed.name,
        'paymentStatus': PaymentStatus.released.name,
        'payoutStatus': PayoutStatus.paid.name,
        'buyerConfirmed': true,
        'buyerConfirmedAt': FieldValue.serverTimestamp(),
        'buyerComment': buyerComment,
        'buyerFeedbackImageUrl': buyerFeedbackImageUrl,
        'isDisputed': false,
        'commissionRate': kPlatformCommissionRate,
        'commissionAmount': platformCommission,
        'sellerEarnings': sellerPayout,
        'completedAt': FieldValue.serverTimestamp(),
        'releasedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ── Create payout transaction record ──────────────────────────────
      final now = DateTime.now();
      final txnId = 'TXN-PAYOUT-${now.millisecondsSinceEpoch}';
      final txn = TransactionModel(
        transactionId: txnId,
        orderId: orderId,
        finalAmount: totalAmount,
        sellerAmount: sellerPayout,
        platformAmount: platformCommission,
        paymentMethod: paymentMethod,
        transactionReference: paymentReference,
        status: PaymentStatus.released.name,
        createdAt: now,
      );

      await _txnRef.doc(txnId).set(txn.toJson());

      AppLogger.info(
        'PayoutService.confirmReceived: order $orderId — '
        'total=$totalAmount commission=$platformCommission seller=$sellerPayout',
      );
      return true;
    } catch (e) {
      AppLogger.error('PayoutService.confirmReceived failed: $e');
      return false;
    }
  }

  // ── flagDispute ───────────────────────────────────────────────────────────

  /// Called when the BUYER reports that the order was wrong/incorrect.
  /// Flags the order as disputed so admin can review.
  Future<bool> flagDispute({
    required String orderId,
    String buyerComment = '',
    String buyerFeedbackImageUrl = '',
  }) async {
    try {
      final snap = await _orderRef(orderId).get();
      if (!snap.exists) return false;

      final data = snap.data()!;
      final alreadyConfirmed = data['buyerConfirmed'] as bool? ?? false;
      if (alreadyConfirmed) return false;

      await _orderRef(orderId).update({
        'status': OrderStatus.disputed.name,
        'payoutStatus': PayoutStatus.disputed.name,
        'isDisputed': true,
        'buyerComment': buyerComment,
        'buyerFeedbackImageUrl': buyerFeedbackImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('PayoutService.flagDispute: order $orderId disputed');
      return true;
    } catch (e) {
      AppLogger.error('PayoutService.flagDispute failed: $e');
      return false;
    }
  }

  // ── releasePaymentForCompletedOrder ───────────────────────────────────────

  /// DEPRECATED — kept for backwards compatibility with old pickup-code flow.
  /// New flow uses confirmReceived() triggered by buyer.
  Future<bool> releasePaymentForCompletedOrder({
    required String orderId,
    required double totalAmount,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    return confirmReceived(
      orderId: orderId,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
    );
  }

  // ── Admin manual actions ──────────────────────────────────────────────────

  Future<void> issueRefund(String orderId) async {
    await _orderRef(orderId).update({
      'paymentStatus': PaymentStatus.refunded.name,
      'payoutStatus': PayoutStatus.refunded.name,
      'status': OrderStatus.cancelled.name,
      'isDisputed': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> processPayout(String orderId) async {
    await _orderRef(orderId).update({
      'payoutStatus': PayoutStatus.paid.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markDisputed(String orderId) async {
    await _orderRef(orderId).update({
      'status': OrderStatus.disputed.name,
      'payoutStatus': PayoutStatus.disputed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
