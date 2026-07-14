enum OrderStatus {
  placed,
  assigned,
  negotiating,
  pickedUp,
  inTransit,
  delivered,
  completed,
  cancelled
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
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

  static OrderStatus fromString(String value) {
    try {
      return OrderStatus.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return OrderStatus.placed;
    }
  }
}
