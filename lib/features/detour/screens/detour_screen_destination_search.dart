part of 'detour_screen.dart';

extension _DetourDestinationSearch on _DetourScreenState {
  Future<void> _loadDestinations() async {
    try {
      await loadDetourDestinations();
    } catch (error) {
      debugPrint(
        'DETOUR DESTINATIONS LOAD FAILED: $error',
      );
    }

    if (!mounted) {
      return;
    }

    _updateState(() {
      _loadingDestinations = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingCurrentLocation) {
      return;
    }

    _updateState(() {
      _loadingCurrentLocation = true;
    });

    try {
      final position =
          await LocationService.getCurrentLocation();

      if (!mounted) {
        return;
      }

      _updateState(() {
        _startingPoint = DetourEndpoint(
          name: 'Current location',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not get your current location: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        _updateState(() {
          _loadingCurrentLocation = false;
        });
      }
    }
  }

  void _swapLocations() {
    if (_startingPoint == null &&
        _destination == null) {
      return;
    }

    _updateState(() {
      final oldStartingPoint = _startingPoint;

      _startingPoint = _destination;
      _destination = oldStartingPoint;

      _destinationController.text =
          _destination?.name ?? '';
    });
  }

  Future<List<CrawlLocationSearchResult>>
      _searchDestinationPlaces(
    String query,
  ) async {
    final apiKey = const String.fromEnvironment(
      'GOOGLE_PLACES_API_KEY',
    );

    if (apiKey.trim().isEmpty) {
      throw const _DestinationSearchException(
        'Google Places API key is not configured.',
      );
    }

    final requestBody = <String, dynamic>{
      'textQuery': query,
      'pageSize': 8,
      'regionCode': 'CA',
    };

    final startingPoint = _startingPoint;

    if (startingPoint != null &&
        startingPoint.isValid) {
      requestBody['locationBias'] = <String, dynamic>{
        'circle': <String, dynamic>{
          'center': <String, dynamic>{
            'latitude': startingPoint.latitude,
            'longitude': startingPoint.longitude,
          },
          'radius': 50000.0,
        },
      };
    }

    final response = await _destinationSearchClient
        .post(
          Uri.parse(
            'https://places.googleapis.com/v1/places:searchText',
          ),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,places.location',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      debugPrint(
        'DETOUR DESTINATION SEARCH FAILED: '
        '${response.statusCode} ${response.body}',
      );

      throw const _DestinationSearchException(
        'Google Places search failed.',
      );
    }

    final decoded = jsonDecode(response.body);
    final places =
        decoded is Map ? decoded['places'] : null;

    final results =
        <CrawlLocationSearchResult>[];

    if (places is List) {
      for (final place in places) {
        if (place is! Map) {
          continue;
        }

        final displayName = place['displayName'];
        final location = place['location'];

        final name = displayName is Map
            ? displayName['text']?.toString()
            : null;

        final address =
            place['formattedAddress']?.toString();

        final latitude = location is Map
            ? (location['latitude'] as num?)?.toDouble()
            : null;

        final longitude = location is Map
            ? (location['longitude'] as num?)?.toDouble()
            : null;

        if (name == null ||
            name.trim().isEmpty ||
            latitude == null ||
            longitude == null) {
          continue;
        }

        results.add(
          CrawlLocationSearchResult(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      }
    }

    return results;
  }

  Future<void> _searchDestination(
    String query,
  ) async {
    final normalizedQuery = query.trim();
    final requestId =
        ++_destinationSearchRequest;

    _destinationSearchDebounce?.cancel();

    if (normalizedQuery.isEmpty) {
      _updateState(() {
        _searchResults = [];
        _searching = false;
      });

      return;
    }

    _updateState(() {
      _searching = true;
    });

    _destinationSearchDebounce = Timer(
      const Duration(milliseconds: 450),
      () async {
        try {
          final results =
              await _searchDestinationPlaces(
            normalizedQuery,
          );

          if (!mounted ||
              requestId !=
                  _destinationSearchRequest ||
              _destinationController.text.trim() !=
                  normalizedQuery) {
            return;
          }

          _updateState(() {
            _searchResults = results;
          });
        } catch (error) {
          if (!mounted ||
              requestId !=
                  _destinationSearchRequest) {
            return;
          }

          debugPrint(
            'DETOUR DESTINATION SEARCH ERROR: $error',
          );

          _updateState(() {
            _searchResults = [];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not search for that destination.',
              ),
            ),
          );
        } finally {
          if (mounted &&
              requestId ==
                  _destinationSearchRequest) {
            _updateState(() {
              _searching = false;
            });
          }
        }
      },
    );
  }

  Future<void> _selectSearchResult(
    CrawlLocationSearchResult result,
  ) async {
    ++_destinationSearchRequest;
    _destinationSearchDebounce?.cancel();

    final destination = DetourEndpoint(
      name: result.name,
      address: result.address,
      latitude: result.latitude,
      longitude: result.longitude,
    );

    _updateState(() {
      _destination = destination;
      _destinationController.text =
          destination.name;
      _searchResults = [];
    });

    _destinationFocusNode.unfocus();

    await recordRecentDetourDestination(
      destination,
    );

    if (!mounted) {
      return;
    }

    _updateState(() {});
  }

  Future<void> _selectDestination(
    DetourEndpoint destination,
  ) async {
    ++_destinationSearchRequest;
    _destinationSearchDebounce?.cancel();

    _updateState(() {
      _destination = destination;
      _destinationController.text =
          destination.name;
      _searchResults = [];
    });

    _destinationFocusNode.unfocus();

    await recordRecentDetourDestination(
      destination,
    );

    if (!mounted) {
      return;
    }

    _updateState(() {});
  }

  Future<void> _toggleSavedDestination(
    DetourEndpoint destination,
  ) async {
    if (isSavedDetourDestination(
      destination,
    )) {
      await removeDetourDestination(
        destination,
      );
    } else {
      await saveDetourDestination(
        destination,
      );
    }

    if (!mounted) {
      return;
    }

    _updateState(() {});
  }

  void _clearDestination() {
    ++_destinationSearchRequest;
    _destinationSearchDebounce?.cancel();

    _updateState(() {
      _destination = null;
      _destinationController.clear();
      _searchResults = [];
    });
  }
}