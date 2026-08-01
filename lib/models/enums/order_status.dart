enum OrderStatus {
  /// Initial state for a buyer-initiated order. The Firestore
  /// security rule (`firestore.rules` match /orders/{orderId})
  /// requires new orders to be created with `orderStatus ==
  /// 'pending'`. The seller confirms with a transition to
  /// `confirmed`.
  pending,

  /// Seller has accepted the order and the associated listing is
  /// marked `sold` atomically (see
  /// [OrderService.confirmOrderAndMarkListingSold]). The seller
  /// then advances to `inTransit` once the goods are handed off.
  confirmed,

  /// Seller has marked the order as handed off / out for delivery.
  /// Intermediate state between seller's acceptance and the
  /// buyer's receipt confirmation.
  inTransit,

  /// Terminal happy-path state. The buyer has confirmed receipt
  /// via [OrderService.confirmReceipt]. This is the state that
  /// admin/payout queries sum over.
  completed,

  /// Terminal off-path state. The order was rejected by the
  /// seller, cancelled by the buyer, or otherwise halted before
  /// reaching `completed`.
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending Confirmation';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value {
    return name;
  }

  /// String → enum parse. Defaults to [OrderStatus.pending] for
  /// unknown values: that's the initial state the buyer writes on
  /// creation, so a fallback there matches the most likely source
  /// of a fresh doc rather than surfacing an undefined enum case
  /// in the UI.
  static OrderStatus fromString(String value) {
    try {
      return OrderStatus.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return OrderStatus.pending;
    }
  }
}
