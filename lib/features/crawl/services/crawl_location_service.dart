// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:geolocator/geolocator.dart';

import '../../../models/nearby_result.dart';
import '../../../services/location_service.dart';
import '../models/crawl_starting_point.dart';

class CrawlLocationService {
  const CrawlLocationService();

  Future<CrawlStartingPoint> useCurrentLocation() async {
    final Position position =
        await LocationService.getCurrentLocation();

    return CrawlStartingPoint(
      name: 'Current location',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  CrawlStartingPoint fromNearbyLocation(
    Location location, {
    String name = 'Selected location',
  }) {
    if (!location.isValid) {
      throw const CrawlLocationException(
        'The selected location has invalid coordinates.',
      );
    }

    return CrawlStartingPoint(
      name: name,
      latitude: location.latitude!,
      longitude: location.longitude!,
    );
  }
}

class CrawlLocationException implements Exception {
  final String message;

  const CrawlLocationException(this.message);

  @override
  String toString() => message;
}
