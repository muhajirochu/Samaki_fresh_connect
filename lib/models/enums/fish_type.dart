enum FishType { tilapia, tuna, mackerel, sardine, grouper, snapper, other }

extension FishTypeExtension on FishType {
  String get displayName {
    switch (this) {
      case FishType.tilapia:
        return 'Tilapia';
      case FishType.tuna:
        return 'Tuna';
      case FishType.mackerel:
        return 'Mackerel';
      case FishType.sardine:
        return 'Sardine';
      case FishType.grouper:
        return 'Grouper';
      case FishType.snapper:
        return 'Snapper';
      case FishType.other:
        return 'Other';
    }
  }

  String get value {
    return name;
  }

  static FishType fromString(String value) {
    try {
      return FishType.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return FishType.other;
    }
  }

  static List<String> getAllTypes() {
    return FishType.values.map((e) => e.displayName).toList();
  }
}
