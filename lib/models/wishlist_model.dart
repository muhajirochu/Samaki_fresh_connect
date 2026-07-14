// A buyer's wishlist — fish types they're hunting for. When the live
// fish feed sees a matching broker-approved listing, the notification
// system can fire a "fish_available_now" event. Persisted under
// `users/{buyerId}/wishlist/{fishTypeValue}`.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums/fish_type.dart';

class WishlistEntry {
  final String id; // fishType value, lowercased
  final FishType fishType;
  final DateTime addedAt;
  final double? maxPricePerKg;

  /// Set when a notification has been shown, so we don't spam the buyer
  /// every time a matching listing ticks through.
  final DateTime? lastNotifiedAt;
  final String? lastNotifiedListingId;

  const WishlistEntry({
    required this.id,
    required this.fishType,
    required this.addedAt,
    this.maxPricePerKg,
    this.lastNotifiedAt,
    this.lastNotifiedListingId,
  });

  bool isStale(DateTime now) {
    // After 6h we forget we ever notified, so a new incoming listing
    // can fire again.
    if (lastNotifiedAt == null) return true;
    return now.difference(lastNotifiedAt!).inHours >= 6;
  }

  WishlistEntry copyWith({DateTime? lastNotifiedAt, String? lastNotifiedListingId}) {
    return WishlistEntry(
      id: id,
      fishType: fishType,
      addedAt: addedAt,
      maxPricePerKg: maxPricePerKg,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
      lastNotifiedListingId:
          lastNotifiedListingId ?? this.lastNotifiedListingId,
    );
  }

  Map<String, dynamic> toMap() => {
        'fishType': fishType.value,
        'addedAt': Timestamp.fromDate(addedAt),
        'maxPricePerKg': maxPricePerKg,
        'lastNotifiedAt': lastNotifiedAt == null
            ? null
            : Timestamp.fromDate(lastNotifiedAt!),
        'lastNotifiedListingId': lastNotifiedListingId,
      };

  factory WishlistEntry.fromMap(Map<String, dynamic> data, {String? docId}) {
    return WishlistEntry(
      id: docId ?? (data['fishType'] as String? ?? ''),
      fishType: FishTypeExtension.fromString(data['fishType'] as String? ?? 'other'),
      addedAt: (data['addedAt'] is Timestamp
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['addedAt']?.toString() ?? '') ??
              DateTime.now()),
      maxPricePerKg: (data['maxPricePerKg'] as num?)?.toDouble(),
      lastNotifiedAt: data['lastNotifiedAt'] is Timestamp
          ? (data['lastNotifiedAt'] as Timestamp).toDate()
          : null,
      lastNotifiedListingId: data['lastNotifiedListingId'] as String?,
    );
  }
}
