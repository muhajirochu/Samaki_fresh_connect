enum OrderStatus {
  /// Initial state for a buyer-initiated order that has not yet
  /// been picked up by the seller. The Firestore security rule
  /// (`firestore.rules` match /orders/{orderId}) requires new orders
  /// to be created with `orderStatus == 'pending'`. The seller
  /// confirms with a transition to `confirmed`.
  pending,
  placed,
  assigned,
  negotiating,
  pickedUp,
  inTransit,
  delivered,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending Confirmation';
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.negotiating:
        return 'Negotiating';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
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
  /// of a fresh doc rather than the older `placed` legacy value.
  static OrderStatus fromString(String value) {
    try {
      return OrderStatus.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return OrderStatus.pending;
    }
  }
}
