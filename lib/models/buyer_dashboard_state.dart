// Immutable view-model for the Buyer Dashboard. Plain Dart class (not freezed)
// because:
//   1. It composes three other models and we want field-level control over
//      identity equality (e.g. two empty states should be `==`).
//   2. Phase 1 doesn't need code generation for this file.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'fish_item_model.dart';
import 'fish_request_model.dart';
import 'street_seller_model.dart';
import '../utils/timestamp_converter.dart';

class RecentSearch {
  final String query;
  final DateTime searchedAt;
  final int resultCount;

  const RecentSearch({
    required this.query,
    required this.searchedAt,
    this.resultCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'query': query,
        'searchedAt': Timestamp.fromDate(searchedAt),
        'resultCount': resultCount,
      };

  factory RecentSearch.fromMap(Map<String, dynamic> data) => RecentSearch(
        query: (data['query'] as String?) ?? '',
        searchedAt: const OptionalTimestampConverter()
                .fromJson(data['searchedAt']) ??
            DateTime.now(),
        resultCount: (data['resultCount'] as num?)?.toInt() ?? 0,
      );
}

class BuyerDashboardState {
  /// The buyer this state belongs to. Used to enforce session isolation —
  /// if the current auth user changes, providers above invalidate this.
  final String buyerId;

  /// Fish available *near the buyer*, broker-approved and in stock. Already
  /// filtered through [FishItemModel.isBuyable].
  final List<FishItemModel> fishAvailableNearby;

  /// All active FishRequests owned by this buyer.
  final List<FishRequestModel> activeRequests;

  /// Recent search history (most recent first, capped at 10).
  final List<RecentSearch> recentSearches;

  /// Buyer's last known location (used for "nearby" filter).
  final double? buyerLatitude;
  final double? buyerLongitude;

  /// Cached list of street sellers (used for distance computation + lookup).
  final List<StreetSellerModel> nearbySellers;

  /// Loading / error signals for the summary card.
  final bool isLoading;
  final String? error;

  const BuyerDashboardState({
    required this.buyerId,
    this.fishAvailableNearby = const [],
    this.activeRequests = const [],
    this.recentSearches = const [],
    this.buyerLatitude,
    this.buyerLongitude,
    this.nearbySellers = const [],
    this.isLoading = false,
    this.error,
  });

  /// Empty seed state for a freshly-authenticated buyer.
  factory BuyerDashboardState.empty(String buyerId) =>
      BuyerDashboardState(buyerId: buyerId);

  bool get hasLocation => buyerLatitude != null && buyerLongitude != null;

  int get fishCount => fishAvailableNearby.length;
  int get activeRequestCount =>
      activeRequests.where((r) => r.countsAsActive).length;

  BuyerDashboardState copyWith({
    String? buyerId,
    List<FishItemModel>? fishAvailableNearby,
    List<FishRequestModel>? activeRequests,
    List<RecentSearch>? recentSearches,
    double? buyerLatitude,
    double? buyerLongitude,
    List<StreetSellerModel>? nearbySellers,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearLocation = false,
  }) {
    return BuyerDashboardState(
      buyerId: buyerId ?? this.buyerId,
      fishAvailableNearby: fishAvailableNearby ?? this.fishAvailableNearby,
      activeRequests: activeRequests ?? this.activeRequests,
      recentSearches: recentSearches ?? this.recentSearches,
      buyerLatitude:
          clearLocation ? null : (buyerLatitude ?? this.buyerLatitude),
      buyerLongitude:
          clearLocation ? null : (buyerLongitude ?? this.buyerLongitude),
      nearbySellers: nearbySellers ?? this.nearbySellers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Used by tests / debug tooling to detect a stale state — if the buyerId
  /// on the state doesn't match the current auth user, the provider will
  /// reject the update.
  bool belongsTo(String currentBuyerId) => buyerId == currentBuyerId;
}
