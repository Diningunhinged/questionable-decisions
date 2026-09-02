// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

class DiningUnhingedReview {
  const DiningUnhingedReview({
    required this.reviewId,
    required this.title,
    required this.slug,
    required this.venueType,
    required this.rating,
    required this.venueId,
    required this.venueName,
    required this.city,
    required this.province,
    required this.country,
    required this.address,
    required this.cuisine,
    required this.priceRange,
    required this.featured,
    required this.googleMaps,
    required this.latitude,
    required this.longitude,
  });

  final String reviewId;
  final String title;
  final String? slug;
  final String? venueType;
  final double? rating;

  final String? venueId;
  final String? venueName;
  final String? city;
  final String? province;
  final String? country;
  final String? address;
  final String? cuisine;
  final String? priceRange;
  final bool? featured;
  final String? googleMaps;

  final double latitude;
  final double longitude;

  factory DiningUnhingedReview.fromJson(
    Map<String, dynamic> json,
  ) {
    final venue =
        json['venue'] is Map<String, dynamic>
            ? json['venue'] as Map<String, dynamic>
            : const <String, dynamic>{};

    final location =
        venue['location'] is Map<String, dynamic>
            ? venue['location'] as Map<String, dynamic>
            : const <String, dynamic>{};

    return DiningUnhingedReview(
      reviewId:
          json['reviewId']?.toString().trim() ?? '',
      title:
          json['title']?.toString().trim() ?? '',
      slug: _stringOrNull(json['slug']),
      venueType:
          _stringOrNull(json['venueType']),
      rating: _doubleOrNull(json['rating']),
      venueId:
          _stringOrNull(venue['id']),
      venueName:
          _stringOrNull(venue['name']),
      city:
          _stringOrNull(venue['city']),
      province:
          _stringOrNull(venue['province']),
      country:
          _stringOrNull(venue['country']),
      address:
          _stringOrNull(venue['address']),
      cuisine:
          _stringOrNull(venue['cuisine']),
      priceRange:
          _stringOrNull(venue['priceRange']),
      featured:
          venue['featured'] is bool
              ? venue['featured'] as bool
              : null,
      googleMaps:
          _stringOrNull(venue['googleMaps']),
      latitude:
          _doubleOrNull(location['lat']) ?? 0,
      longitude:
          _doubleOrNull(location['lng']) ?? 0,
    );
  }

  bool get isValid =>
      reviewId.isNotEmpty &&
      venueName != null &&
      venueName!.isNotEmpty &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  static String? _stringOrNull(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static double? _doubleOrNull(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return null;
    }

    return double.tryParse(
      value.toString(),
    );
  }
}
