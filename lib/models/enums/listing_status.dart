enum ListingStatus { active, sold, expired }

extension ListingStatusExtension on ListingStatus {
  String get displayName {
    switch (this) {
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.sold:
        return 'Sold';
      case ListingStatus.expired:
        return 'Expired';
    }
  }

  String get value {
    return name;
  }

  static ListingStatus fromString(String value) {
    try {
      return ListingStatus.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return ListingStatus.active;
    }
  }
}
