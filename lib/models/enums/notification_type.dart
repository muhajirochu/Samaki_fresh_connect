// Notification type taxonomy used by Phase 4. Stored as a string in
// Firestore; this enum keeps the rest of the app from passing magic
// strings around.

enum NotificationType {
  requestAccepted,
  requestRejected,
  requestOffered,
  fishAvailableNow,
  newSellerHasFish,
  orderStatusChanged,
  generic,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.requestAccepted:
        return 'request_accepted';
      case NotificationType.requestRejected:
        return 'request_rejected';
      case NotificationType.requestOffered:
        return 'request_offered';
      case NotificationType.fishAvailableNow:
        return 'fish_available_now';
      case NotificationType.newSellerHasFish:
        return 'new_seller_has_fish';
      case NotificationType.orderStatusChanged:
        return 'order_status_changed';
      case NotificationType.generic:
        return 'generic';
    }
  }

  String get emoji {
    switch (this) {
      case NotificationType.requestAccepted:
        return '✅';
      case NotificationType.requestRejected:
        return '😔';
      case NotificationType.requestOffered:
        return '💬';
      case NotificationType.fishAvailableNow:
        return '🐟';
      case NotificationType.newSellerHasFish:
        return '🆕';
      case NotificationType.orderStatusChanged:
        return '🚚';
      case NotificationType.generic:
        return '🔔';
    }
  }

  static NotificationType fromString(String? raw) {
    switch (raw) {
      case 'request_accepted':
        return NotificationType.requestAccepted;
      case 'request_rejected':
        return NotificationType.requestRejected;
      case 'request_offered':
        return NotificationType.requestOffered;
      case 'fish_available_now':
        return NotificationType.fishAvailableNow;
      case 'new_seller_has_fish':
        return NotificationType.newSellerHasFish;
      case 'order_status_changed':
        return NotificationType.orderStatusChanged;
      default:
        return NotificationType.generic;
    }
  }
}
