// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import '../models/detour_endpoint.dart';
import '../models/detour_route.dart';

abstract class RoutingProvider {
  Future<DetourRoute> calculateRoute({
    required DetourEndpoint start,
    required DetourEndpoint destination,
    List<DetourEndpoint> waypoints = const [],
    bool optimizeWaypointOrder = true,
  });
}
