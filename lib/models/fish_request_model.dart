// A buyer's open request for fish. Distinct from OrderModel: an Order is the
// post-pickup transaction, a FishRequest is the pre-purchase intent the buyer
// broadcasts to dalalis / street sellers ("I want 5kg of Tuna by Friday").

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enums/fish_type.dart';
import '../utils/timestamp_converter.dart';

enum FishRequestStatus {
  open, // buyer just posted it, waiting for offers
  offered, // at least one seller responded
  accepted, // buyer picked an offer, order created
  fulfilled, // order completed
  cancelled, // buyer cancelled before accepting
  expired, // needsBy passed with no offer accepted
}

extension FishRequestStatusExtension on FishRequestStatus {
  String get value {
    switch (this) {
      case FishRequestStatus.open:
        return 'open';
      case FishRequestStatus.offered:
        return 'offered';
      case FishRequestStatus.accepted:
        return 'accepted';
      case FishRequestStatus.fulfilled:
        return 'fulfilled';
      case FishRequestStatus.cancelled:
        return 'cancelled';
      case FishRequestStatus.expired:
        return 'expired';
    }
  }

  String get displayName {
    switch (this) {
      case FishRequestStatus.open:
        return 'Open';
      case FishRequestStatus.offered:
        return 'Offers Received';
      case FishRequestStatus.accepted:
        return 'Accepted';
      case FishRequestStatus.fulfilled:
        return 'Fulfilled';
      case FishRequestStatus.cancelled:
        return 'Cancelled';
      case FishRequestStatus.expired:
        return 'Expired';
    }
  }

  static FishRequestStatus fromString(String value) {
    try {
      return FishRequestStatus.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return FishRequestStatus.open;
    }
  }
}

class FishRequestModel {
  final String requestId;
  final String buyerId; // the ONLY author — session-isolated
  final FishType fishType;
  final String customFishName;
  final double quantityKg;
  final double? maxPricePerKg;
  final String? notes;
  final String? regionName;
  final String? marketName;

  // Delivery constraints
  final DateTime? needsBy;
  final bool deliveryRequired;

  final FishRequestStatus status;
  final int offersCount; // populated by sellers' responses

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;
  final String? acceptedOfferId; // links to the chosen seller's offer
  final String? resultingOrderId; // links to the created OrderModel

  const FishRequestModel({
    required this.requestId,
    required this.buyerId,
    this.fishType = FishType.other,
    this.customFishName = '',
    this.quantityKg = 1.0,
    this.maxPricePerKg,
    this.notes,
    this.regionName,
    this.marketName,
    this.needsBy,
    this.deliveryRequired = false,
    this.status = FishRequestStatus.open,
    this.offersCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.cancelledAt,
    this.acceptedOfferId,
    this.resultingOrderId,
  });

  bool get isActive =>
      status == FishRequestStatus.open || status == FishRequestStatus.offered;

  /// Counts toward the "Active Requests" dashboard summary.
  bool get countsAsActive => isActive;

  String get displayName =>
      fishType == FishType.other && customFishName.isNotEmpty
          ? customFishName
          : fishType.displayName;

  factory FishRequestModel.fromMap(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    return FishRequestModel(
      requestId: docId ?? (data['requestId'] as String? ?? ''),
      buyerId: (data['buyerId'] as String?) ?? '',
      fishType:
          FishTypeExtension.fromString((data['fishType'] as String?) ?? 'other'),
      customFishName: (data['customFishName'] as String?) ?? '',
      quantityKg: (data['quantityKg'] as num?)?.toDouble() ?? 1.0,
      maxPricePerKg: (data['maxPricePerKg'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      regionName: data['regionName'] as String?,
      marketName: data['marketName'] as String?,
      needsBy: const OptionalTimestampConverter().fromJson(data['needsBy']),
      deliveryRequired: (data['deliveryRequired'] as bool?) ?? false,
      status: FishRequestStatusExtension.fromString(
        (data['status'] as String?) ?? 'open',
      ),
      offersCount: (data['offersCount'] as num?)?.toInt() ?? 0,
      createdAt: const TimestampConverter().fromJson(data['createdAt']),
      updatedAt: const TimestampConverter().fromJson(
        data['updatedAt'] ?? data['createdAt'],
      ),
      acceptedAt: const OptionalTimestampConverter().fromJson(data['acceptedAt']),
      cancelledAt:
          const OptionalTimestampConverter().fromJson(data['cancelledAt']),
      acceptedOfferId: data['acceptedOfferId'] as String?,
      resultingOrderId: data['resultingOrderId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'buyerId': buyerId,
        'fishType': fishType.value,
        'customFishName': customFishName,
        'quantityKg': quantityKg,
        'maxPricePerKg': maxPricePerKg,
        'notes': notes,
        'regionName': regionName,
        'marketName': marketName,
        'needsBy': needsBy == null ? null : Timestamp.fromDate(needsBy!),
        'deliveryRequired': deliveryRequired,
        'status': status.value,
        'offersCount': offersCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'acceptedAt':
            acceptedAt == null ? null : Timestamp.fromDate(acceptedAt!),
        'cancelledAt':
            cancelledAt == null ? null : Timestamp.fromDate(cancelledAt!),
        'acceptedOfferId': acceptedOfferId,
        'resultingOrderId': resultingOrderId,
      };

  FishRequestModel copyWith({
    String? requestId,
    String? buyerId,
    FishType? fishType,
    String? customFishName,
    double? quantityKg,
    double? maxPricePerKg,
    String? notes,
    String? regionName,
    String? marketName,
    DateTime? needsBy,
    bool? deliveryRequired,
    FishRequestStatus? status,
    int? offersCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? cancelledAt,
    String? acceptedOfferId,
    String? resultingOrderId,
  }) {
    return FishRequestModel(
      requestId: requestId ?? this.requestId,
      buyerId: buyerId ?? this.buyerId,
      fishType: fishType ?? this.fishType,
      customFishName: customFishName ?? this.customFishName,
      quantityKg: quantityKg ?? this.quantityKg,
      maxPricePerKg: maxPricePerKg ?? this.maxPricePerKg,
      notes: notes ?? this.notes,
      regionName: regionName ?? this.regionName,
      marketName: marketName ?? this.marketName,
      needsBy: needsBy ?? this.needsBy,
      deliveryRequired: deliveryRequired ?? this.deliveryRequired,
      status: status ?? this.status,
      offersCount: offersCount ?? this.offersCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      acceptedOfferId: acceptedOfferId ?? this.acceptedOfferId,
      resultingOrderId: resultingOrderId ?? this.resultingOrderId,
    );
  }
}
