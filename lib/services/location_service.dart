import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    print('LOCATION: Starting location request');

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    print('LOCATION: Service enabled = $serviceEnabled');

    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Location services are turned off on this phone.',
      );
    }

    var permission = await Geolocator.checkPermission();

    print('LOCATION: Initial permission = $permission');

    if (permission == LocationPermission.denied) {
      print('LOCATION: Requesting permission...');

      permission = await Geolocator.requestPermission();

      print('LOCATION: Permission result = $permission');
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionException(
        'Android denied location permission.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException(
        'Location permission is permanently denied. '
        'Open Settings > Apps > Questionable Decisions > Permissions > Location.',
      );
    }

    if (permission == LocationPermission.unableToDetermine) {
      throw const LocationPermissionException(
        'Android could not determine the location permission state.',
      );
    }

    print('LOCATION: Getting GPS position...');

    final position =
        await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    print(
      'LOCATION: Got position '
      '${position.latitude}, ${position.longitude}',
    );

    return position;
  }
}

class LocationServiceException implements Exception {
  final String message;

  const LocationServiceException(this.message);

  @override
  String toString() => message;
}

class LocationPermissionException implements Exception {
  final String message;

  const LocationPermissionException(this.message);

  @override
  String toString() => message;
}