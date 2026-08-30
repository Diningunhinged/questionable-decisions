import '../models/detour_endpoint.dart';
import '../models/detour_route.dart';

abstract class RoutingProvider {
  Future<DetourRoute> calculateRoute({
    required DetourEndpoint start,
    required DetourEndpoint destination,
    List<DetourEndpoint> waypoints = const [],
  });
}