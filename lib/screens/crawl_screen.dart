import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/crawl/models/crawl_configuration.dart';
import '../models/nearby_result.dart';
import '../services/dining_unhinged_api.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class CrawlScreen extends StatefulWidget {
  final CrawlConfiguration configuration;

  const CrawlScreen({
    super.key,
    this.configuration = const CrawlConfiguration(),
  });

  @override
  State<CrawlScreen> createState() => _CrawlScreenState();
}

class _CrawlScreenState extends State<CrawlScreen> {
  static const double _encounterDistanceMeters = 500.0;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _debugLocationTimer;

  List<NearbyResult> _results = [];
  List<NearbyResult> _crawlStops = [];
  final Set<String> _encountered = <String>{};
  final Set<String> _encounteredLocations = <String>{};

  Position? _currentPosition;

  bool _loading = false;
  bool _running = false;
  String? _error;

  double get _crawlRadiusMeters =>
      widget.configuration.walkingDistanceMeters;

  bool get _usesImperial =>
      widget.configuration.distanceUnit == DistanceUnit.imperial;

  String get _crawlRadiusText {
    final meters = _crawlRadiusMeters;

    if (_usesImperial) {
      final miles = meters / 1609.344;

      if (miles < 0.1) {
        final feet = meters * 3.28084;
        return '${feet.round()} ft';
      }

      return '${miles.toStringAsFixed(miles < 10 ? 1 : 0)} mi';
    }

    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String get _encounterDistanceText {
    if (_usesImperial) {
      final feet = _encounterDistanceMeters * 3.28084;

      if (feet < 528) {
        return '${feet.round()} ft';
      }

      final miles = _encounterDistanceMeters / 1609.344;
      return '${miles.toStringAsFixed(1)} mi';
    }

    return '${_encounterDistanceMeters.round()} m';
  }

  @override
  void dispose() {
    _stopLocationMonitoring();
    super.dispose();
  }

  Future<void> _startCrawl() async {
    if (_running || _loading) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _encountered.clear();
      _encounteredLocations.clear();
      _currentPosition = null;
      _results = [];
      _crawlStops = [];
    });

    try {
      final position =
          await LocationService.getCurrentLocation();

      final results =
          await DiningUnhingedApi().fetchNearbyResults();

      if (!mounted) {
        return;
      }

      final validResults = results
          .where(
            (result) =>
                result.venue.location?.isValid == true,
          )
          .toList();

      final crawlResults = <NearbyResult>[];

      for (final result in validResults) {
        final location = result.venue.location;

        if (location == null || !location.isValid) {
          continue;
        }

        final distanceMeters =
            Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude!,
          location.longitude!,
        );

        if (distanceMeters <= _crawlRadiusMeters) {
          result.distanceKm =
              distanceMeters / 1000.0;

          crawlResults.add(result);
        }
      }

      crawlResults.sort(
        (a, b) =>
            (a.distanceKm ?? double.infinity)
                .compareTo(
          b.distanceKm ?? double.infinity,
        ),
      );

      final categoryResults = crawlResults
          .where(_matchesSelectedCategory)
          .toList();

      final crawlStops = _buildCrawlStops(
        categoryResults,
        position,
      );

      setState(() {
        _currentPosition = position;
        _results = crawlResults;
        _crawlStops = crawlStops;
        _running = true;
        _loading = false;
      });

      debugPrint('CRAWL STARTED');

      debugPrint(
        'Starting position: '
        '${position.latitude}, ${position.longitude}',
      );

      debugPrint(
        'Reviewed locations returned: '
        '${validResults.length}',
      );

      debugPrint(
        'Crawl candidates within radius: '
        '${crawlResults.length}',
      );

      debugPrint(
        'Crawl candidates after category filter: '
        '${categoryResults.length}',
      );

      debugPrint(
        'CRAWL STOPS SELECTED: '
        '${crawlStops.length} of ${widget.configuration.stopCount}',
      );

      for (var index = 0; index < crawlStops.length; index++) {
        debugPrint(
          'CRAWL STOP ${index + 1}: '
          '${crawlStops[index].title}',
        );
      }

      debugPrint(
        'CRAWL SEARCH RADIUS: '
        '$_crawlRadiusMeters metres',
      );

      debugPrint(
        'CRAWL ENCOUNTER RADIUS: '
        '$_encounterDistanceMeters metres',
      );

      _checkForEncounters(position);

      await _startLocationMonitoring();
    } on LocationServiceException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } on LocationPermissionException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = 'Could not start Crawl: $e';
      });
    }
  }

  Future<void> _startLocationMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _debugLocationTimer?.cancel();
    _debugLocationTimer = null;

    if (!_running) {
      return;
    }

    if (kDebugMode &&
        LocationService.isUsingDebugLocation) {
      debugPrint(
        'CRAWL LOCATION MONITORING: '
        'DEBUG LOCATION MODE',
      );

      _debugLocationTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) async {
          if (!_running || !mounted) {
            return;
          }

          try {
            final position =
                await LocationService
                    .getCurrentLocation();

            _handlePosition(position);
          } catch (error) {
            debugPrint(
              'CRAWL DEBUG LOCATION ERROR: '
              '$error',
            );
          }
        },
      );

      return;
    }

    debugPrint(
      'CRAWL LOCATION MONITORING: '
      'REAL GPS MODE',
    );

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen(
      _handlePosition,
      onError: (Object error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _error =
              'GPS monitoring stopped: $error';
          _running = false;
        });
      },
    );
  }

  void _handlePosition(Position position) {
    if (!mounted || !_running) {
      return;
    }

    setState(() {
      _currentPosition = position;
    });

    debugPrint(
      'CRAWL POSITION: '
      '${position.latitude}, ${position.longitude}',
    );

    _checkForEncounters(position);
  }

  void _checkForEncounters(Position position) {
    for (final result in _crawlStops) {
      final location = result.venue.location;

      if (location == null || !location.isValid) {
        continue;
      }

      final physicalLocationKey = _physicalLocationKey(result);

      final distanceMeters =
          Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location.latitude!,
        location.longitude!,
      );

      result.distanceKm =
          distanceMeters / 1000.0;

      debugPrint(
        'CRAWL DISTANCE: '
        '${result.title} = '
        '${distanceMeters.toStringAsFixed(1)} m',
      );

      if (_encounteredLocations.contains(physicalLocationKey)) {
        continue;
      }

      if (distanceMeters <=
          _encounterDistanceMeters) {
        debugPrint(
          'CRAWL ENCOUNTER: '
          '${result.title} '
          'within $_encounterDistanceMeters m '
          '(physical location: $physicalLocationKey)',
        );

        _encounteredLocations.add(physicalLocationKey);

        _markPhysicalLocationEncountered(
          physicalLocationKey,
        );

        _showEncounter(
          result,
          distanceMeters,
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _physicalLocationKey(NearbyResult result) {
    final location = result.venue.location!;

    // Coordinates are rounded to roughly centimetre-level precision.
    // This treats reviews at the same physical venue as one encounter
    // while still keeping genuinely different nearby venues separate.
    final latitude =
        location.latitude!.toStringAsFixed(5);
    final longitude =
        location.longitude!.toStringAsFixed(5);

    return 'location:$latitude,$longitude';
  }

  void _markPhysicalLocationEncountered(
    String physicalLocationKey,
  ) {
    for (final result in _crawlStops) {
      final location = result.venue.location;

      if (location == null || !location.isValid) {
        continue;
      }

      if (_physicalLocationKey(result) ==
          physicalLocationKey) {
        _encountered.add(
          _resultKey(result),
        );
      }
    }
  }

  String _resultKey(NearbyResult result) {
    return '${result.type}:${result.slug}';
  }

  void _showEncounter(
    NearbyResult result,
    double distanceMeters,
  ) {
    if (!mounted) {
      return;
    }

    final distance =
        _formatDistance(distanceMeters);

    NotificationService.showCrawlEncounter(
      result: result,
      distanceMeters: distanceMeters,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration:
            const Duration(seconds: 6),
        backgroundColor:
            const Color(0xFF1C1C1E),
        content: Row(
          children: [
            const Icon(
              Icons.location_on,
              color:
                  Color(0xFFD4AF37),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${result.title} is $distance away.',
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor:
              const Color(0xFFD4AF37),
          onPressed: () =>
              _openReview(result),
        ),
      ),
    );
  }

  String _formatDistance(
    double distanceMeters,
  ) {
    if (_usesImperial) {
      final miles =
          distanceMeters / 1609.344;

      if (miles < 0.1) {
        final feet =
            distanceMeters * 3.28084;

        return '${feet.round()} ft';
      }

      return '${miles.toStringAsFixed(miles < 10 ? 1 : 0)} mi';
    }

    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _openReview(
    NearbyResult result,
  ) async {
    final section =
        result.isDrink
            ? 'drinks'
            : 'venues';

    final url = Uri.parse(
      'https://www.diningunhinged.ca/'
      '$section/${result.slug}',
    );

    try {
      await launchUrl(
        url,
        mode:
            LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the Dining Unhinged review.',
          ),
        ),
      );
    }
  }

  /// Development-only helper for testing Crawl proximity notifications.
  ///
  /// Moves the simulated GPS position to the selected Crawl stop and then
  /// immediately runs the same encounter check used by the real GPS stream.
  Future<void> _simulateArrivalAtStop(NearbyResult result) async {
    if (!kDebugMode) {
      return;
    }

    final location = result.venue.location;

    if (location == null || !location.isValid) {
      return;
    }

    LocationService.setDebugLocation(
      latitude: location.latitude!,
      longitude: location.longitude!,
    );

    final position = await LocationService.getCurrentLocation();

    if (!mounted || !_running) {
      return;
    }

    debugPrint(
      'CRAWL DEBUG TEST: Simulated arrival at '
      '${result.title}',
    );

    _handlePosition(position);
  }

  Future<void> _stopLocationMonitoring() async {
    _debugLocationTimer?.cancel();
    _debugLocationTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _stopCrawl() async {
    await _stopLocationMonitoring();

    if (!mounted) {
      return;
    }

    setState(() {
      _running = false;
      _loading = false;
      _currentPosition = null;
      _results = [];
      _crawlStops = [];
      _encountered.clear();
      _encounteredLocations.clear();
      _error = null;
    });

    debugPrint('CRAWL STOPPED');
  }

  bool _matchesSelectedCategory(NearbyResult result) {
    final categories = widget.configuration.categories;

    if (categories.contains(CrawlCategory.anyCategory) ||
        categories.contains(CrawlCategory.surpriseMe)) {
      return true;
    }

    final category = (result.category ?? '').toLowerCase().trim();

    for (final selected in categories) {
      switch (selected) {
        case CrawlCategory.breweries:
          if (category.contains('brew')) return true;
          break;
        case CrawlCategory.cocktailBars:
          if (category.contains('cocktail')) return true;
          break;
        case CrawlCategory.restaurants:
          if (category.contains('restaurant')) return true;
          break;
        case CrawlCategory.distilleries:
          if (category.contains('distill')) return true;
          break;
        case CrawlCategory.wine:
          if (category.contains('wine')) return true;
          break;
        case CrawlCategory.coffee:
          if (category.contains('coffee') || category.contains('café')) return true;
          break;
        case CrawlCategory.surpriseMe:
        case CrawlCategory.anyCategory:
          return true;
      }
    }

    return false;
  }

  List<NearbyResult> _buildCrawlStops(
    List<NearbyResult> candidates,
    Position startingPosition,
  ) {
    // A Crawl stop represents a physical venue, not an individual
    // Dining Unhinged review. Multiple reviews can share the same
    // coordinates, so collapse them before selecting stops.
    final uniqueVenues = <String, NearbyResult>{};

    for (final result in candidates) {
      final location = result.venue.location;

      if (location == null || !location.isValid) {
        continue;
      }

      final distanceMeters = Geolocator.distanceBetween(
        startingPosition.latitude,
        startingPosition.longitude,
        location.latitude!,
        location.longitude!,
      );

      // Do not treat the starting venue itself as a Crawl stop.
      if (distanceMeters <= 50.0) {
        continue;
      }

      uniqueVenues.putIfAbsent(
        _physicalLocationKey(result),
        () => result,
      );
    }

    final remaining =
        uniqueVenues.values.toList();

    final stops = <NearbyResult>[];

    var routeLatitude = startingPosition.latitude;
    var routeLongitude = startingPosition.longitude;
    final requestedStops = widget.configuration.stopCount;

    while (remaining.isNotEmpty &&
        stops.length < requestedStops) {
      NearbyResult? nearest;
      double nearestDistance = double.infinity;

      for (final candidate in remaining) {
        final location = candidate.venue.location;

        if (location == null || !location.isValid) {
          continue;
        }

        final distanceMeters =
            Geolocator.distanceBetween(
          routeLatitude,
          routeLongitude,
          location.latitude!,
          location.longitude!,
        );

        if (distanceMeters < nearestDistance) {
          nearestDistance = distanceMeters;
          nearest = candidate;
        }
      }

      if (nearest == null) {
        break;
      }

      stops.add(nearest);
      remaining.remove(nearest);

      final location = nearest.venue.location!;
      routeLatitude = location.latitude!;
      routeLongitude = location.longitude!;
    }

    debugPrint(
      'CRAWL PHYSICAL VENUES: '
      '${uniqueVenues.length} unique venues from '
      '${candidates.length} candidate results',
    );

    return stops;
  }

  List<NearbyResult> _sortedResults() {
    final sorted = _results
        .where(
          (result) =>
              result.distanceKm != null,
        )
        .toList();

    sorted.sort(
      (a, b) =>
          a.distanceKm!.compareTo(
        b.distanceKm!,
      ),
    );

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final encounteredCount =
        _encountered.length;

    final debugLocationActive =
        kDebugMode &&
        LocationService.isUsingDebugLocation;

    return Scaffold(
      backgroundColor:
          const Color(0xFF0D0D0F),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _running
              ? () async {
                  final position =
                      await LocationService
                          .getCurrentLocation();

                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _currentPosition =
                        position;
                  });

                  _checkForEncounters(
                    position,
                  );
                }
              : () async {},
          color:
              const Color(0xFFD4AF37),
          backgroundColor:
              const Color(0xFF1C1C1E),
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              28,
              20,
              30,
            ),
            children: [
              const Text(
                'CRAWL',
                style: TextStyle(
                  color:
                      Color(0xFFD4AF37),
                  fontSize: 32,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _running
                    ? 'We\'ll let you know when questionable decisions are nearby.'
                    : 'Let the app find the questionable decisions for you.',
                style:
                    const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 26),
              Container(
                padding:
                    const EdgeInsets.all(20),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF1C1C1E),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  border: Border.all(
                    color: _running
                        ? const Color(
                            0xFFD4AF37,
                          )
                        : const Color(
                            0xFF333337,
                          ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _running
                          ? Icons.my_location
                          : Icons.route,
                      color:
                          const Color(0xFFD4AF37),
                      size: 48,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      _running
                          ? 'CRAWL IS RUNNING'
                          : 'CRAWL IS STOPPED',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      _running
                          ? 'Searching within $_crawlRadiusText. Alerts trigger at $_encounterDistanceText.'
                          : 'Start Crawl to begin watching your route.',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    if (debugLocationActive) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFF0D0D0F,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border:
                              Border.all(
                            color:
                                const Color(
                              0xFFD4AF37,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.science,
                              color:
                                  Color(
                                0xFFD4AF37,
                              ),
                              size: 18,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                'DEBUG GPS ACTIVE',
                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFFD4AF37,
                                  ),
                                  fontWeight:
                                      FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_currentPosition !=
                        null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        'GPS: '
                        '${_currentPosition!.latitude.toStringAsFixed(5)}, '
                        '${_currentPosition!.longitude.toStringAsFixed(5)}',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (kDebugMode &&
                        _running &&
                        _crawlStops.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF241F0F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6B5A20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.science,
                                  color: Color(0xFFD4AF37),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'NOTIFICATION TEST',
                                  style: TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Simulate being at a Crawl stop to test the '
                              '500 m proximity notification.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._crawlStops.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _simulateArrivalAtStop(entry.value),
                                    icon: const Icon(
                                      Icons.location_on,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'SIMULATE ARRIVAL: '
                                      'STOP ${entry.key + 1}',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFFD4AF37),
                                      side: const BorderSide(
                                        color: Color(0xFF6B5A20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_running) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        '$encounteredCount encountered · '
                        '${_results.length} reviewed spots in range',
                        style:
                            const TextStyle(
                          color:
                              Color(0xFFD4AF37),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_error != null)
                Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 18,
                  ),
                  padding:
                      const EdgeInsets.all(16),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xFF24191A),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    border: Border.all(
                      color:
                          const Color(
                        0xFF6B3A3A,
                      ),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      height: 1.35,
                    ),
                  ),
                ),
              if (!_running)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : _startCrawl,
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFFD4AF37,
                      ),
                      foregroundColor:
                          const Color(
                        0xFF0D0D0F,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 16,
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Color(
                                0xFF0D0D0F,
                              ),
                            ),
                          )
                        : const Text(
                            'START CRAWL',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w900,
                              letterSpacing:
                                  0.8,
                            ),
                          ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _stopCrawl,
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          const Color(
                        0xFFD4AF37,
                      ),
                      side:
                          const BorderSide(
                        color:
                            Color(
                          0xFFD4AF37,
                        ),
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'STOP CRAWL',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing:
                            0.8,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (_running && _crawlStops.isNotEmpty)
                const Text(
                  'YOUR CRAWL STOPS',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              if (_running && _crawlStops.isNotEmpty)
                const SizedBox(height: 10),
              if (_running)
                ..._crawlStops.asMap().entries.map(
                  (entry) => _CrawlStopTile(
                    stopNumber: entry.key + 1,
                    result: entry.value,
                    encountered: _encountered.contains(
                      _resultKey(entry.value),
                    ),
                    onTap: () => _openReview(entry.value),
                    useImperial: _usesImperial,
                  ),
                ),
              if (_running &&
                  _results.isNotEmpty &&
                  _results.length > _crawlStops.length) ...[
                const SizedBox(height: 18),
                const Text(
                  'OTHER REVIEWED SPOTS IN RANGE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ..._sortedResults()
                    .where((result) => !_crawlStops.contains(result))
                    .take(10)
                    .map(
                      (result) => _CrawlResultTile(
                        result: result,
                        encountered: false,
                        onTap: () => _openReview(result),
                        useImperial: _usesImperial,
                      ),
                    ),
              ],
              if (_running &&
                  _results.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    top: 30,
                  ),
                  child: Text(
                    'No reviewed spots with valid coordinates were found within the selected Crawl distance.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          Colors.white54,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrawlStopTile extends StatelessWidget {
  final int stopNumber;
  final NearbyResult result;
  final bool encountered;
  final VoidCallback onTap;
  final bool useImperial;

  const _CrawlStopTile({
    required this.stopNumber,
    required this.result,
    required this.encountered,
    required this.onTap,
    required this.useImperial,
  });

  @override
  Widget build(BuildContext context) {
    final distanceMeters = (result.distanceKm ?? 0) * 1000;
    final distanceText = useImperial
        ? _formatImperial(distanceMeters)
        : _formatMetric(distanceMeters);

    return Card(
      color: const Color(0xFF1C1C1E),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: const Color(0xFF0D0D0F),
          child: Text(
            '$stopNumber',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(
          result.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          encountered ? 'ENCOUNTERED · $distanceText' : distanceText,
          style: TextStyle(
            color: encountered ? const Color(0xFFD4AF37) : Colors.white54,
            fontWeight: encountered ? FontWeight.w700 : null,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFFD4AF37),
        ),
      ),
    );
  }

  String _formatMetric(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatImperial(double meters) {
    final miles = meters / 1609.344;
    if (miles < 0.1) return '${(meters * 3.28084).round()} ft';
    return '${miles.toStringAsFixed(miles < 10 ? 1 : 0)} mi';
  }
}

class _CrawlResultTile
    extends StatelessWidget {
  final NearbyResult result;
  final bool encountered;
  final VoidCallback onTap;
  final bool useImperial;

  const _CrawlResultTile({
    required this.result,
    required this.encountered,
    required this.onTap,
    required this.useImperial,
  });

  @override
  Widget build(BuildContext context) {
    final distance =
        result.distanceKm ?? 0;

    final distanceMeters =
        distance * 1000;

    final distanceText =
        useImperial
            ? _formatImperial(
                distanceMeters,
              )
            : _formatMetric(
                distanceMeters,
              );

    return Card(
      color:
          const Color(0xFF1C1C1E),
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading:
            result.heroImage != null &&
                    result.heroImage!
                        .isNotEmpty
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    child: Image.network(
                      result.heroImage!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) =>
                              _fallbackIcon(),
                    ),
                  )
                : _fallbackIcon(),
        title: Text(
          result.title,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        subtitle: Text(
          encountered
              ? 'ENCOUNTERED · $distanceText'
              : distanceText,
          style: TextStyle(
            color: encountered
                ? const Color(
                    0xFFD4AF37,
                  )
                : Colors.white54,
            fontWeight: encountered
                ? FontWeight.w700
                : null,
          ),
        ),
        trailing:
            const Icon(
          Icons.chevron_right,
          color:
              Color(0xFFD4AF37),
        ),
      ),
    );
  }

  String _formatMetric(
    double meters,
  ) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatImperial(
    double meters,
  ) {
    final miles =
        meters / 1609.344;

    if (miles < 0.1) {
      final feet =
          meters * 3.28084;

      return '${feet.round()} ft';
    }

    return '${miles.toStringAsFixed(miles < 10 ? 1 : 0)} mi';
  }

  Widget _fallbackIcon() {
    return Container(
      width: 54,
      height: 54,
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF0D0D0F),
        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),
      child: const Icon(
        Icons.restaurant,
        color:
            Color(0xFFD4AF37),
      ),
    );
  }
}