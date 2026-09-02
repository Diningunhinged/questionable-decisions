import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/nearby_result.dart';
import '../../../services/dining_unhinged_api.dart';
import '../../../screens/crawl_screen.dart';
import '../models/crawl_configuration.dart';
import '../models/crawl_starting_point.dart';
import '../models/saved_crawl.dart';
import '../services/saved_store.dart';

enum _CrawlBuildMode {
  manual,
  decisionParalysis,
}

class CrawlBuilderScreen extends StatefulWidget {
  const CrawlBuilderScreen({
    super.key,
    required this.configuration,
    required this.startingPoint,
    this.editingCrawl,
  });

  final CrawlConfiguration configuration;
  final CrawlStartingPoint startingPoint;
  final SavedCrawl? editingCrawl;

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
  List<NearbyResult> _manualVenues = [];
  List<NearbyResult> _manualPool = [];

  _CrawlBuildMode _mode =
      _CrawlBuildMode.manual;

  bool _loading = false;
  bool _manualLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    if (widget.editingCrawl != null) {
      _mode = _CrawlBuildMode.manual;
      _manualVenues = List<NearbyResult>.from(
        widget.editingCrawl!.stops,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitMapToManualVenues();
        }
      });
    } else {
      _selectManualBuild();
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _selectDecisionParalysis() async {
    setState(() {
      _mode =
          _CrawlBuildMode.decisionParalysis;
      _loading = true;
      _error = null;
      _venues = [];
      _manualVenues = [];
    });

    await _buildDecisionParalysisCrawl();
  }

  Future<void> _selectManualBuild() async {
    setState(() {
      _mode = _CrawlBuildMode.manual;
      _manualLoading = true;
      _error = null;
      _venues = [];
      _manualVenues = [];
    });

    await _buildManualVenuePool();
  }

  Future<void> _buildDecisionParalysisCrawl() async {
    try {
      final results =
          await _api.fetchNearbyResults();

      final eligible = results
          .where(_isEligibleVenue)
          .toList();

      final selected = _selectRandomUniqueVenues(
        eligible,
        widget.configuration.stopCount,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _venues = selected;
        _loading = false;
        _error = null;
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
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

  Future<void> _buildManualVenuePool() async {
    try {
      final results =
          await _api.fetchNearbyResults();

      final eligible = results
          .where(_isEligibleVenue)
          .toList();

      final unique =
          _selectAllUniqueVenues(eligible);

      if (!mounted) {
        return;
      }

      setState(() {
        _manualPool = unique;

        // A new manual crawl starts with no stops selected.
        // When editing an existing crawl, preserve its saved stops.
        if (widget.editingCrawl == null) {
          _manualVenues = [];
        } else {
          _manualVenues =
              List<NearbyResult>.from(
            widget.editingCrawl!.stops,
          );
        }

        _manualLoading = false;
        _error = null;
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          _fitMapToManualVenues();
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _manualLoading = false;
        _error = error.toString();
      });
    }
  }

  String _manualVenueKey(NearbyResult venue) {
    final location = venue.venue.location;

    if (location != null && location.isValid) {
      return '${location.latitude!.toStringAsFixed(5)},'
          '${location.longitude!.toStringAsFixed(5)}';
    }

    return '${venue.type}:${venue.slug}';
  }

  List<NearbyResult> _availableManualVenues() {
    final selectedKeys = _manualVenues
        .map(_manualVenueKey)
        .toSet();

    return _manualPool
        .where(
          (venue) =>
              !selectedKeys.contains(
            _manualVenueKey(venue),
          ),
        )
        .toList();
  }

  void _addManualVenueFromMap(
    NearbyResult venue,
  ) {
    final stopCount =
        widget.configuration.stopCount;

    if (stopCount < 5 &&
        _manualVenues.length >= stopCount) {
      return;
    }

    final key = _manualVenueKey(venue);

    if (_manualVenues.any(
      (selected) =>
          _manualVenueKey(selected) == key,
    )) {
      return;
    }

    setState(() {
      _manualVenues.add(venue);
    });
  }

  void _addManualVenue(NearbyResult venue) {
    final stopCount =
        widget.configuration.stopCount;

    // 5+ means there is no artificial selection cap.
    if (stopCount < 5 &&
        _manualVenues.length >= stopCount) {
      return;
    }

    final key = _manualVenueKey(venue);

    if (_manualVenues
        .any((selected) =>
            _manualVenueKey(selected) == key)) {
      return;
    }

    setState(() {
      _manualVenues.add(venue);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fitMapToManualVenues();
      }
    });
  }

  List<NearbyResult> _selectRandomUniqueVenues(
    List<NearbyResult> eligible,
    int requestedStops,
  ) {
    final unique = <NearbyResult>[];
    final physicalLocations =
        <String>{};

    for (final result in eligible) {
      final location =
          result.venue.location;

      if (location == null ||
          !location.isValid) {
        continue;
      }

      final key =
          '${location.latitude!.toStringAsFixed(5)},'
          '${location.longitude!.toStringAsFixed(5)}';

      if (!physicalLocations.add(key)) {
        continue;
      }

      unique.add(result);
    }

    unique.shuffle();

    if (requestedStops >= 5 ||
        unique.length <= requestedStops) {
      return unique;
    }

    return unique.sublist(
      0,
      requestedStops,
    );
  }


  List<NearbyResult> _selectAllUniqueVenues(
    List<NearbyResult> eligible,
  ) {
    final selected = <NearbyResult>[];
    final physicalLocations =
        <String>{};

    for (final result in eligible) {
      final location =
          result.venue.location;

      if (location == null ||
          !location.isValid) {
        continue;
      }

      final key =
          '${location.latitude!.toStringAsFixed(5)},'
          '${location.longitude!.toStringAsFixed(5)}';

      if (!physicalLocations.add(key)) {
        continue;
      }

      selected.add(result);
    }

    return selected;
  }

  bool _isEligibleVenue(
    NearbyResult result,
  ) {
    if (result.isDrink) {
      return false;
    }

    final location =
        result.venue.location;

    if (location == null ||
        !location.isValid) {
      return false;
    }

    if (!_matchesCategory(result)) {
      return false;
    }

    final distance =
        _distanceFromStartingPoint(result);

    return distance <=
        widget.configuration
            .walkingDistanceMeters;
  }

  bool _matchesCategory(
    NearbyResult result,
  ) {
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
            'caf├⌐',
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
    _fitMapToVenues(_venues);
  }

  void _fitMapToManualVenues() {
    _fitMapToVenues(_manualVenues);
  }

  void _fitMapToVenues(
    List<NearbyResult> venues,
  ) {
    if (_mapController == null ||
        !mounted) {
      return;
    }

    final points = <LatLng>[
      LatLng(
        widget.startingPoint.latitude,
        widget.startingPoint.longitude,
      ),
      ...venues
          .where(
            (venue) =>
                venue.venue.location
                    ?.isValid ??
                false,
          )
          .map(
            (venue) => LatLng(
              venue.venue.location!
                  .latitude!,
              venue.venue.location!
                  .longitude!,
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
            const MarkerId(
          'starting_point',
        ),
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
            BitmapDescriptor
                .defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        ),
      ),
    };

    final venues = _mode ==
            _CrawlBuildMode.manual
        ? _manualPool
        : _venues;

    for (var index = 0;
        index < venues.length;
        index++) {
      final venue = venues[index];
      final location =
          venue.venue.location;

      if (location == null ||
          !location.isValid) {
        continue;
      }

      final isManual =
          _mode == _CrawlBuildMode.manual;

      final selected = isManual &&
          _manualVenues.any(
            (selectedVenue) =>
                _manualVenueKey(selectedVenue) ==
                _manualVenueKey(venue),
          );

      markers.add(
        Marker(
          markerId: MarkerId(
            'venue_${venue.type}_${venue.slug}',
          ),
          position: LatLng(
            location.latitude!,
            location.longitude!,
          ),
          icon: isManual
              ? BitmapDescriptor.defaultMarkerWithHue(
                  selected
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueYellow,
                )
              : BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: isManual
                ? venue.title
                : '${index + 1}. ${venue.title}',
            snippet:
                venue.venue.name,
          ),
          onTap: isManual
              ? () => _toggleManualVenueFromMap(
                    venue,
                  )
              : null,
        ),
      );
    }

    return markers;
  }

  void _toggleManualVenueFromMap(
    NearbyResult venue,
  ) {
    final key = _manualVenueKey(venue);
    final selectedIndex =
        _manualVenues.indexWhere(
      (selectedVenue) =>
          _manualVenueKey(selectedVenue) == key,
    );

    if (selectedIndex >= 0) {
      setState(() {
        _manualVenues.removeAt(selectedIndex);
      });
      return;
    }

    _addManualVenueFromMap(venue);
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
        widget.configuration
            .walkingDistanceMeters;

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
          configuration:
              widget.configuration,
        ),
      ),
    );
  }

  Future<void> _saveManualCrawl() async {
    if (_manualVenues.length < widget.configuration.stopCount) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Select at least '
              '${widget.configuration.stopCount} stops '
              'before saving.',
            ),
          ),
        );
      return;
    }

    final draft = await showDialog<_SaveCrawlDraft>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _SaveCrawlDialog(
          initialName: widget.editingCrawl?.name,
          initialDate: widget.editingCrawl?.plannedDate,
        );
      },
    );

    if (!mounted || draft == null) {
      return;
    }

    final crawl = SavedCrawl(
      id: widget.editingCrawl?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: draft.name,
      plannedDate: draft.plannedDate,
      configuration: widget.configuration,
      startingPoint: widget.startingPoint,
      stops: List<NearbyResult>.from(_manualVenues),
    );

    await saveCrawl(crawl);

    if (!mounted) {
      return;
    }

    if (widget.editingCrawl != null) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '"${draft.name}" saved to Saved Crawls.',
          ),
        ),
      );
  }

  void _startManualCrawl() {
    if (_manualVenues.isEmpty) {
      return;
    }

    if (_manualVenues.length <
        widget.configuration.stopCount) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Select at least '
              '${widget.configuration.stopCount} stops.',
            ),
          ),
        );

      return;
    }

    // Manual Build is authoritative. Pass the selected
    // venues in their current order to the Crawl screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CrawlScreen(
          configuration: widget.configuration,
          manualStops:
              List<NearbyResult>.from(
            _manualVenues,
          ),
          autoStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
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
        foregroundColor:
            Colors.white,
        title: const Text(
          'BUILD YOUR CRAWL',
          style: TextStyle(
            fontWeight:
                FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: _buildBuilderBody(
        startingPosition,
      ),
    );
  }

  Widget _buildBuilderBody(
    LatLng startingPosition,
  ) {
    final isManual =
        _mode ==
            _CrawlBuildMode.manual;

    final isLoading =
        isManual
            ? _manualLoading
            : _loading;

    final venues =
        isManual
            ? _manualVenues
            : _venues;

    return _error != null
        ? _errorView()
        : isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color:
                      Color(0xFFD4AF37),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    flex: isManual ? 3 : 5,
                    child:
                        GoogleMap(
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
                        _fitMapToVenues(
                          venues,
                        );
                      },
                      markers:
                          _markers(),
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
                    flex: isManual ? 7 : 5,
                    child:
                        isManual
                            ? _manualDetails()
                            : _decisionParalysisDetails(),
                  ),
                ],
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
              color:
                  Color(0xFFD4AF37),
              size: 48,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              'WE COULDN\'T BUILD YOUR CRAWL',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontWeight:
                    FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.white60,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            FilledButton(
              onPressed:
                  _mode ==
                          _CrawlBuildMode.manual
                      ? _selectManualBuild
                      : _selectDecisionParalysis,
              child:
                  const Text(
                'TRY AGAIN',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decisionParalysisDetails() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),
      decoration:
          const BoxDecoration(
        color:
            Color(0xFF0D0D0F),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'DECISION PARALYSIS',
            style:
                TextStyle(
              color:
                  Color(0xFFD4AF37),
              fontSize: 13,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            _venues.isEmpty
                ? 'NO STOPS FOUND'
                : '${_venues.length} STOPS SELECTED',
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 24,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            'Searching within '
            '${_selectedDistanceText()}',
            style:
                const TextStyle(
              color:
                  Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          if (_venues.isEmpty)
            const Expanded(
              child:
                  Center(
                child: Text(
                  'We couldn\'t find enough eligible reviewed venues within your selected distance.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white60,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child:
                  ListView.separated(
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

                  return _venueTile(
                    venue,
                    index:
                        index,
                    showDrag:
                        false,
                  );
                },
              ),
            ),
          const SizedBox(
            height: 14,
          ),
          _startButton(
            enabled:
                _venues.isNotEmpty,
            onPressed:
                _startCrawl,
            label:
                'START CRAWL',
          ),
        ],
      ),
    );
  }

  Widget _manualDetails() {
    final available = _availableManualVenues();
    final stopCount =
        widget.configuration.stopCount;
    final selectionCapReached =
        stopCount < 5 &&
        _manualVenues.length >= stopCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
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
          const Text(
            'MANUAL BUILD',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_manualVenues.length} STOPS SELECTED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stopCount >= 5
                ? 'Choose your stops from the available pool.'
                : 'Choose your stops. You need $stopCount.',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'AVAILABLE VENUES',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  flex: 3,
                  child: available.isEmpty
                      ? Center(
                          child: Text(
                            _manualPool.isEmpty
                                ? 'No eligible venues were found within your selected distance.'
                                : 'All available venues are selected.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: available.length,
                          separatorBuilder:
                              (context, index) =>
                                  const SizedBox(height: 8),
                          itemBuilder:
                              (context, index) {
                            final venue =
                                available[index];

                            return _availableManualVenueTile(
                              venue,
                              disabled:
                                  selectionCapReached,
                            );
                          },
                        ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'SELECTED STOPS',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  flex: 2,
                  child: _manualVenues.isEmpty
                      ? const Center(
                          child: Text(
                            'Select venues above to build your crawl.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          itemCount:
                              _manualVenues.length,
                          buildDefaultDragHandles: true,
                          onReorderItem:
                              _reorderManualVenues,
                          itemBuilder:
                              (context, index) {
                            final venue =
                                _manualVenues[index];

                            return _manualVenueTile(
                              venue,
                              index,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _manualVenues.length >=
                              stopCount
                          ? _saveManualCrawl
                          : null,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFFD4AF37),
                    side: const BorderSide(
                      color: Color(0xFFD4AF37),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'SAVE CRAWL',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _startButton(
                  enabled:
                      _manualVenues.length >=
                          stopCount,
                  onPressed: _startManualCrawl,
                  label: 'START CRAWL',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _availableManualVenueTile(
    NearbyResult venue, {
    required bool disabled,
  }) {
    final distance =
        _distanceFromStartingPoint(venue);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  venue.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _distanceText(distance),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: disabled
                ? null
                : () => _addManualVenue(venue),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xFFD4AF37),
              side: const BorderSide(
                color: Color(0xFFD4AF37),
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'ADD',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _venueTile(
    NearbyResult venue, {
    required int index,
    required bool showDrag,
  }) {
    final distance =
        _distanceFromStartingPoint(
      venue,
    );

    return Container(
      key:
          ValueKey(
        '${venue.type}:${venue.slug}:$index',
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF1C1C1E),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFD4AF37,
              ),
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child: Text(
              '${index + 1}',
              style:
                  const TextStyle(
                color:
                    Color(0xFF0D0D0F),
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  venue.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.w800,
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
                        Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (showDrag)
            const Icon(
              Icons.drag_indicator,
              color:
                  Colors.white24,
            ),
        ],
      ),
    );
  }

  Widget _manualVenueTile(
    NearbyResult venue,
    int index,
  ) {
    final distance =
        _distanceFromStartingPoint(
      venue,
    );

    return Container(
      key:
          ValueKey(
        '${venue.type}:${venue.slug}',
      ),
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF1C1C1E),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFD4AF37,
              ),
              borderRadius:
                  BorderRadius.circular(
                8,
              ),
            ),
            child: Text(
              '${index + 1}',
              style:
                  const TextStyle(
                color:
                    Color(0xFF0D0D0F),
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  venue.title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.w800,
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
                        Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove stop',
            onPressed: () {
              setState(() {
                _manualVenues.removeAt(index);
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _fitMapToManualVenues();
                }
              });
            },
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.white54,
            ),
          ),
          const Icon(
            Icons.drag_handle,
            color:
                Colors.white38,
          ),
        ],
      ),
    );
  }

  void _reorderManualVenues(
    int oldIndex,
    int newIndex,
  ) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final venue =
          _manualVenues.removeAt(
        oldIndex,
      );

      _manualVenues.insert(
        newIndex,
        venue,
      );
    });

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (mounted) {
        _fitMapToManualVenues();
      }
    });
  }

  Widget _startButton({
    required bool enabled,
    required VoidCallback onPressed,
    required String label,
  }) {
    return SizedBox(
      width:
          double.infinity,
      height: 52,
      child:
          FilledButton(
        onPressed:
            enabled
                ? onPressed
                : null,
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
        child:
            Text(
          label,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w900,
            letterSpacing:
                0.8,
          ),
        ),
      ),
    );
  }
}


class _SaveCrawlDraft {
  final String name;
  final DateTime plannedDate;

  const _SaveCrawlDraft({
    required this.name,
    required this.plannedDate,
  });
}

class _SaveCrawlDialog extends StatefulWidget {
  const _SaveCrawlDialog({
    this.initialName,
    this.initialDate,
  });

  final String? initialName;
  final DateTime? initialDate;

  @override
  State<_SaveCrawlDialog> createState() =>
      _SaveCrawlDialogState();
}

class _SaveCrawlDialogState
    extends State<_SaveCrawlDialog> {
  late final TextEditingController _nameController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName ?? '',
    );
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: (widget.initialDate != null &&
              widget.initialDate!.isBefore(DateTime.now()))
          ? widget.initialDate!
          : DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  void _save() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _SaveCrawlDraft(
        name: name,
        plannedDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: const Text(
        'SAVE YOUR CRAWL',
        style: TextStyle(
          color: Color(0xFFD4AF37),
          fontWeight: FontWeight.w900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(
              color: Colors.white,
            ),
            textCapitalization:
                TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Crawl name',
              labelStyle: TextStyle(
                color: Colors.white54,
              ),
              hintText:
                  'Friday Night Degeneracy',
              hintStyle: TextStyle(
                color: Colors.white24,
              ),
              enabledBorder:
                  UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white24,
                ),
              ),
              focusedBorder:
                  UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'PLANNED DATE',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            subtitle: Text(
              '${_selectedDate.year}-'
              '${_selectedDate.month.toString().padLeft(2, '0')}-'
              '${_selectedDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            trailing: const Icon(
              Icons.calendar_month,
              color: Color(0xFFD4AF37),
            ),
            onTap: _pickDate,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'CANCEL',
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor:
                const Color(0xFFD4AF37),
            foregroundColor:
                const Color(0xFF0D0D0F),
          ),
          child: Text(
            widget.initialName == null
                ? 'SAVE CRAWL'
                : 'UPDATE CRAWL',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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
  final absolute =
      value.abs();

  if (absolute <= 1) {
    var result = 0.0;
    var power = value;

    for (var n = 0; n < 20; n++) {
      final denominator =
          (2 * n + 1).toDouble();

      final term =
          power / denominator;

      result +=
          n.isEven
              ? term
              : -term;

      power *=
          value * value;
    }

    return result;
  }

  final result =
      3.141592653589793 / 2 -
          _atan(1 / absolute);

  return value < 0
      ? -result
      : result;
}