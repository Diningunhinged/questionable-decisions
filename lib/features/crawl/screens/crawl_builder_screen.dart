import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/nearby_result.dart';
import '../../../services/dining_unhinged_api.dart';
import '../../../screens/crawl_screen.dart';
import '../models/crawl_configuration.dart';
import '../models/crawl_starting_point.dart';

class CrawlBuilderScreen extends StatefulWidget {
  const CrawlBuilderScreen({
    super.key,
    required this.configuration,
    required this.startingPoint,
  });

  final CrawlConfiguration configuration;
  final CrawlStartingPoint startingPoint;

  @override
  State<CrawlBuilderScreen> createState() =>
      _CrawlBuilderScreenState();
}

class _CrawlBuilderScreenState
    extends State<CrawlBuilderScreen> {
  final DiningUnhingedApi _api =
      DiningUnhingedApi();

  GoogleMapController? _mapController;

  List<NearbyResult> _venues = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buildCrawl();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _buildCrawl() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results =
          await _api.fetchNearbyResults();

      final eligible = results
          .where(_isEligibleVenue)
          .toList();

      eligible.sort(
        (a, b) => _distanceFromStartingPoint(a)
            .compareTo(
          _distanceFromStartingPoint(b),
        ),
      );

      final selected = _selectUniqueVenues(
        eligible,
        widget.configuration.stopCount,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _venues = selected;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitMapToCrawl();
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<NearbyResult> _selectUniqueVenues(
    List<NearbyResult> eligible,
    int requestedStops,
  ) {
    final selected = <NearbyResult>[];
    final physicalLocations = <String>{};

    for (final result in eligible) {
      final location = result.venue.location;

      if (location == null || !location.isValid) {
        continue;
      }

      final key =
          '${location.latitude!.toStringAsFixed(5)},'
          '${location.longitude!.toStringAsFixed(5)}';

      if (!physicalLocations.add(key)) {
        continue;
      }

      selected.add(result);

      if (selected.length >= requestedStops) {
        break;
      }
    }

    return selected;
  }

  bool _isEligibleVenue(NearbyResult result) {
    if (result.isDrink) {
      return false;
    }

    final location = result.venue.location;

    if (location == null || !location.isValid) {
      return false;
    }

    if (!_matchesCategory(result)) {
      return false;
    }

    final distance =
        _distanceFromStartingPoint(result);

    return distance <=
        widget.configuration.walkingDistanceMeters;
  }

  bool _matchesCategory(NearbyResult result) {
    final categories =
        widget.configuration.categories;

    if (categories.contains(
      CrawlCategory.anyCategory,
    )) {
      return true;
    }

    final value =
        (result.category ??
                result.venue.cuisine ??
                '')
            .trim()
            .toLowerCase();

    if (value.isEmpty) {
      return false;
    }

    for (final category in categories) {
      switch (category) {
        case CrawlCategory.breweries:
          if (_containsAny(value, [
            'brewery',
            'brewing',
            'beer',
          ])) {
            return true;
          }
          break;

        case CrawlCategory.cocktailBars:
          if (_containsAny(value, [
            'cocktail',
            'bar',
            'lounge',
          ])) {
            return true;
          }
          break;

        case CrawlCategory.restaurants:
          if (_containsAny(value, [
            'restaurant',
            'food',
            'bistro',
            'grill',
            'dining',
          ])) {
            return true;
          }
          break;

        case CrawlCategory.distilleries:
          if (_containsAny(value, [
            'distillery',
            'spirits',
          ])) {
            return true;
          }
          break;

        case CrawlCategory.wine:
          if (_containsAny(value, [
            'wine',
            'winery',
            'vineyard',
          ])) {
            return true;
          }
          break;

        case CrawlCategory.coffee:
          if (_containsAny(value, [
            'coffee',
            'cafe',
            'café',
          ])) {
            return true;
          }
          break;

        case CrawlCategory.surpriseMe:
          return true;

        case CrawlCategory.anyCategory:
          return true;
      }
    }

    return false;
  }

  bool _containsAny(
    String value,
    List<String> terms,
  ) {
    for (final term in terms) {
      if (value.contains(term)) {
        return true;
      }
    }

    return false;
  }

  double _distanceFromStartingPoint(
    NearbyResult result,
  ) {
    final location =
        result.venue.location;

    if (location == null ||
        !location.isValid) {
      return double.infinity;
    }

    return _distanceInMeters(
      widget.startingPoint.latitude,
      widget.startingPoint.longitude,
      location.latitude!,
      location.longitude!,
    );
  }

  double _distanceInMeters(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadius = 6371000.0;
    const pi = 3.141592653589793;

    final lat1 =
        latitude1 * pi / 180;
    final lat2 =
        latitude2 * pi / 180;

    final deltaLat =
        (latitude2 - latitude1) *
            pi /
            180;

    final deltaLon =
        (longitude2 - longitude1) *
            pi /
            180;

    final sinLat =
        _mathSin(deltaLat / 2);

    final sinLon =
        _mathSin(deltaLon / 2);

    final a =
        sinLat * sinLat +
        _mathCos(lat1) *
            _mathCos(lat2) *
            sinLon *
            sinLon;

    final c =
        2 *
        _mathAtan2(
          _mathSqrt(a),
          _mathSqrt(1 - a),
        );

    return earthRadius * c;
  }

  void _fitMapToCrawl() {
    if (_mapController == null ||
        !mounted) {
      return;
    }

    final points = <LatLng>[
      LatLng(
        widget.startingPoint.latitude,
        widget.startingPoint.longitude,
      ),
      ..._venues
          .where(
            (venue) =>
                venue.venue.location?.isValid ??
                false,
          )
          .map(
            (venue) => LatLng(
              venue.venue.location!.latitude!,
              venue.venue.location!.longitude!,
            ),
          ),
    ];

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: points.first,
            zoom: 15,
          ),
        ),
      );

      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLon) {
        minLon = point.longitude;
      }

      if (point.longitude > maxLon) {
        maxLon = point.longitude;
      }
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            minLat,
            minLon,
          ),
          northeast: LatLng(
            maxLat,
            maxLon,
          ),
        ),
        70,
      ),
    );
  }

  Set<Marker> _markers() {
    final markers = <Marker>{
      Marker(
        markerId:
            const MarkerId('starting_point'),
        position: LatLng(
          widget.startingPoint.latitude,
          widget.startingPoint.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Starting Point',
          snippet:
              widget.startingPoint.name,
        ),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        ),
      ),
    };

    for (var index = 0;
        index < _venues.length;
        index++) {
      final venue = _venues[index];
      final location =
          venue.venue.location;

      if (location == null ||
          !location.isValid) {
        continue;
      }

      markers.add(
        Marker(
          markerId: MarkerId(
            'venue_$index',
          ),
          position: LatLng(
            location.latitude!,
            location.longitude!,
          ),
          infoWindow: InfoWindow(
            title:
                '${index + 1}. ${venue.title}',
            snippet:
                venue.venue.name,
          ),
        ),
      );
    }

    return markers;
  }

  String _distanceText(
    double meters,
  ) {
    if (widget.configuration.distanceUnit ==
        DistanceUnit.imperial) {
      final miles =
          meters / 1609.344;

      if (miles < 0.1) {
        final feet =
            meters * 3.28084;

        return '${feet.round()} ft away';
      }

      return '${miles.toStringAsFixed(
        miles < 10 ? 1 : 0,
      )} mi away';
    }

    if (meters < 1000) {
      return '${meters.round()} m away';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  String _selectedDistanceText() {
    final meters =
        widget.configuration.walkingDistanceMeters;

    if (widget.configuration.distanceUnit ==
        DistanceUnit.imperial) {
      final miles =
          meters / 1609.344;

      if (miles < 0.1) {
        return '${(meters * 3.28084).round()} ft';
      }

      return '${miles.toStringAsFixed(
        miles < 10 ? 1 : 0,
      )} mi';
    }

    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _startCrawl() {
    if (_venues.isEmpty) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CrawlScreen(
          configuration: widget.configuration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startingPosition = LatLng(
      widget.startingPoint.latitude,
      widget.startingPoint.longitude,
    );

    return Scaffold(
      backgroundColor:
          const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        title: const Text(
          'YOUR CRAWL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            )
          : _error != null
              ? _errorView()
              : Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: GoogleMap(
                        initialCameraPosition:
                            CameraPosition(
                          target:
                              startingPosition,
                          zoom: 14,
                        ),
                        onMapCreated:
                            (controller) {
                          _mapController =
                              controller;
                          _fitMapToCrawl();
                        },
                        markers: _markers(),
                        myLocationButtonEnabled:
                            true,
                        myLocationEnabled:
                            true,
                        zoomControlsEnabled:
                            false,
                        mapToolbarEnabled:
                            false,
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: _crawlDetails(),
                    ),
                  ],
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFD4AF37),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'WE COULDN\'T BUILD YOUR CRAWL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _buildCrawl,
              child: const Text(
                'TRY AGAIN',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crawlDetails() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0F),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            widget.startingPoint.name,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _venues.isEmpty
                ? 'NO STOPS FOUND'
                : '${_venues.length} STOPS SELECTED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Searching within ${_selectedDistanceText()}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          if (_venues.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'We couldn\'t find enough eligible reviewed venues within your selected distance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount:
                    _venues.length,
                separatorBuilder:
                    (context, index) =>
                        const SizedBox(
                  height: 8,
                ),
                itemBuilder:
                    (context, index) {
                  final venue =
                      _venues[index];

                  final distance =
                      _distanceFromStartingPoint(
                    venue,
                  );

                  return Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF1C1C1E,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment:
                              Alignment
                                  .center,
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFD4AF37,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                          child: Text(
                            '${index + 1}',
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF0D0D0F,
                              ),
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                venue.title,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors
                                          .white,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                _distanceText(
                                  distance,
                                ),
                                style:
                                    const TextStyle(
                                  color:
                                      Colors
                                          .white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons
                              .drag_indicator,
                          color:
                              Colors.white24,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed:
                  _venues.isEmpty
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
              ),
              child: const Text(
                'START CRAWL',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _mathSin(double value) {
  var term = value;
  var result = value;

  for (var n = 1; n <= 10; n++) {
    term *=
        -value *
        value /
        ((2 * n) * (2 * n + 1));

    result += term;
  }

  return result;
}

double _mathCos(double value) {
  var term = 1.0;
  var result = 1.0;

  for (var n = 1; n <= 10; n++) {
    term *=
        -value *
        value /
        ((2 * n - 1) * (2 * n));

    result += term;
  }

  return result;
}

double _mathSqrt(double value) {
  if (value <= 0) {
    return 0;
  }

  var result = value;

  for (var i = 0; i < 12; i++) {
    result =
        (result + value / result) / 2;
  }

  return result;
}

double _mathAtan2(
  double y,
  double x,
) {
  if (x > 0) {
    return _atan(y / x);
  }

  if (x < 0 && y >= 0) {
    return _atan(y / x) +
        3.141592653589793;
  }

  if (x < 0 && y < 0) {
    return _atan(y / x) -
        3.141592653589793;
  }

  if (x == 0 && y > 0) {
    return 3.141592653589793 / 2;
  }

  if (x == 0 && y < 0) {
    return -3.141592653589793 / 2;
  }

  return 0;
}

double _atan(double value) {
  final absolute = value.abs();

  if (absolute <= 1) {
    var result = 0.0;
    var power = value;

    for (var n = 0; n < 20; n++) {
      final denominator =
          (2 * n + 1).toDouble();

      final term =
          power / denominator;

      result +=
          n.isEven ? term : -term;

      power *=
          value * value;
    }

    return result;
  }

  final result =
      3.141592653589793 / 2 -
          _atan(1 / absolute);

  return value < 0 ? -result : result;
}