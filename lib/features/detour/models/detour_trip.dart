// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'detour_endpoint.dart';
import 'detour_route.dart';
import 'detour_venue.dart';

class DetourTrip {
  const DetourTrip({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.start,
    required this.destination,
    required this.stops,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
    this.routeGeometry = const [],
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Starting point for the trip.
  final DetourEndpoint start;

  /// Final destination for the trip.
  final DetourEndpoint destination;

  /// Ordered stops selected for this trip.
  ///
  /// V1 maximum: 5 stops.
  final List<DetourVenue> stops;

  /// Last calculated Google route distance.
  ///
  /// This is a cached route result, not the source
  /// of truth for the trip.
  final double? routeDistanceMeters;

  /// Last calculated Google route duration.
  ///
  /// This is a cached route result, not the source
  /// of truth for the trip.
  final double? routeDurationSeconds;

  /// Last calculated Google route geometry.
  ///
  /// Each point is:
  /// [latitude, longitude]
  final List<List<double>> routeGeometry;

  /// V1 maximum number of stops.
  static const int maxStops = 5;

  bool get isValid {
    if (id.trim().isEmpty) {
      return false;
    }

    if (!start.isValid || !destination.isValid) {
      return false;
    }

    if (stops.length > maxStops) {
      return false;
    }

    if (routeDistanceMeters != null &&
        routeDistanceMeters! < 0) {
      return false;
    }

    if (routeDurationSeconds != null &&
        routeDurationSeconds! < 0) {
      return false;
    }

    for (final stop in stops) {
      if (!stop.isValid) {
        return false;
      }
    }

    for (final point in routeGeometry) {
      if (point.length != 2) {
        return false;
      }

      final latitude = point[0];
      final longitude = point[1];

      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        return false;
      }
    }

    return true;
  }

  /// Returns the cached route as a DetourRoute when
  /// a valid route has been persisted.
  DetourRoute? get cachedRoute {
    final distance = routeDistanceMeters;
    final duration = routeDurationSeconds;

    if (distance == null ||
        duration == null ||
        routeGeometry.isEmpty) {
      return null;
    }

    final route = DetourRoute(
      distanceMeters: distance,
      durationSeconds: duration,
      geometry: routeGeometry,
    );

    return route.isValid ? route : null;
  }

  DetourTrip copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DetourEndpoint? start,
    DetourEndpoint? destination,
    List<DetourVenue>? stops,
    double? routeDistanceMeters,
    double? routeDurationSeconds,
    List<List<double>>? routeGeometry,
    bool clearCachedRoute = false,
  }) {
    return DetourTrip(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      start: start ?? this.start,
      destination:
          destination ?? this.destination,
      stops: stops ?? this.stops,
      routeDistanceMeters:
          clearCachedRoute
              ? null
              : routeDistanceMeters ??
                  this.routeDistanceMeters,
      routeDurationSeconds:
          clearCachedRoute
              ? null
              : routeDurationSeconds ??
                  this.routeDurationSeconds,
      routeGeometry:
          clearCachedRoute
              ? const []
              : routeGeometry ??
                  this.routeGeometry,
    );
  }

  /// Creates a trip containing the current
  /// calculated route.
  factory DetourTrip.fromRoute({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DetourEndpoint start,
    required DetourEndpoint destination,
    required List<DetourVenue> stops,
    required DetourRoute route,
  }) {
    return DetourTrip(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      start: start,
      destination: destination,
      stops: List<DetourVenue>.from(stops),
      routeDistanceMeters:
          route.distanceMeters,
      routeDurationSeconds:
          route.durationSeconds,
      routeGeometry: route.geometry
          .map(
            (point) => List<double>.from(point),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt':
          createdAt.toIso8601String(),
      'updatedAt':
          updatedAt.toIso8601String(),
      'start': start.toJson(),
      'destination':
          destination.toJson(),
      'stops': stops
          .map(
            (stop) => _venueToJson(stop),
          )
          .toList(),
      'routeDistanceMeters':
          routeDistanceMeters,
      'routeDurationSeconds':
          routeDurationSeconds,
      'routeGeometry': routeGeometry
          .map(
            (point) =>
                List<double>.from(point),
          )
          .toList(),
    };
  }

  factory DetourTrip.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawStart = json['start'];
    final rawDestination =
        json['destination'];
    final rawStops = json['stops'];
    final rawGeometry =
        json['routeGeometry'];

    final start =
        rawStart is Map
            ? DetourEndpoint.fromJson(
                rawStart.cast<
                    String,
                    dynamic>(),
              )
            : const DetourEndpoint(
                name: '',
                latitude: 0,
                longitude: 0,
              );

    final destination =
        rawDestination is Map
            ? DetourEndpoint.fromJson(
                rawDestination.cast<
                    String,
                    dynamic>(),
              )
            : const DetourEndpoint(
                name: '',
                latitude: 0,
                longitude: 0,
              );

    final stops = <DetourVenue>[];

    if (rawStops is List) {
      for (final value in rawStops) {
        if (value is Map) {
          final venue =
              _venueFromJson(
            value.cast<
                String,
                dynamic>(),
          );

          if (venue.isValid) {
            stops.add(venue);
          }
        }
      }
    }

    final geometry =
        <List<double>>[];

    if (rawGeometry is List) {
      for (final value in rawGeometry) {
        if (value is List &&
            value.length == 2 &&
            value[0] is num &&
            value[1] is num) {
          geometry.add([
            (value[0] as num).toDouble(),
            (value[1] as num).toDouble(),
          ]);
        }
      }
    }

    DateTime parseDate(
      dynamic value,
    ) {
      final parsed =
          DateTime.tryParse(
        value?.toString() ?? '',
      );

      return parsed ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
          );
    }

    final trip = DetourTrip(
      id: json['id']?.toString() ?? '',
      createdAt: parseDate(
        json['createdAt'],
      ),
      updatedAt: parseDate(
        json['updatedAt'],
      ),
      start: start,
      destination: destination,
      stops: stops
          .take(maxStops)
          .toList(),
      routeDistanceMeters:
          (json['routeDistanceMeters']
                  as num?)
              ?.toDouble(),
      routeDurationSeconds:
          (json['routeDurationSeconds']
                  as num?)
              ?.toDouble(),
      routeGeometry: geometry,
    );

    return trip;
  }

  static Map<String, dynamic> _venueToJson(
    DetourVenue venue,
  ) {
    return {
      'placeId': venue.placeId,
      'name': venue.name,
      'address': venue.address,
      'latitude': venue.latitude,
      'longitude': venue.longitude,
      'primaryType': venue.primaryType,
      'types': venue.types,
      'isOpenNow': venue.isOpenNow,
      'diningUnhingedRating':
          venue.diningUnhingedRating,
      'diningUnhingedReviewId':
          venue.diningUnhingedReviewId,
      'diningUnhingedSlug':
          venue.diningUnhingedSlug,
    };
  }

  static DetourVenue _venueFromJson(
    Map<String, dynamic> json,
  ) {
    final rawTypes = json['types'];

    return DetourVenue(
      placeId:
          json['placeId']?.toString() ?? '',
      name:
          json['name']?.toString() ?? '',
      address:
          json['address']?.toString(),
      latitude:
          (json['latitude'] as num?)
                  ?.toDouble() ??
              0,
      longitude:
          (json['longitude'] as num?)
                  ?.toDouble() ??
              0,
      primaryType:
          json['primaryType']?.toString(),
      types: rawTypes is List
          ? rawTypes
              .whereType<String>()
              .toList()
          : const [],
      isOpenNow:
          json['isOpenNow'] as bool?,
      diningUnhingedRating:
          (json['diningUnhingedRating']
                  as num?)
              ?.toDouble(),
      diningUnhingedReviewId:
          json['diningUnhingedReviewId']
              ?.toString(),
      diningUnhingedSlug:
          json['diningUnhingedSlug']
              ?.toString(),
    );
  }
}
