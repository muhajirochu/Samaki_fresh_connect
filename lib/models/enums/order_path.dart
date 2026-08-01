enum OrderPath { directFromSeller, pickupFromSeller }

extension OrderPathExtension on OrderPath {
  String get displayName {
    switch (this) {
      case OrderPath.directFromSeller:
        return 'Direct from Seller';
      case OrderPath.pickupFromSeller:
        return 'Pickup from Seller';
    }
  }

  String get value {
    return name;
  }

  static OrderPath fromString(String value) {
    try {
      return OrderPath.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return OrderPath.directFromSeller;
    }
  }
}
