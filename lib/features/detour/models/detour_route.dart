class DetourRoute {
  const DetourRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
  });

  /// Total driving distance for the calculated route.
  final double distanceMeters;

  /// Estimated driving time for the calculated route.
  final double durationSeconds;

  /// Ordered route geometry.
  ///
  /// Each point is represented as:
  /// [latitude, longitude]
  ///
  /// The geometry is intentionally kept provider-neutral so the
  /// routing provider can change later without affecting Detour.
  final List<List<double>> geometry;

  double get distanceKilometers =>
      distanceMeters / 1000;

  double get durationMinutes =>
      durationSeconds / 60;

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

    return true;
  }

  DetourRoute copyWith({
    double? distanceMeters,
    double? durationSeconds,
    List<List<double>>? geometry,
  }) {
    return DetourRoute(
      distanceMeters:
          distanceMeters ?? this.distanceMeters,
      durationSeconds:
          durationSeconds ?? this.durationSeconds,
      geometry:
          geometry ?? this.geometry,
    );
  }
}