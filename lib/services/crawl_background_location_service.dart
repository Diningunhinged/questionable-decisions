import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/nearby_result.dart';
import 'notification_service.dart';

/// Background location monitoring for an active Crawl.
///
/// This service intentionally runs alongside the existing CrawlScreen
/// foreground location stream. It does not replace or modify that stream.
class CrawlBackgroundLocationService {
  CrawlBackgroundLocationService._();

  static const double _encounterDistanceMeters = 500.0;

  static StreamSubscription<Position>? _positionSubscription;
  static NearbyResult? _activeStop;
  static bool _notificationSent = false;

  static bool get isRunning => _positionSubscription != null;

  static Future<void> start({
    required NearbyResult activeStop,
  }) async {
    await stop();

    _activeStop = activeStop;
    _notificationSent = false;

    final location = activeStop.venue.location;
    if (location == null || !location.isValid) {
      _activeStop = null;
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always) {
      debugPrint(
        'CRAWL BACKGROUND LOCATION: Always/background permission is not granted. '
        'Background monitoring will not start.',
      );
      _activeStop = null;
      return;
    }

    final settings = _buildLocationSettings();

    if (settings == null) {
      debugPrint(
        'CRAWL BACKGROUND LOCATION: Platform does not support background monitoring.',
      );
      _activeStop = null;
      return;
    }

    debugPrint(
      'CRAWL BACKGROUND LOCATION: Starting for ${activeStop.title}',
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      _handlePosition,
      onError: (Object error) {
        debugPrint(
          'CRAWL BACKGROUND LOCATION ERROR: $error',
        );
      },
    );
  }

  static Future<void> updateActiveStop(
    NearbyResult activeStop,
  ) async {
    if (_activeStop == null) {
      return;
    }

    _activeStop = activeStop;
    _notificationSent = false;

    debugPrint(
      'CRAWL BACKGROUND LOCATION: Next stop updated to ${activeStop.title}',
    );
  }

  static Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _activeStop = null;
    _notificationSent = false;

    debugPrint(
      'CRAWL BACKGROUND LOCATION: Stopped',
    );
  }

  static LocationSettings? _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        intervalDuration: Duration(seconds: 10),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'QUESTIONABLE DECISIONS',
          notificationText:
              'Your Crawl is monitoring the next stop in the background.',
          notificationChannelName: 'Crawl Background Location',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 25,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    return null;
  }

  static void _handlePosition(Position position) {
    final activeStop = _activeStop;
    if (activeStop == null || _notificationSent) {
      return;
    }

    final location = activeStop.venue.location;
    if (location == null || !location.isValid) {
      return;
    }

    final distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      location.latitude!,
      location.longitude!,
    );

    debugPrint(
      'CRAWL BACKGROUND POSITION: ${activeStop.title} = '
      '${distanceMeters.toStringAsFixed(1)} m',
    );

    if (distanceMeters <= _encounterDistanceMeters) {
      _notificationSent = true;

      debugPrint(
        'CRAWL BACKGROUND NEARBY: ${activeStop.title} '
        'within $_encounterDistanceMeters m',
      );

      NotificationService.showCrawlEncounter(
        result: activeStop,
        distanceMeters: distanceMeters,
      );
    }
  }
}
