import '../models/detour_venue.dart';
import 'google_places_provider.dart';

class DetourVenueSearchService {
  const DetourVenueSearchService({
    required this.provider,
  });

  final GooglePlacesProvider provider;

  Future<List<DetourVenue>> searchNearby({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required List<String> includedTypes,
    int maxResultCount = 20,
  }) {
    return provider.searchNearby(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      includedTypes: includedTypes,
      maxResultCount: maxResultCount,
    );
  }
}