// Buyer-facing model. The brokerage layer (existing FishListingModel) is the
// source of truth in Firestore — this is the Buyer Dashboard's view, with the
// extra invariants the UI needs (broker approval flag, in-stock signal).

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enums/fish_type.dart';
import '../models/enums/listing_status.dart';
import '../utils/timestamp_converter.dart';

/// A fish entry the Buyer sees in the marketplace.
///
/// `isBrokerApproved` is the *only* gate the Buyer Dashboard uses to decide
/// whether to render a listing — it must be `true` AND `status` must be
/// `active` AND `quantityKg > 0` for the item to appear in the buyer feed.
class FishItemModel {
  final String itemId;
  final String listingId;
  final String sellerId;
  final FishType fishType;
  final String customFishName; // when fishType == FishType.other
  final double quantityKg;
  final double pricePerKg;
  final double totalPrice;
  final List<String> imageUrls;
  final String? description;

  // ── Broker-approval contract (REQUIRED) ────────────────────────────────────
  final bool isBrokerApproved;
  final String? approvedBy; // dalali userId
  final DateTime? approvedAt;
  final ListingStatus status;

  // ── Location (denormalized from the broker / street seller) ───────────────
  final double? latitude;
  final double? longitude;
  final String? marketName;
  final String? regionName;

  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? soldAt;

  const FishItemModel({
    required this.itemId,
    required this.listingId,
    required this.sellerId,
    this.fishType = FishType.other,
    this.customFishName = '',
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalPrice,
    this.imageUrls = const [],
    this.description,
    this.isBrokerApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.status = ListingStatus.active,
    this.latitude,
    this.longitude,
    this.marketName,
    this.regionName,
    required this.createdAt,
    this.expiresAt,
    this.soldAt,
  });

  /// True if this item should be visible to a buyer right now.
  /// Since the broker/dalali role was removed, all active in-stock fish
  /// are buyable — no approval gate needed.
  bool get isBuyable =>
      status == ListingStatus.active &&
      quantityKg > 0 &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool get isInStock => quantityKg > 0;

  String get displayName =>
      fishType == FishType.other && customFishName.isNotEmpty
          ? customFishName
          : fishType.displayName;

  factory FishItemModel.fromMap(Map<String, dynamic> data, {String? docId}) {
    final typeStr = (data['fishType'] as String?) ?? 'other';
    return FishItemModel(
      itemId: docId ?? (data['itemId'] as String? ?? ''),
      listingId: (data['listingId'] as String?) ?? (docId ?? ''),
      sellerId: (data['sellerId'] ?? '') as String,
      fishType: FishTypeExtension.fromString(typeStr),
      customFishName: (data['customFishName'] as String?) ?? '',
      quantityKg: (data['quantityKg'] as num?)?.toDouble() ?? 0.0,
      pricePerKg: (data['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      imageUrls: (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      description: data['description'] as String?,
      isBrokerApproved: (data['isBrokerApproved'] as bool?) ??
          (data['dalaliApproved'] as bool? ??
              (data['status'] == 'active')), // sane fallback
      approvedBy: (data['approvedBy'] ?? data['dalaliId']) as String?,
      approvedAt: const OptionalTimestampConverter()
          .fromJson(data['approvedAt'] ?? data['createdAt']),
      status: ListingStatusExtension.fromString(
        (data['status'] as String?) ?? 'active',
      ),
      latitude: (data['latitude'] as num?)?.toDouble() ??
          (data['location'] is Map
              ? (data['location']['latitude'] as num?)?.toDouble()
              : null),
      longitude: (data['longitude'] as num?)?.toDouble() ??
          (data['location'] is Map
              ? (data['location']['longitude'] as num?)?.toDouble()
              : null),
      marketName: data['marketName'] as String?,
      regionName: data['regionName'] as String?,
      createdAt: const TimestampConverter().fromJson(data['createdAt']),
      expiresAt: const OptionalTimestampConverter().fromJson(data['expiresAt']),
      soldAt: const OptionalTimestampConverter().fromJson(data['soldAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'listingId': listingId,
        'sellerId': sellerId,
        'fishType': fishType.value,
        'customFishName': customFishName,
        'quantityKg': quantityKg,
        'pricePerKg': pricePerKg,
        'totalPrice': totalPrice,
        'imageUrls': imageUrls,
        'description': description,
        'isBrokerApproved': isBrokerApproved,
        'approvedBy': approvedBy,
        'approvedAt':
            approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
        'status': status.value,
        'latitude': latitude,
        'longitude': longitude,
        'marketName': marketName,
        'regionName': regionName,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt':
            expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
        'soldAt': soldAt == null ? null : Timestamp.fromDate(soldAt!),
      };
}
