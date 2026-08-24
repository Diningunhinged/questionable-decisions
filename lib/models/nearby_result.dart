class NearbyResult {
  final String type;
  final String? category;
  final String title;
  final String slug;
  final double rating;
  final String? heroImage;
  final Venue venue;

  double? distanceKm;

  NearbyResult({
    required this.type,
    required this.category,
    required this.title,
    required this.slug,
    required this.rating,
    required this.heroImage,
    required this.venue,
    this.distanceKm,
  });

  factory NearbyResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return NearbyResult(
      type: json['type'] as String? ?? 'venue',
      category: json['category'] as String?,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      rating:
          (json['rating'] as num?)?.toDouble() ?? 0.0,
      heroImage: json['heroImage'] as String?,
      venue: Venue.fromJson(
        json['venue'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  bool get isDrink => type == 'drink';
}

class Venue {
  final String name;
  final String? city;
  final String? province;
  final String? cuisine;
  final bool featured;
  final String? googleMaps;
  final Location? location;

  const Venue({
    required this.name,
    required this.city,
    required this.province,
    required this.cuisine,
    required this.featured,
    required this.googleMaps,
    required this.location,
  });

  factory Venue.fromJson(
    Map<String, dynamic> json,
  ) {
    return Venue(
      name:
          json['name'] as String? ?? 'Unknown Venue',
      city: json['city'] as String?,
      province: json['province'] as String?,
      cuisine: json['cuisine'] as String?,
      featured:
          json['featured'] as bool? ?? false,
      googleMaps:
          json['googleMaps'] as String?,
      location: json['location'] != null
          ? Location.fromJson(
              json['location']
                  as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class Location {
  final double? latitude;
  final double? longitude;

  const Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(
    Map<String, dynamic> json,
  ) {
    return Location(
      latitude:
          (json['lat'] as num?)?.toDouble(),
      longitude:
          (json['lng'] as num?)?.toDouble(),
    );
  }

  bool get isValid {
    if (latitude == null ||
        longitude == null) {
      return false;
    }

    if (latitude! < -90 ||
        latitude! > 90) {
      return false;
    }

    if (longitude! < -180 ||
        longitude! > 180) {
      return false;
    }

    return true;
  }
}