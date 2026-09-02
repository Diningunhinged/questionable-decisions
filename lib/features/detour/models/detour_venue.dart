// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

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
    this.isUserSelected = false,
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
  final double? diningUnhingedRating;

  /// Sanity restaurantReview document ID.
  final String? diningUnhingedReviewId;

  /// Dining Unhinged review slug.
  final String? diningUnhingedSlug;

  /// Whether this venue was deliberately added
  /// by the user to the planned route.
  final bool isUserSelected;

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

  DetourVenue copyWith({
    String? placeId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? primaryType,
    List<String>? types,
    bool? isOpenNow,
    double? diningUnhingedRating,
    String? diningUnhingedReviewId,
    String? diningUnhingedSlug,
    bool? isUserSelected,
  }) {
    return DetourVenue(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      primaryType:
          primaryType ?? this.primaryType,
      types: types ?? this.types,
      isOpenNow:
          isOpenNow ?? this.isOpenNow,
      diningUnhingedRating:
          diningUnhingedRating ??
              this.diningUnhingedRating,
      diningUnhingedReviewId:
          diningUnhingedReviewId ??
              this.diningUnhingedReviewId,
      diningUnhingedSlug:
          diningUnhingedSlug ??
              this.diningUnhingedSlug,
      isUserSelected:
          isUserSelected ??
              this.isUserSelected,
    );
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
      isUserSelected: isUserSelected,
    );
  }
}
