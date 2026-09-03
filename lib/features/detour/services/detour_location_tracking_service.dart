// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS tracking for an active Detour.
///
/// This service is intentionally separate from the existing Crawl location
/// monitoring. It only provides live positions to Detour and contains no
/// notification or UI logic.
class DetourLocationTrackingService {
  DetourLocationTrackingService._();

  static StreamSubscription<Position>? _positionSubscription;

  static bool get isRunning => _positionSubscription != null;

  /// Starts live GPS tracking for an active Detour.
  ///
  /// [onPosition] receives each updated GPS position.
  /// [onError] receives a tracking error without throwing it into the UI.
  static Future<void> start({
    required void Function(Position position) onPosition,
    void Function(Object error)? onError,
  }) async {
    await stop();

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const DetourLocationTrackingException(
        'Location services are turned off on this phone.',
      );
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const DetourLocationTrackingException(
        'Location permission was denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const DetourLocationTrackingException(
        'Location permission is permanently denied. '
        'Open Settings > Apps > Questionable Decisions '
        '> Permissions > Location.',
      );
    }

    if (permission == LocationPermission.unableToDetermine) {
      throw const DetourLocationTrackingException(
        'The phone could not determine the location permission state.',
      );
    }

    final settings = _buildLocationSettings();

    debugPrint(
      'DETOUR LOCATION: Starting live GPS tracking',
    );

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        debugPrint(
          'DETOUR LOCATION POSITION: '
          '${position.latitude}, ${position.longitude} '
          'accuracy=${position.accuracy.toStringAsFixed(1)}m',
        );
        onPosition(position);
      },
      onError: (Object error) {
        debugPrint(
          'DETOUR LOCATION ERROR: $error',
        );

        onError?.call(error);
      },
    );

    try {
      final initialPosition =
          await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );

      debugPrint(
        'DETOUR LOCATION INITIAL POSITION: '
        '${initialPosition.latitude}, '
        '${initialPosition.longitude} '
        'accuracy=${initialPosition.accuracy.toStringAsFixed(1)}m',
      );

      onPosition(initialPosition);
    } catch (error) {
      debugPrint(
        'DETOUR LOCATION INITIAL POSITION ERROR: $error',
      );

      onError?.call(error);
    }
  }

  /// Stops live GPS tracking.
  static Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    debugPrint(
      'DETOUR LOCATION: Stopped',
    );
  }

  static LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        intervalDuration: const Duration(seconds: 10),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 25,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: false,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
  }
}

class DetourLocationTrackingException implements Exception {
  const DetourLocationTrackingException(this.message);

  final String message;

  @override
  String toString() => message;
}
