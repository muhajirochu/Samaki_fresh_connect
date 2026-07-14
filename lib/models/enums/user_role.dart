enum UserRole { streetSeller, buyer, admin }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.streetSeller:
        return 'Street Seller';
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get value {
    return name;
  }

  static UserRole fromString(String value) {
    try {
      return UserRole.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return UserRole.buyer;
    }
  }
}
