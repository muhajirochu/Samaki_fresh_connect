enum OrderPath { directFromDalali, pickupFromSeller }

extension OrderPathExtension on OrderPath {
  String get displayName {
    switch (this) {
      case OrderPath.directFromDalali:
        return 'Direct from Dalali';
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
      return OrderPath.directFromDalali;
    }
  }
}
