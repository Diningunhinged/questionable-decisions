import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/detour_endpoint.dart';
import '../models/detour_route.dart';
import 'routing_provider.dart';

class GoogleRoutesProvider implements RoutingProvider {
  const GoogleRoutesProvider({
    String? apiKey,
    this._client,
  }) : _apiKey =
        apiKey ??
        const String.fromEnvironment(
          'GOOGLE_ROUTES_API_KEY',
        );

  static const String _baseUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  static const String _fieldMask =
      'routes.duration,'
      'routes.distanceMeters,'
      'routes.polyline.encodedPolyline,'
      'routes.optimizedIntermediateWaypointIndex';

  final String _apiKey;
  final http.Client? _client;

  @override
  Future<DetourRoute> calculateRoute({
    required DetourEndpoint start,
    required DetourEndpoint destination,
    List<DetourEndpoint> waypoints = const [],
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw const GoogleRoutesException(
        'Google Routes API key is not configured.',
      );
    }

    if (!start.isValid) {
      throw const GoogleRoutesException(
        'The starting location is invalid.',
      );
    }

    if (!destination.isValid) {
      throw const GoogleRoutesException(
        'The destination is invalid.',
      );
    }

    for (final waypoint in waypoints) {
      if (!waypoint.isValid) {
        throw const GoogleRoutesException(
          'One of the route stops is invalid.',
        );
      }
    }

    final uri = Uri.parse(_baseUrl);

    final requestBody = <String, dynamic>{
      'origin': {
        'location': {
          'latLng': {
            'latitude': start.latitude,
            'longitude': start.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
        },
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
      'polylineQuality': 'OVERVIEW',
      'computeAlternativeRoutes': false,
      'languageCode': 'en-US',
      'units': 'METRIC',
    };

    /*
     * Intermediate waypoints are stopovers by default.
     *
     * When multiple stops are supplied, Google can optimize
     * their order based primarily on travel time while also
     * considering distance and turns.
     */
    if (waypoints.isNotEmpty) {
      requestBody['intermediates'] =
          waypoints.map(
        (waypoint) {
          return {
            'location': {
              'latLng': {
                'latitude': waypoint.latitude,
                'longitude': waypoint.longitude,
              },
            },
          };
        },
      ).toList();

      /*
       * Ask Google to determine the most efficient order
       * of the supplied intermediate stops.
       */
      requestBody['optimizeWaypointOrder'] = true;
    }

    final httpClient =
        _client ?? http.Client();

    try {
      final response = await httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask': _fieldMask,
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) {
        String details = '';

        try {
          final errorBody =
              jsonDecode(response.body);

          if (errorBody
              is Map<String, dynamic>) {
            final error =
                errorBody['error'];

            if (error
                is Map<String, dynamic>) {
              final status =
                  error['status']?.toString();

              final message =
                  error['message']?.toString();

              final parts =
                  <String>[];

              if (status != null &&
                  status.isNotEmpty) {
                parts.add(status);
              }

              if (message != null &&
                  message.isNotEmpty) {
                parts.add(message);
              }

              if (parts.isNotEmpty) {
                details =
                    ' ${parts.join(': ')}';
              }
            }
          }
        } catch (_) {
          if (response.body
              .trim()
              .isNotEmpty) {
            details =
                ' ${response.body.trim()}';
          }
        }

        throw GoogleRoutesException(
          'Google Routes API request failed '
          '(${response.statusCode}).$details',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded
          is! Map<String, dynamic>) {
        throw const GoogleRoutesException(
          'Google Routes API returned an '
          'unexpected response.',
        );
      }

      final routes =
          decoded['routes'];

      if (routes is! List ||
          routes.isEmpty) {
        throw const GoogleRoutesException(
          'Google Routes API returned no route.',
        );
      }

      final firstRoute =
          routes.first;

      if (firstRoute
          is! Map<String, dynamic>) {
        throw const GoogleRoutesException(
          'Google Routes API returned an '
          'invalid route.',
        );
      }

      return _parseRoute(
        firstRoute,
        optimizeWaypoints:
            waypoints.isNotEmpty,
      );
    } on GoogleRoutesException {
      rethrow;
    } on FormatException {
      throw const GoogleRoutesException(
        'Google Routes API returned invalid JSON.',
      );
    } catch (error) {
      throw GoogleRoutesException(
        'Could not calculate route: $error',
      );
    } finally {
      if (_client == null) {
        httpClient.close();
      }
    }
  }

  DetourRoute _parseRoute(
    Map<String, dynamic> route, {
    required bool optimizeWaypoints,
  }) {
    final rawDistance =
        route['distanceMeters'];

    final rawDuration =
        route['duration'];

    if (rawDistance is! num) {
      throw const GoogleRoutesException(
        'Google route is missing distance.',
      );
    }

    final durationSeconds =
        _parseDurationSeconds(
      rawDuration,
    );

    final polyline =
        route['polyline'];

    if (polyline
        is! Map<String, dynamic>) {
      throw const GoogleRoutesException(
        'Google route is missing polyline data.',
      );
    }

    final encodedPolyline =
        polyline['encodedPolyline'];

    if (encodedPolyline is! String ||
        encodedPolyline.trim().isEmpty) {
      throw const GoogleRoutesException(
        'Google route is missing encoded polyline.',
      );
    }

    final geometry =
        _decodePolyline(
      encodedPolyline,
    );

    final optimizedIndices =
        _parseOptimizedWaypointIndices(
      route,
      optimizeWaypoints:
          optimizeWaypoints,
    );

    final result = DetourRoute(
      distanceMeters:
          rawDistance.toDouble(),
      durationSeconds:
          durationSeconds,
      geometry: geometry,
      optimizedWaypointIndices:
          optimizedIndices,
    );

    if (!result.isValid) {
      throw const GoogleRoutesException(
        'Google route contained invalid data.',
      );
    }

    return result;
  }

  List<int> _parseOptimizedWaypointIndices(
    Map<String, dynamic> route, {
    required bool optimizeWaypoints,
  }) {
    if (!optimizeWaypoints) {
      return const [];
    }

    final raw =
        route[
            'optimizedIntermediateWaypointIndex'];

    if (raw is! List) {
      throw const GoogleRoutesException(
        'Google route is missing the '
        'optimized waypoint order.',
      );
    }

    final indices =
        raw.whereType<num>()
            .map(
              (value) => value.toInt(),
            )
            .toList();

    if (indices.isEmpty) {
      throw const GoogleRoutesException(
        'Google route returned an empty '
        'optimized waypoint order.',
      );
    }

    final sortedIndices =
        [...indices]..sort();

    for (var index = 0;
        index < sortedIndices.length;
        index++) {
      if (sortedIndices[index] != index) {
        throw const GoogleRoutesException(
          'Google route returned an invalid '
          'optimized waypoint order.',
        );
      }
    }

    return indices;
  }

  double _parseDurationSeconds(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is! String) {
      throw const GoogleRoutesException(
        'Google route is missing duration.',
      );
    }

    final match = RegExp(
      r'^([0-9]+(?:\.[0-9]+)?)s$',
    ).firstMatch(
      value.trim(),
    );

    if (match == null) {
      throw const GoogleRoutesException(
        'Google route returned an '
        'invalid duration.',
      );
    }

    final seconds =
        double.tryParse(
      match.group(1)!,
    );

    if (seconds == null) {
      throw const GoogleRoutesException(
        'Google route returned an '
        'invalid duration.',
      );
    }

    return seconds;
  }

  List<List<double>> _decodePolyline(
    String encoded,
  ) {
    final points =
        <List<double>>[];

    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      final latitudeResult =
          _decodePolylineValue(
        encoded,
        index,
      );

      index =
          latitudeResult.nextIndex;

      latitude +=
          latitudeResult.value;

      if (index >= encoded.length) {
        throw const GoogleRoutesException(
          'Google route polyline is incomplete.',
        );
      }

      final longitudeResult =
          _decodePolylineValue(
        encoded,
        index,
      );

      index =
          longitudeResult.nextIndex;

      longitude +=
          longitudeResult.value;

      points.add([
        latitude / 100000.0,
        longitude / 100000.0,
      ]);
    }

    if (points.isEmpty) {
      throw const GoogleRoutesException(
        'Google route polyline contains no points.',
      );
    }

    return points;
  }

  _PolylineValue _decodePolylineValue(
    String encoded,
    int startIndex,
  ) {
    var index = startIndex;
    var result = 0;
    var shift = 0;

    while (true) {
      if (index >= encoded.length) {
        throw const GoogleRoutesException(
          'Google route polyline is malformed.',
        );
      }

      final byte =
          encoded.codeUnitAt(index++) -
              63;

      if (byte < 0 ||
          byte > 63) {
        throw const GoogleRoutesException(
          'Google route polyline contains '
          'invalid data.',
        );
      }

      result |=
          (byte & 0x1f) << shift;

      if (byte < 0x20) {
        break;
      }

      shift += 5;

      if (shift > 30) {
        throw const GoogleRoutesException(
          'Google route polyline value is '
          'too large.',
        );
      }
    }

    final decoded =
        (result & 1) != 0
            ? -(result >> 1) - 1
            : result >> 1;

    return _PolylineValue(
      value: decoded,
      nextIndex: index,
    );
  }
}

class _PolylineValue {
  const _PolylineValue({
    required this.value,
    required this.nextIndex,
  });

  final int value;
  final int nextIndex;
}

class GoogleRoutesException
    implements Exception {
  const GoogleRoutesException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}