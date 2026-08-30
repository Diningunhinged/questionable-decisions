import 'dart:math' as math;

class DetourRouteGeometryService {
  const DetourRouteGeometryService();

  /// Returns points sampled along a route.
  ///
  /// [geometry] must contain points in the form:
  /// [latitude, longitude]
  ///
  /// [spacingMeters] controls the approximate distance between
  /// sampled points.
  ///
  /// The first and last route points are always included.
  List<List<double>> sampleRoute({
    required List<List<double>> geometry,
    double spacingMeters = 5000,
  }) {
    if (geometry.isEmpty) {
      return const [];
    }

    if (spacingMeters <= 0) {
      throw ArgumentError(
        'spacingMeters must be greater than zero.',
      );
    }

    final validGeometry = geometry
        .where(_isValidPoint)
        .map(
          (point) => <double>[
            point[0],
            point[1],
          ],
        )
        .toList();

    if (validGeometry.isEmpty) {
      return const [];
    }

    if (validGeometry.length == 1) {
      return [
        validGeometry.first,
      ];
    }

    final sampledPoints = <List<double>>[
      validGeometry.first,
    ];

    var distanceSinceLastSample = 0.0;

    for (var index = 1;
        index < validGeometry.length;
        index++) {
      final previous = validGeometry[index - 1];
      final current = validGeometry[index];

      final segmentDistance = distanceMeters(
        latitude1: previous[0],
        longitude1: previous[1],
        latitude2: current[0],
        longitude2: current[1],
      );

      if (segmentDistance <= 0) {
        continue;
      }

      var segmentStart = previous;
      var remainingSegmentDistance = segmentDistance;

      while (distanceSinceLastSample +
              remainingSegmentDistance >=
          spacingMeters) {
        final distanceToSample =
            spacingMeters - distanceSinceLastSample;

        final fraction =
            distanceToSample /
            remainingSegmentDistance;

        final sampledPoint = _interpolate(
          segmentStart,
          current,
          fraction,
        );

        sampledPoints.add(sampledPoint);

        segmentStart = sampledPoint;

        remainingSegmentDistance -=
            distanceToSample;

        distanceSinceLastSample = 0;
      }

      distanceSinceLastSample +=
          remainingSegmentDistance;
    }

    final lastPoint = validGeometry.last;

    if (!_samePoint(
      sampledPoints.last,
      lastPoint,
    )) {
      sampledPoints.add(lastPoint);
    }

    return sampledPoints;
  }

  /// Calculates the great-circle distance between two
  /// latitude/longitude points using the Haversine formula.
  double distanceMeters({
    required double latitude1,
    required double longitude1,
    required double latitude2,
    required double longitude2,
  }) {
    const earthRadiusMeters = 6371000.0;

    final latitude1Radians =
        _degreesToRadians(latitude1);
    final latitude2Radians =
        _degreesToRadians(latitude2);

    final deltaLatitude =
        _degreesToRadians(
      latitude2 - latitude1,
    );

    final deltaLongitude =
        _degreesToRadians(
      longitude2 - longitude1,
    );

    final a =
        math.pow(
              math.sin(deltaLatitude / 2),
              2,
            ) +
            math.cos(latitude1Radians) *
                math.cos(latitude2Radians) *
                math.pow(
                  math.sin(deltaLongitude / 2),
                  2,
                );

    final clampedA = a.clamp(0.0, 1.0);

    final c =
        2 *
        math.atan2(
          math.sqrt(clampedA),
          math.sqrt(
            1 - clampedA,
          ),
        );

    return earthRadiusMeters * c;
  }

  /// Returns the closest point on the route to the supplied
  /// latitude/longitude coordinate.
  ///
  /// This is useful later when determining how far a venue
  /// is from the actual route corridor.
  List<double>? closestPointOnRoute({
    required List<List<double>> geometry,
    required double latitude,
    required double longitude,
  }) {
    final validGeometry = geometry
        .where(_isValidPoint)
        .toList();

    if (validGeometry.isEmpty) {
      return null;
    }

    if (validGeometry.length == 1) {
      return [
        validGeometry.first[0],
        validGeometry.first[1],
      ];
    }

    List<double>? closestPoint;
    var closestDistance = double.infinity;

    for (var index = 1;
        index < validGeometry.length;
        index++) {
      final start = validGeometry[index - 1];
      final end = validGeometry[index];

      final candidate = _closestPointOnSegment(
        start,
        end,
        latitude,
        longitude,
      );

      final candidateDistance = distanceMeters(
        latitude1: latitude,
        longitude1: longitude,
        latitude2: candidate[0],
        longitude2: candidate[1],
      );

      if (candidateDistance <
          closestDistance) {
        closestDistance = candidateDistance;
        closestPoint = candidate;
      }
    }

    return closestPoint;
  }

  /// Calculates the minimum straight-line distance from
  /// a coordinate to the supplied route geometry.
  double distanceToRouteMeters({
    required List<List<double>> geometry,
    required double latitude,
    required double longitude,
  }) {
    final closestPoint = closestPointOnRoute(
      geometry: geometry,
      latitude: latitude,
      longitude: longitude,
    );

    if (closestPoint == null) {
      return double.infinity;
    }

    return distanceMeters(
      latitude1: latitude,
      longitude1: longitude,
      latitude2: closestPoint[0],
      longitude2: closestPoint[1],
    );
  }

  List<double> _closestPointOnSegment(
    List<double> start,
    List<double> end,
    double latitude,
    double longitude,
  ) {
    final referenceLatitude =
        _degreesToRadians(latitude);

    final longitudeScale =
        math.cos(referenceLatitude);

    final startX =
        _degreesToRadians(start[1]) *
        longitudeScale;

    final startY =
        _degreesToRadians(start[0]);

    final endX =
        _degreesToRadians(end[1]) *
        longitudeScale;

    final endY =
        _degreesToRadians(end[0]);

    final pointX =
        _degreesToRadians(longitude) *
        longitudeScale;

    final pointY =
        _degreesToRadians(latitude);

    final deltaX = endX - startX;
    final deltaY = endY - startY;

    final segmentLengthSquared =
        deltaX * deltaX +
        deltaY * deltaY;

    if (segmentLengthSquared == 0) {
      return [
        start[0],
        start[1],
      ];
    }

    var t =
        ((pointX - startX) * deltaX +
            (pointY - startY) * deltaY) /
        segmentLengthSquared;

    t = t.clamp(0.0, 1.0);

    final projectedX =
        startX + deltaX * t;

    final projectedY =
        startY + deltaY * t;

    final projectedLatitude =
        _radiansToDegrees(projectedY);

    final projectedLongitude =
        _radiansToDegrees(
          projectedX / longitudeScale,
        );

    return [
      projectedLatitude,
      projectedLongitude,
    ];
  }

  List<double> _interpolate(
    List<double> start,
    List<double> end,
    double fraction,
  ) {
    final clampedFraction =
        fraction.clamp(0.0, 1.0);

    return [
      start[0] +
          (end[0] - start[0]) *
              clampedFraction,
      start[1] +
          (end[1] - start[1]) *
              clampedFraction,
    ];
  }

  bool _isValidPoint(
    List<double> point,
  ) {
    if (point.length < 2) {
      return false;
    }

    final latitude = point[0];
    final longitude = point[1];

    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  bool _samePoint(
    List<double> first,
    List<double> second,
  ) {
    return (first[0] - second[0]).abs() <
            0.000001 &&
        (first[1] - second[1]).abs() <
            0.000001;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees * math.pi / 180;
  }

  double _radiansToDegrees(
    double radians,
  ) {
    return radians * 180 / math.pi;
  }
}