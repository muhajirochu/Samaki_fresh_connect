// Result type produced by the buyer's fish-name search.
//
// One [FishSearchResult] is returned per matching fish type; the
// `listings` field groups every active listing of that type from any
// seller, each annotated with its seller distance so the UI can sort
// and render "who has the fish in stock near you".

import 'fish_listing_model.dart';
import 'street_seller_model.dart';

class FishListingWithSeller {
  final FishListingModel listing;
  final StreetSellerModel seller;
  final double distanceKm;

  const FishListingWithSeller({
    required this.listing,
    required this.seller,
    required this.distanceKm,
  });
}

class FishSearchResult {
  final String fishType;

  /// Pretty name — `"Tuna"`, `"Mackerel"`, etc. Falls back to the raw
  /// enum value if the type isn't a known [FishType].
  final String displayName;

  /// Every active listing for this fish type, sorted by distance from
  /// the buyer.
  final List<FishListingWithSeller> listings;

  const FishSearchResult({
    required this.fishType,
    required this.displayName,
    required this.listings,
  });

  /// Sum of `quantityKg` across every listing in this result.
  double get totalKgAvailable =>
      listings.fold(0, (sum, l) => sum + l.listing.quantityKg);

  /// Highest `pricePerKg` across the result. The UI uses this together
  /// with `minPricePerKg` to show a "from X to Y TZS / kg" line.
  double get minPricePerKg => listings
      .map((l) => l.listing.pricePerKg)
      .reduce((a, b) => a < b ? a : b);

  /// Lowest `pricePerKg` across the result.
  double get maxPricePerKg => listings
      .map((l) => l.listing.pricePerKg)
      .reduce((a, b) => a > b ? a : b);

  /// `true` if any seller in the result is currently streaming their
  /// location (so we can show the live badge).
  bool get anyOnline => listings.any((l) => l.seller.isOnline);

  /// Distance in km to the closest seller in the result. The search
  /// screen sorts the result list by this ascending.
  double get closestDistanceKm => listings
      .map((l) => l.distanceKm)
      .reduce((a, b) => a < b ? a : b);

  int get listingCount => listings.length;
}
