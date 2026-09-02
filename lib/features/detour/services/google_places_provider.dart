// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'dart:convert';
import 'dart:math' as math;

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

    final types = includedTypes
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();

    if (types.isEmpty) {
      return const [];
    }

    final safeRadius = radiusMeters.clamp(0.1, 50000.0);
    final safeMaxResults = maxResultCount.clamp(1, 20);
    final httpClient = _client ?? http.Client();

    try {
      debugPrint('GOOGLE PLACES: Sending nearby search');
      debugPrint(
        'GOOGLE PLACES: latitude=$latitude '
        'longitude=$longitude radius=$safeRadius',
      );
      debugPrint(
        'GOOGLE PLACES: includedTypes=$types',
      );
      debugPrint(
        'GOOGLE PLACES: maxResultCount=$safeMaxResults',
      );

      final primaryResponse = await _postWithRetries(
        httpClient: httpClient,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: safeRadius,
        includedTypes: types,
        maxResultCount: safeMaxResults,
      );

      if (primaryResponse.statusCode == 200) {
        return _parseResponse(primaryResponse);
      }

      if (primaryResponse.statusCode != 500 ||
          types.length == 1) {
        throw _exceptionFromResponse(primaryResponse);
      }

      debugPrint(
        'GOOGLE PLACES: multi-type request returned 500; '
        'falling back to individual type searches.',
      );

      final merged = <String, DetourVenue>{};

      for (final type in types) {
        try {
          final response = await _postWithRetries(
            httpClient: httpClient,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: safeRadius,
            includedTypes: [type],
            maxResultCount: safeMaxResults,
          );

          if (response.statusCode != 200) {
            debugPrint(
              'GOOGLE PLACES: type=$type failed '
              '(${response.statusCode}).',
            );
            continue;
          }

          for (final venue in _parseResponse(response)) {
            if (venue.placeId.isNotEmpty) {
              merged[venue.placeId] = venue;
            }
          }
        } catch (error) {
          debugPrint(
            'GOOGLE PLACES: type=$type exception: $error',
          );
        }
      }

      final venues = merged.values.toList();

      venues.sort(
        (first, second) {
          final firstDistance = _distanceSquared(
            latitude,
            longitude,
            first.latitude,
            first.longitude,
          );

          final secondDistance = _distanceSquared(
            latitude,
            longitude,
            second.latitude,
            second.longitude,
          );

          return firstDistance.compareTo(secondDistance);
        },
      );

      return venues.take(safeMaxResults).toList();
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

  Future<http.Response> _postWithRetries({
    required http.Client httpClient,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required List<String> includedTypes,
    required int maxResultCount,
  }) async {
    var response = await _postNearby(
      httpClient: httpClient,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      includedTypes: includedTypes,
      maxResultCount: maxResultCount,
    );

    for (var attempt = 1;
        attempt <= 2 && response.statusCode == 500;
        attempt++) {
      debugPrint(
        'GOOGLE PLACES: HTTP 500; '
        'retry ${attempt + 1}/3',
      );

      await Future<void>.delayed(
        Duration(milliseconds: 500 * attempt),
      );

      response = await _postNearby(
        httpClient: httpClient,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        includedTypes: includedTypes,
        maxResultCount: maxResultCount,
      );
    }

    return response;
  }

  Future<http.Response> _postNearby({
    required http.Client httpClient,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required List<String> includedTypes,
    required int maxResultCount,
  }) async {
    final requestBody = {
      'includedTypes': includedTypes,
      'maxResultCount': maxResultCount,
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

    final response = await httpClient
        .post(
          Uri.parse(_baseUrl),
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

    debugPrint(
      'GOOGLE PLACES STATUS: ${response.statusCode}',
    );

    if (response.statusCode != 200) {
      debugPrint(
        'GOOGLE PLACES BODY: ${response.body}',
      );
    }

    return response;
  }

  List<DetourVenue> _parseResponse(
    http.Response response,
  ) {
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
        .where((venue) => venue.isValid)
        .toList();
  }

  GooglePlacesException _exceptionFromResponse(
    http.Response response,
  ) {
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

    return GooglePlacesException(
      'Google Places API request failed '
      '(${response.statusCode}).$details',
    );
  }

  double _distanceSquared(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadius = 6371000.0;

    final lat1 = latitude1 * math.pi / 180;
    final lat2 = latitude2 * math.pi / 180;
    final deltaLat =
        (latitude2 - latitude1) * math.pi / 180;
    final deltaLon =
        (longitude2 - longitude1) * math.pi / 180;

    final a =
        math.sin(deltaLat / 2) *
            math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    return 2 *
        earthRadius *
        math.atan2(
          math.sqrt(a),
          math.sqrt(1 - a),
        );
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
  const GooglePlacesException(this.message);

  final String message;

  @override
  String toString() => message;
}
