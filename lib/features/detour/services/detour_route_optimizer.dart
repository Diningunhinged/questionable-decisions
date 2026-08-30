import '../models/detour_endpoint.dart';
import '../models/detour_route.dart';
import '../models/detour_venue.dart';
import 'routing_provider.dart';

class DetourOptimizationResult {
  const DetourOptimizationResult({
    required this.stops,
    required this.route,
  });

  /// Venues in the actual optimized driving order.
  final List<DetourVenue> stops;

  /// The actual route through those stops.
  final DetourRoute route;
}

class DetourRouteOptimizer {
  const DetourRouteOptimizer({
    required this.routingProvider,
  });

  final RoutingProvider routingProvider;

  /// V1 maximum.
  static const int maxStops = 5;

  Future<DetourOptimizationResult> optimize({
    required DetourEndpoint start,
    required DetourEndpoint destination,
    required List<DetourVenue> candidates,
    required int maximumStops,
  }) async {
    if (!start.isValid) {
      throw const DetourRouteOptimizationException(
        'The starting location is invalid.',
      );
    }

    if (!destination.isValid) {
      throw const DetourRouteOptimizationException(
        'The destination is invalid.',
      );
    }

    if (candidates.isEmpty) {
      throw const DetourRouteOptimizationException(
        'No Detour candidates were found.',
      );
    }

    final requestedStops =
        maximumStops.clamp(1, maxStops);

    final validCandidates = candidates
        .where(
          (candidate) => candidate.isValid,
        )
        .toList();

    if (validCandidates.isEmpty) {
      throw const DetourRouteOptimizationException(
        'No valid Detour candidates were found.',
      );
    }

    final shortlist = _buildShortlist(
      validCandidates,
      requestedStops,
    );

    if (shortlist.isEmpty) {
      throw const DetourRouteOptimizationException(
        'No suitable Detour stops were found.',
      );
    }

    final selectedStops =
        shortlist.take(requestedStops).toList();

    final waypoints = selectedStops
        .map(_toEndpoint)
        .toList();

    final route =
        await routingProvider.calculateRoute(
      start: start,
      destination: destination,
      waypoints: waypoints,
    );

    if (!route.isValid) {
      throw const DetourRouteOptimizationException(
        'Google returned an invalid optimized route.',
      );
    }

    final optimizedStops =
        _applyGoogleWaypointOrder(
      selectedStops,
      route.optimizedWaypointIndices,
    );

    return DetourOptimizationResult(
      stops: optimizedStops,
      route: route,
    );
  }

  List<DetourVenue> _buildShortlist(
    List<DetourVenue> candidates,
    int maximumStops,
  ) {
    final reviewed = candidates
        .where(
          (candidate) =>
              candidate.hasDiningUnhingedReview,
        )
        .toList();

    final unreviewed = candidates
        .where(
          (candidate) =>
              !candidate.hasDiningUnhingedReview,
        )
        .toList();

    /*
     * Candidate ranking has already established
     * Dining Unhinged priority.
     *
     * Keep a deliberately small routing shortlist
     * so we don't send a huge number of waypoints
     * to Google.
     */
    final shortlistSize =
        (maximumStops * 3).clamp(5, 15);

    return [
      ...reviewed,
      ...unreviewed,
    ].take(shortlistSize).toList();
  }

  List<DetourVenue> _applyGoogleWaypointOrder(
    List<DetourVenue> originalStops,
    List<int> optimizedIndices,
  ) {
    /*
     * With no intermediate waypoints, Google does not
     * return an optimized order.
     */
    if (originalStops.isEmpty) {
      return const [];
    }

    if (optimizedIndices.isEmpty) {
      return List<DetourVenue>.from(
        originalStops,
      );
    }

    if (optimizedIndices.length !=
        originalStops.length) {
      throw const DetourRouteOptimizationException(
        'Google returned an incomplete '
        'waypoint order.',
      );
    }

    final reordered =
        <DetourVenue>[];

    final usedIndices =
        <int>{};

    for (final index in optimizedIndices) {
      if (index < 0 ||
          index >= originalStops.length) {
        throw const DetourRouteOptimizationException(
          'Google returned an invalid '
          'waypoint index.',
        );
      }

      if (!usedIndices.add(index)) {
        throw const DetourRouteOptimizationException(
          'Google returned duplicate '
          'waypoint indexes.',
        );
      }

      reordered.add(
        originalStops[index],
      );
    }

    if (reordered.length !=
        originalStops.length) {
      throw const DetourRouteOptimizationException(
        'Google returned an invalid '
        'waypoint order.',
      );
    }

    return reordered;
  }

  DetourEndpoint _toEndpoint(
    DetourVenue venue,
  ) {
    return DetourEndpoint(
      name: venue.name,
      address: venue.address,
      latitude: venue.latitude,
      longitude: venue.longitude,
    );
  }
}

class DetourRouteOptimizationException
    implements Exception {
  const DetourRouteOptimizationException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}