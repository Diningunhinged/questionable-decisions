import 'dart:async';

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
  StreamSubscription<Position>? _positionSubscription;

  List<NearbyResult> _results = [];
  final Set<String> _encountered = <String>{};

  Position? _currentPosition;

  bool _loading = false;
  bool _running = false;
  String? _error;

  double get _triggerDistanceMeters =>
      widget.configuration.walkingDistanceMeters;

  bool get _usesImperial =>
      widget.configuration.distanceUnit ==
      DistanceUnit.imperial;

  String get _triggerDistanceText {
    final meters = _triggerDistanceMeters;

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

  @override
  void dispose() {
    _positionSubscription?.cancel();
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
      _currentPosition = null;
      _results = [];
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

      setState(() {
        _currentPosition = position;
        _results = validResults;
        _running = true;
        _loading = false;
      });

      await _positionSubscription?.cancel();

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
            _error = 'GPS monitoring stopped: $error';
            _running = false;
          });
        },
      );

      _checkForEncounters(position);
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

  void _handlePosition(Position position) {
    if (!mounted || !_running) {
      return;
    }

    setState(() {
      _currentPosition = position;
    });

    _checkForEncounters(position);
  }

  void _checkForEncounters(Position position) {
    for (final result in _results) {
      final location = result.venue.location;

      if (location == null ||
          !location.isValid ||
          _encountered.contains(_resultKey(result))) {
        continue;
      }

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location.latitude!,
        location.longitude!,
      );

      result.distanceKm = distanceMeters / 1000.0;

      if (distanceMeters <= _triggerDistanceMeters) {
        _encountered.add(_resultKey(result));

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
        duration: const Duration(seconds: 6),
        backgroundColor:
            const Color(0xFF1C1C1E),
        content: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${result.title} is $distance away.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
        result.isDrink ? 'drinks' : 'venues';

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the Dining Unhinged review.',
          ),
        ),
      );
    }
  }

  Future<void> _stopCrawl() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _running = false;
      _loading = false;
      _currentPosition = null;
      _results = [];
      _encountered.clear();
      _error = null;
    });
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
                          ? 'Watching for reviewed spots within $_triggerDistanceText.'
                          : 'Start Crawl to begin watching your route.',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
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
                    if (_running) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        '$encounteredCount encountered · '
                        '${_results.length} reviewed spots loaded',
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
                        color: Color(
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
              if (_running &&
                  _results.isNotEmpty)
                const Text(
                  'REVIEWED SPOTS',
                  style:
                      TextStyle(
                    color:
                        Color(0xFFD4AF37),
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing:
                        1.5,
                  ),
                ),
              if (_running &&
                  _results.isNotEmpty)
                const SizedBox(
                  height: 10,
                ),
              if (_running)
                ..._sortedResults()
                    .take(10)
                    .map(
                      (result) =>
                          _CrawlResultTile(
                        result: result,
                        encountered:
                            _encountered
                                .contains(
                          _resultKey(
                            result,
                          ),
                        ),
                        onTap: () =>
                            _openReview(
                          result,
                        ),
                        useImperial:
                            _usesImperial,
                      ),
                    ),
              if (_running &&
                  _results.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.only(
                    top: 30,
                  ),
                  child: Text(
                    'No reviewed spots with valid coordinates were found.',
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
                          (_, __, ___) =>
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