// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import '../models/detour_endpoint.dart';
import '../models/detour_route.dart';
import 'routing_provider.dart';

class DetourRouteService {
  const DetourRouteService({
    required this._provider,
  });

  final RoutingProvider _provider;

  Future<DetourRoute> calculateRoute({
    required DetourEndpoint start,
    required DetourEndpoint destination,
  }) async {
    if (!start.isValid) {
      throw const DetourRouteException(
        'The starting location is invalid.',
      );
    }

    if (!destination.isValid) {
      throw const DetourRouteException(
        'The destination is invalid.',
      );
    }

    if (_sameCoordinates(start, destination)) {
      throw const DetourRouteException(
        'The starting location and destination cannot be the same.',
      );
    }

    final route = await _provider.calculateRoute(
      start: start,
      destination: destination,
    );

    if (!route.isValid) {
      throw const DetourRouteException(
        'The routing provider returned an invalid route.',
      );
    }

    return route;
  }

  bool _sameCoordinates(
    DetourEndpoint first,
    DetourEndpoint second,
  ) {
    return (first.latitude - second.latitude).abs() <
            0.00001 &&
        (first.longitude - second.longitude).abs() <
            0.00001;
  }
}

class DetourRouteException implements Exception {
  const DetourRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}
