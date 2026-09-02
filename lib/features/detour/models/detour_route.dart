// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

class DetourRoute {
  const DetourRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    this.optimizedWaypointIndices = const [],
  });

  /// Total driving distance for the calculated route.
  final double distanceMeters;

  /// Estimated driving time for the calculated route.
  final double durationSeconds;

  /// Ordered route geometry.
  ///
  /// Each point is represented as:
  /// [latitude, longitude]
  final List<List<double>> geometry;

  /// Zero-based indexes representing Google's optimized
  /// order of the intermediate waypoints.
  ///
  /// For example:
  ///
  /// Input:
  /// [A, B, C]
  ///
  /// Google result:
  /// [2, 0, 1]
  ///
  /// means:
  /// C Ã¢â€ â€™ A Ã¢â€ â€™ B
  ///
  /// Empty when no waypoint optimization was requested.
  final List<int> optimizedWaypointIndices;

  double get distanceKilometers =>
      distanceMeters / 1000;

  double get durationMinutes =>
      durationSeconds / 60;

  bool get hasOptimizedWaypointOrder =>
      optimizedWaypointIndices.isNotEmpty;

  bool get isValid {
    if (distanceMeters < 0 ||
        durationSeconds < 0 ||
        geometry.isEmpty) {
      return false;
    }

    for (final point in geometry) {
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

    if (optimizedWaypointIndices.isNotEmpty) {
      final sortedIndices =
          [...optimizedWaypointIndices]..sort();

      for (var index = 0;
          index < sortedIndices.length;
          index++) {
        if (sortedIndices[index] != index) {
          return false;
        }
      }
    }

    return true;
  }

  DetourRoute copyWith({
    double? distanceMeters,
    double? durationSeconds,
    List<List<double>>? geometry,
    List<int>? optimizedWaypointIndices,
  }) {
    return DetourRoute(
      distanceMeters:
          distanceMeters ?? this.distanceMeters,
      durationSeconds:
          durationSeconds ?? this.durationSeconds,
      geometry:
          geometry ?? this.geometry,
      optimizedWaypointIndices:
          optimizedWaypointIndices ??
              this.optimizedWaypointIndices,
    );
  }
}
