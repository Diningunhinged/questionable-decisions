import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/detour_venue.dart';

class GooglePlacesProvider {
  const GooglePlacesProvider({
    String? apiKey,
    this._client,
  }) : _apiKey =
        apiKey ??
        const String.fromEnvironment(
          'GOOGLE_PLACES_API_KEY',
        );

  static const String _baseUrl =
      'https://places.googleapis.com/v1/places:searchNearby';

  static const String _fieldMask =
      'places.id,'
      'places.displayName,'
      'places.formattedAddress,'
      'places.location,'
      'places.primaryType,'
      'places.types,'
      'places.currentOpeningHours';

  final String _apiKey;
  final http.Client? _client;

  Future<List<DetourVenue>> searchNearby({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required List<String> includedTypes,
    int maxResultCount = 20,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw const GooglePlacesException(
        'Google Places API key is not configured.',
      );
    }

    if (includedTypes.isEmpty) {
      return const [];
    }

    final uri = Uri.parse(_baseUrl);

    final requestBody = {
      'includedTypes': includedTypes,
      'maxResultCount': maxResultCount.clamp(1, 20),
      'rankPreference': 'DISTANCE',
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radiusMeters,
        },
      },
    };

    final httpClient = _client ?? http.Client();

    try {
      debugPrint(
        'GOOGLE PLACES: Sending nearby search',
      );
      debugPrint(
        'GOOGLE PLACES: latitude=$latitude '
        'longitude=$longitude '
        'radius=$radiusMeters',
      );
      debugPrint(
        'GOOGLE PLACES: includedTypes=$includedTypes',
      );
      debugPrint(
        'GOOGLE PLACES: maxResultCount='
        '${maxResultCount.clamp(1, 20)}',
      );

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
            const Duration(seconds: 20),
          );

      // TEMPORARY DIAGNOSTIC LOGGING.
      // This will show us Google's actual response,
      // especially if the API returns HTTP 400.
      debugPrint(
        'GOOGLE PLACES STATUS: ${response.statusCode}',
      );
      debugPrint(
        'GOOGLE PLACES BODY: ${response.body}',
      );

      if (response.statusCode != 200) {
        String details = '';

        try {
          final errorBody = jsonDecode(response.body);

          if (errorBody is Map<String, dynamic>) {
            final error = errorBody['error'];

            if (error is Map<String, dynamic>) {
              final status = error['status']?.toString();
              final message = error['message']?.toString();

              final parts = <String>[];

              if (status != null && status.isNotEmpty) {
                parts.add(status);
              }

              if (message != null && message.isNotEmpty) {
                parts.add(message);
              }

              if (parts.isNotEmpty) {
                details = ' ${parts.join(': ')}';
              }
            }
          }
        } catch (_) {
          if (response.body.trim().isNotEmpty) {
            details = ' ${response.body.trim()}';
          }
        }

        throw GooglePlacesException(
          'Google Places API request failed '
          '(${response.statusCode}).$details',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const GooglePlacesException(
          'Google Places API returned an unexpected response.',
        );
      }

      final rawPlaces = decoded['places'];

      if (rawPlaces is! List) {
        return const [];
      }

      return rawPlaces
          .whereType<Map<String, dynamic>>()
          .map(_parseVenue)
          .where(
            (venue) => venue.isValid,
          )
          .toList();
    } on GooglePlacesException {
      rethrow;
    } on FormatException {
      throw const GooglePlacesException(
        'Google Places API returned invalid JSON.',
      );
    } catch (error) {
      debugPrint(
        'GOOGLE PLACES EXCEPTION: $error',
      );

      throw GooglePlacesException(
        'Could not search Google Places: $error',
      );
    } finally {
      if (_client == null) {
        httpClient.close();
      }
    }
  }

  DetourVenue _parseVenue(
    Map<String, dynamic> json,
  ) {
    final placeId =
        json['id']?.toString().trim() ?? '';

    final displayName = json['displayName'];

    final name =
        displayName is Map<String, dynamic>
            ? displayName['text']?.toString().trim() ?? ''
            : '';

    final rawAddress =
        json['formattedAddress']?.toString().trim();

    final address =
        rawAddress == null || rawAddress.isEmpty
            ? null
            : rawAddress;

    final location = json['location'];

    double latitude = 0;
    double longitude = 0;

    if (location is Map<String, dynamic>) {
      latitude =
          (location['latitude'] as num?)?.toDouble() ?? 0;

      longitude =
          (location['longitude'] as num?)?.toDouble() ?? 0;
    }

    final primaryType =
        json['primaryType']?.toString().trim();

    final types =
        json['types'] is List
            ? (json['types'] as List)
                .whereType<String>()
                .toList()
            : <String>[];

    bool? isOpenNow;

    final openingHours =
        json['currentOpeningHours'];

    if (openingHours is Map<String, dynamic>) {
      final rawOpen = openingHours['openNow'];

      if (rawOpen is bool) {
        isOpenNow = rawOpen;
      }
    }

    return DetourVenue(
      placeId: placeId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      primaryType:
          primaryType == null || primaryType.isEmpty
              ? null
              : primaryType,
      types: types,
      isOpenNow: isOpenNow,
    );
  }
}

class GooglePlacesException implements Exception {
  const GooglePlacesException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}