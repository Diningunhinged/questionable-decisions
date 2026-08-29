import '../../../models/nearby_result.dart';
import 'crawl_configuration.dart';
import 'crawl_starting_point.dart';

class SavedCrawl {
  final String id;
  final String name;
  final DateTime plannedDate;
  final CrawlConfiguration configuration;
  final CrawlStartingPoint startingPoint;
  final List<NearbyResult> stops;

  const SavedCrawl({
    required this.id,
    required this.name,
    required this.plannedDate,
    required this.configuration,
    required this.startingPoint,
    required this.stops,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plannedDate': plannedDate.toIso8601String(),
      'configuration': {
        'size': configuration.size.name,
        'categories':
            configuration.categories.map((category) => category.name).toList(),
        'walkingDistanceMeters': configuration.walkingDistanceMeters,
        'distanceUnit': configuration.distanceUnit.name,
      },
      'startingPoint': {
        'name': startingPoint.name,
        'latitude': startingPoint.latitude,
        'longitude': startingPoint.longitude,
      },
      'stops': stops.map(_nearbyResultToJson).toList(),
    };
  }

  factory SavedCrawl.fromJson(Map<String, dynamic> json) {
    final configurationJson =
        (json['configuration'] as Map?)?.cast<String, dynamic>() ?? {};

    final startingPointJson =
        (json['startingPoint'] as Map?)?.cast<String, dynamic>() ?? {};

    final categories = <CrawlCategory>{};
    final rawCategories = configurationJson['categories'];

    if (rawCategories is List) {
      for (final value in rawCategories) {
        final name = value.toString();
        for (final category in CrawlCategory.values) {
          if (category.name == name) {
            categories.add(category);
            break;
          }
        }
      }
    }

    if (categories.isEmpty) {
      categories.add(CrawlCategory.anyCategory);
    }

    final size = CrawlSize.values.firstWhere(
      (value) => value.name == configurationJson['size'],
      orElse: () => CrawlSize.questionable,
    );

    final distanceUnit = DistanceUnit.values.firstWhere(
      (value) => value.name == configurationJson['distanceUnit'],
      orElse: () => DistanceUnit.metric,
    );

    final rawStops = json['stops'];

    return SavedCrawl(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? 'Unnamed Crawl',
      plannedDate: DateTime.tryParse(
            json['plannedDate']?.toString() ?? '',
          ) ??
          DateTime.now(),
      configuration: CrawlConfiguration(
        size: size,
        categories: categories,
        walkingDistanceMeters:
            (configurationJson['walkingDistanceMeters'] as num?)?.toDouble() ??
                2000,
        distanceUnit: distanceUnit,
      ),
      startingPoint: CrawlStartingPoint(
        name: startingPointJson['name']?.toString() ?? 'Starting Point',
        latitude:
            (startingPointJson['latitude'] as num?)?.toDouble() ?? 0,
        longitude:
            (startingPointJson['longitude'] as num?)?.toDouble() ?? 0,
      ),
      stops: rawStops is List
          ? rawStops
              .whereType<Map>()
              .map(
                (value) =>
                    _nearbyResultFromJson(value.cast<String, dynamic>()),
              )
              .toList()
          : const [],
    );
  }
}

Map<String, dynamic> _nearbyResultToJson(NearbyResult result) {
  return {
    'type': result.type,
    'category': result.category,
    'title': result.title,
    'slug': result.slug,
    'rating': result.rating,
    'heroImage': result.heroImage,
    'distanceKm': result.distanceKm,
    'venue': {
      'name': result.venue.name,
      'city': result.venue.city,
      'province': result.venue.province,
      'cuisine': result.venue.cuisine,
      'featured': result.venue.featured,
      'googleMaps': result.venue.googleMaps,
      'location': result.venue.location == null
          ? null
          : {
              'lat': result.venue.location!.latitude,
              'lng': result.venue.location!.longitude,
            },
    },
  };
}

NearbyResult _nearbyResultFromJson(Map<String, dynamic> json) {
  final result = NearbyResult.fromJson(json);
  final distance = (json['distanceKm'] as num?)?.toDouble();
  result.distanceKm = distance;
  return result;
}
