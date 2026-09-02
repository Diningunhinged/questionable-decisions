// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import '../models/detour_route.dart';
import '../models/detour_venue.dart';
import '../models/detour_preferences.dart';
import '../models/dining_unhinged_review.dart';
import 'detour_route_geometry_service.dart';
import 'dining_unhinged_review_service.dart';
import 'google_places_provider.dart';

class DetourCandidateService {
  const DetourCandidateService({
    required this.placesProvider,
    required this.diningUnhingedReviewService,
    this.geometryService =
        const DetourRouteGeometryService(),
  });

  final GooglePlacesProvider placesProvider;
  final DiningUnhingedReviewService
      diningUnhingedReviewService;
  final DetourRouteGeometryService geometryService;

  Future<List<DetourVenue>> findCandidates({
    required DetourRoute route,
    required DetourPreferences preferences,
  }) async {
    if (route.geometry.isEmpty) {
      return const [];
    }

    final includedTypes =
        _googlePlaceTypes(preferences);

    if (includedTypes.isEmpty) {
      return const [];
    }

    /*
     * Dining Unhinged is the authoritative source
     * for Dining Unhinged-reviewed venues.
     *
     * Google Places is used to discover additional
     * venues that may not have a Dining Unhinged
     * review.
     */
    final diningUnhingedReviews =
        await diningUnhingedReviewService
            .fetchReviews();

    final venuesById =
        <String, DetourVenue>{};

    /*
     * --------------------------------------------------
     * 1. ADD DINING UNHINGED VENUES DIRECTLY
     * --------------------------------------------------
     *
     * We do not depend on Google Places discovering
     * our reviewed venues.
     *
     * This is important because a venue can exist in
     * Dining Unhinged/Sanity while Google Places may
     * not return it in a particular nearby search.
     */
    for (final review
        in diningUnhingedReviews) {
      if (!review.isValid) {
        continue;
      }

      final venue =
          _venueFromDiningUnhingedReview(
        review,
      );

      if (!venue.isValid) {
        continue;
      }

      if (!_passesFilters(
        venue,
        preferences,
      )) {
        continue;
      }

      if (!_isWithinSearchCorridor(
        venue,
        route,
        preferences,
      )) {
        continue;
      }

      venuesById[venue.placeId] = venue;
    }

    /*
     * --------------------------------------------------
     * 2. DISCOVER ADDITIONAL GOOGLE PLACES
     * --------------------------------------------------
     *
     * Google Places remains the discovery source for
     * venues that Dining Unhinged has not reviewed.
     */
    final searchPoints =
        geometryService.sampleRoute(
      geometry: route.geometry,
      spacingMeters:
          _searchSpacingMeters(preferences),
    );

    for (final point in searchPoints) {
      final venues =
          await placesProvider.searchNearby(
        latitude: point[0],
        longitude: point[1],
        radiusMeters:
            _searchRadiusMeters(preferences),
        includedTypes: includedTypes,
        maxResultCount: 20,
      );

      for (final venue in venues) {
        if (!venue.isValid) {
          continue;
        }

        final matchedReview =
            diningUnhingedReviewService.findMatch(
          venue: venue,
          reviews: diningUnhingedReviews,
        );

        final enrichedVenue =
            venue.withDiningUnhingedReview(
          rating: matchedReview?.rating,
          reviewId:
              matchedReview?.reviewId,
          slug:
              matchedReview?.slug,
        );

        if (!_passesFilters(
          enrichedVenue,
          preferences,
        )) {
          continue;
        }

        if (!_isWithinSearchCorridor(
          enrichedVenue,
          route,
          preferences,
        )) {
          continue;
        }

        /*
         * If this Google venue corresponds to a
         * Dining Unhinged venue already added above,
         * replace the synthetic DU candidate with the
         * real Google Places identity.
         *
         * This gives the UI the actual Google Place ID
         * while preserving the DU review information.
         */
        final existing =
            venuesById.values.where(
          (existingVenue) =>
              existingVenue
                  .diningUnhingedReviewId ==
              enrichedVenue
                  .diningUnhingedReviewId,
        );

        if (existing.isNotEmpty) {
          final existingVenue =
              existing.first;

          venuesById.remove(
            existingVenue.placeId,
          );
        }

        venuesById[
          enrichedVenue.placeId
        ] = enrichedVenue;
      }
    }

    final candidates =
        venuesById.values.toList();

    /*
     * --------------------------------------------------
     * 3. RANK CANDIDATES
     * --------------------------------------------------
     *
     * Priority:
     *
     *   1. Dining Unhinged reviewed venues
     *   2. Higher Dining Unhinged rating
     *   3. Distance to route
     *
     * Google-only venues come after all reviewed
     * Dining Unhinged venues.
     */
    candidates.sort(
  (first, second) {
    final firstHasDiningUnhingedRating =
        first.diningUnhingedRating != null;

    final secondHasDiningUnhingedRating =
        second.diningUnhingedRating != null;

    // Dining Unhinged-reviewed venues always
    // rank ahead of Google-only venues.
    if (firstHasDiningUnhingedRating !=
        secondHasDiningUnhingedRating) {
      return secondHasDiningUnhingedRating
          ? 1
          : -1;
    }

    final firstDistance =
        geometryService.distanceToRouteMeters(
      geometry: route.geometry,
      latitude: first.latitude,
      longitude: first.longitude,
    );

    final secondDistance =
        geometryService.distanceToRouteMeters(
      geometry: route.geometry,
      latitude: second.latitude,
      longitude: second.longitude,
    );

    // For Detour, route proximity comes before
    // rating. A venue shouldn't be ranked higher
    // simply because it has a better review if it
    // requires substantially more deviation.
    final distanceComparison =
        firstDistance.compareTo(
      secondDistance,
    );

    if (distanceComparison != 0) {
      return distanceComparison;
    }

    // If two venues are similarly close to the
    // route, use Dining Unhinged rating as the
    // tiebreaker.
    final firstRating =
        first.diningUnhingedRating ?? 0;

    final secondRating =
        second.diningUnhingedRating ?? 0;

    return secondRating.compareTo(
      firstRating,
    );
  },
);

    return candidates;
  }

  DetourVenue _venueFromDiningUnhingedReview(
    DiningUnhingedReview review,
  ) {
    /*
     * Dining Unhinged reviews do not contain a Google
     * Places ID, so create a stable internal identity
     * from the review ID.
     *
     * If Google Places later discovers the same venue,
     * the Google Places version replaces this candidate.
     */
    final placeId =
        'dining-unhinged:${review.reviewId}';

    return DetourVenue(
      placeId: placeId,
      name:
          review.venueName ??
          review.title,
      address: review.address,
      latitude: review.latitude,
      longitude: review.longitude,
      primaryType:
          _reviewVenueTypeToGoogleType(
        review.venueType,
      ),
      types: const [],
      isOpenNow: null,
      diningUnhingedRating:
          review.rating,
      diningUnhingedReviewId:
          review.reviewId,
      diningUnhingedSlug:
          review.slug,
    );
  }

  String? _reviewVenueTypeToGoogleType(
    String? venueType,
  ) {
    switch (
        venueType?.trim().toLowerCase()) {
      case 'restaurant':
        return 'restaurant';

      case 'brewery':
        return 'brewery';

      case 'bar':
        return 'bar';

      case 'cocktail bar':
      case 'cocktail':
        return 'cocktail_bar';

      case 'cafÃƒÂ©':
      case 'cafe':
        return 'cafe';

      case 'distillery':
        return 'bar';

      default:
        return null;
    }
  }

  bool _passesFilters(
    DetourVenue venue,
    DetourPreferences preferences,
  ) {
    final rating =
        venue.diningUnhingedRating;

    /*
     * If a minimum Dining Unhinged rating has
     * been requested, an unreviewed venue does
     * not qualify.
     *
     * We never substitute Google's rating.
     */
    if (rating == null &&
        preferences.minimumRating > 0) {
      return false;
    }

    if (rating != null &&
        rating < preferences.minimumRating) {
      return false;
    }

    /*
     * Dining Unhinged-created candidates don't
     * have Google opening-hours data, so only
     * enforce this filter when opening status
     * is actually known.
     */
    if (preferences.openNowOnly &&
        venue.isOpenNow != null &&
        venue.isOpenNow != true) {
      return false;
    }

    if (preferences.openNowOnly &&
        venue.isOpenNow == null &&
        venue.diningUnhingedReviewId == null) {
      return false;
    }

    if (!_matchesPreferredCategory(
      venue,
      preferences,
    )) {
      return false;
    }

    return true;
  }

  bool _matchesPreferredCategory(
    DetourVenue venue,
    DetourPreferences preferences,
  ) {
    if (preferences.preferredCategories.isEmpty) {
      return true;
    }

    final requestedTypes =
        preferences.preferredCategories
            .map(_categoryToGoogleType)
            .whereType<String>()
            .toSet();

    if (requestedTypes.isEmpty) {
      return true;
    }

    final venueTypes =
        venue.types.toSet();

    if (venue.primaryType != null) {
      venueTypes.add(
        venue.primaryType!,
      );
    }

    /*
     * For Dining Unhinged-only candidates,
     * use their review venue type when Google
     * type information isn't available.
     */
    if (venue.diningUnhingedReviewId !=
            null &&
        venue.primaryType != null) {
      return requestedTypes.contains(
        venue.primaryType,
      );
    }

    return requestedTypes.any(
      venueTypes.contains,
    );
  }

  List<String> _googlePlaceTypes(
    DetourPreferences preferences,
  ) {
    if (preferences.preferredCategories.isEmpty) {
      return const [
        'restaurant',
        'cafe',
        'bar',
        'brewery',
        'winery',
      ];
    }

    return preferences.preferredCategories
        .map(_categoryToGoogleType)
        .whereType<String>()
        .toSet()
        .toList();
  }

  String? _categoryToGoogleType(
    String category,
  ) {
    switch (category.trim().toLowerCase()) {
      case 'restaurant':
        return 'restaurant';

      case 'brewery':
        return 'brewery';

      case 'bar':
        return 'bar';

      case 'cocktail':
      case 'cocktail bar':
        return 'cocktail_bar';

      case 'cafÃƒÂ©':
      case 'cafÃƒÆ’Ã‚Â©':
      case 'cafe':
        return 'cafe';

      case 'distillery':
        return 'bar';

      default:
        return null;
    }
  }

  /*
   * This is currently the geographic search corridor
   * used by Detour.
   *
   * It is intentionally NOT described as actual
   * driving detour distance. Calculating true driving
   * detour distance would require additional Routes
   * API calls for each candidate.
   */
  bool _isWithinSearchCorridor(
    DetourVenue venue,
    DetourRoute route,
    DetourPreferences preferences,
  ) {
    final distanceToRoute =
        geometryService.distanceToRouteMeters(
      geometry: route.geometry,
      latitude: venue.latitude,
      longitude: venue.longitude,
    );

    final maximumDetourMeters =
        preferences.maximumDetourKm *
            1000;

    return distanceToRoute <=
        maximumDetourMeters;
  }

  double _searchSpacingMeters(
    DetourPreferences preferences,
  ) {
    final maximumDetour =
        preferences.maximumDetourKm;

    if (maximumDetour <= 5) {
      return 3000;
    }

    if (maximumDetour <= 15) {
      return 5000;
    }

    if (maximumDetour <= 30) {
      return 7500;
    }

    return 10000;
  }

  double _searchRadiusMeters(
    DetourPreferences preferences,
  ) {
    final maximumDetour =
        preferences.maximumDetourKm;

    if (maximumDetour <= 5) {
      return 2500;
    }

    if (maximumDetour <= 15) {
      return 5000;
    }

    if (maximumDetour <= 30) {
      return 7500;
    }

    return 10000;
  }
}
