class DetourVenue {
  const DetourVenue({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.primaryType,
    required this.types,
    required this.isOpenNow,
    this.diningUnhingedRating,
    this.diningUnhingedReviewId,
    this.diningUnhingedSlug,
  });

  /// Google Places identifier.
  final String placeId;

  /// Venue name from Google Places.
  final String name;

  /// Venue address from Google Places.
  final String? address;

  /// Venue latitude.
  final double latitude;

  /// Venue longitude.
  final double longitude;

  /// Google Places primary type.
  final String? primaryType;

  /// Google Places place types.
  final List<String> types;

  /// Current opening status from Google Places, when available.
  final bool? isOpenNow;

  /// Dining Unhinged overall rating.
  ///
  /// This is sourced from the Dining Unhinged / Sanity system.
  /// It is intentionally separate from Google Places data.
  final double? diningUnhingedRating;

  /// Sanity restaurantReview document ID, when the venue
  /// has a matching Dining Unhinged review.
  final String? diningUnhingedReviewId;

  /// Dining Unhinged review slug, when the venue
  /// has a matching review.
  final String? diningUnhingedSlug;

  /// Whether this venue has a valid Google Places identity
  /// and geographic location.
  bool get isValid =>
      placeId.trim().isNotEmpty &&
      name.trim().isNotEmpty &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Whether this venue has a Dining Unhinged review.
  bool get hasDiningUnhingedReview =>
      diningUnhingedReviewId != null &&
      diningUnhingedReviewId!.trim().isNotEmpty;

  bool hasType(String type) {
    return types.contains(type) || primaryType == type;
  }

  /// Returns a copy of this venue with Dining Unhinged
  /// review information attached.
  DetourVenue withDiningUnhingedReview({
    required double? rating,
    required String? reviewId,
    required String? slug,
  }) {
    return DetourVenue(
      placeId: placeId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      primaryType: primaryType,
      types: types,
      isOpenNow: isOpenNow,
      diningUnhingedRating: rating,
      diningUnhingedReviewId: reviewId,
      diningUnhingedSlug: slug,
    );
  }
}