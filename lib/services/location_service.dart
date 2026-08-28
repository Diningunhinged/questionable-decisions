import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  /// Development-only simulated location.
  ///
  /// When set, getCurrentLocation() returns this position instead
  /// of requesting the phone's real GPS position.
  ///
  /// This is only active in debug builds.
  static Position? _debugPosition;

  /// Whether a simulated location is currently being used.
  static bool get isUsingDebugLocation =>
      kDebugMode && _debugPosition != null;

  /// Sets a simulated location for development/testing.
  ///
  /// This has no effect in release builds.
  static void setDebugLocation({
    required double latitude,
    required double longitude,
  }) {
    if (!kDebugMode) {
      return;
    }

    _debugPosition = Position(
      longitude: longitude,
      latitude: latitude,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    debugPrint(
      'LOCATION TEST: Simulated location set to '
      '$latitude, $longitude',
    );
  }

  /// Clears the simulated location and returns the app to real GPS.
  static void clearDebugLocation() {
    if (!kDebugMode) {
      return;
    }

    _debugPosition = null;

    debugPrint(
      'LOCATION TEST: Simulated location cleared',
    );
  }

  /// Returns the current location.
  ///
  /// In debug builds, a configured simulated location takes
  /// precedence over the phone's actual GPS.
  static Future<Position> getCurrentLocation() async {
    if (kDebugMode && _debugPosition != null) {
      debugPrint(
        'LOCATION TEST: Using simulated location '
        '${_debugPosition!.latitude}, '
        '${_debugPosition!.longitude}',
      );

      return _debugPosition!;
    }

    debugPrint(
      'LOCATION: Starting location request',
    );

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    debugPrint(
      'LOCATION: Service enabled = $serviceEnabled',
    );

    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Location services are turned off on this phone.',
      );
    }

    var permission =
        await Geolocator.checkPermission();

    debugPrint(
      'LOCATION: Initial permission = $permission',
    );

    if (permission ==
        LocationPermission.denied) {
      debugPrint(
        'LOCATION: Requesting permission...',
      );

      permission =
          await Geolocator.requestPermission();

      debugPrint(
        'LOCATION: Permission result = $permission',
      );
    }

    if (permission ==
        LocationPermission.denied) {
      throw const LocationPermissionException(
        'Location permission was denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw const LocationPermissionException(
        'Location permission is permanently denied. '
        'Open Settings > Apps > Questionable Decisions '
        '> Permissions > Location.',
      );
    }

    if (permission ==
        LocationPermission.unableToDetermine) {
      throw const LocationPermissionException(
        'The phone could not determine the location '
        'permission state.',
      );
    }

    debugPrint(
      'LOCATION: Getting GPS position...',
    );

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    debugPrint(
      'LOCATION: Got position '
      '${position.latitude}, '
      '${position.longitude}',
    );

    return position;
  }
}

class LocationServiceException
    implements Exception {
  final String message;

  const LocationServiceException(
    this.message,
  );

  @override
  String toString() => message;
}

class LocationPermissionException
    implements Exception {
  final String message;

  const LocationPermissionException(
    this.message,
  );

  @override
  String toString() => message;
}