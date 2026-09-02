// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../crawl/models/crawl_location_search_result.dart';
import '../../crawl/services/crawl_location_search_service.dart';
import '../../crawl/services/nominatim_location_search_provider.dart';
import '../models/detour_endpoint.dart';
import '../models/detour_route.dart';
import '../models/detour_venue.dart';
import '../models/detour_preferences.dart';
import '../models/detour_trip.dart';
import '../models/dining_unhinged_review.dart';
import '../services/detour_destination_store.dart';
import '../services/detour_candidate_service.dart';
import '../services/detour_route_service.dart';
import '../services/detour_route_optimizer.dart';
import '../services/detour_trip_store.dart';
import '../services/dining_unhinged_review_service.dart';
import '../services/google_places_provider.dart';
import '../services/google_routes_provider.dart';
import '../../../services/location_service.dart';

class _AddStopSelection {
  const _AddStopSelection.review(this.review)
      : location = null;

  const _AddStopSelection.location(this.location)
      : review = null;

  final DiningUnhingedReview? review;
  final CrawlLocationSearchResult? location;

  bool get isReview => review != null;
}

class DetourScreen extends StatefulWidget {
  const DetourScreen({super.key});

  @override
  State<DetourScreen> createState() => _DetourScreenState();
}

class _DetourScreenState extends State<DetourScreen> {
  late final CrawlLocationSearchService _searchService;

  final TextEditingController _destinationController =
      TextEditingController();

  final FocusNode _destinationFocusNode = FocusNode();

  DetourEndpoint? _startingPoint;
  DetourEndpoint? _destination;

  List<CrawlLocationSearchResult> _searchResults = [];

  // Candidates returned by the detour search. The service returns the
  // eligible venues; the screen keeps them so they can be shown as stops.
  List<DetourVenue> _optimizedStops = [];

  bool _editingRoute = false;
  List<DetourVenue> _editingStops = [];

  GoogleMapController? _detourMapController;

  DetourPreferences _preferences =
      const DetourPreferences();

  DetourRoute? _route;
  bool _planning = false;

  bool _searching = false;
  bool _loadingCurrentLocation = false;
  bool _loadingDestinations = true;
  bool _showPreferences = false;
  bool _detourSaved = false;
  String? _currentTripId;
  DateTime? _currentTripCreatedAt;

  @override
  void initState() {
    super.initState();

    _searchService = CrawlLocationSearchService(
      provider:
          const NominatimLocationSearchProvider(),
    );

    _loadDestinations();
  }

  @override
  void dispose() {
    _detourMapController?.dispose();
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDestinations() async {
    await loadDetourDestinations();

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingDestinations = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingCurrentLocation) {
      return;
    }

    setState(() {
      _loadingCurrentLocation = true;
    });

    try {
      final position =
          await LocationService.getCurrentLocation();

      if (!mounted) {
        return;
      }

      setState(() {
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
        setState(() {
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

    setState(() {
      final oldStartingPoint =
          _startingPoint;

      _startingPoint = _destination;
      _destination = oldStartingPoint;

      _destinationController.text =
          _destination?.name ?? '';
    });
  }

  Future<void> _searchDestination(
    String query,
  ) async {
    final normalizedQuery =
        query.trim();

    if (normalizedQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });

      return;
    }

    setState(() {
      _searching = true;
    });

    try {
      final results =
          await _searchService.search(
        normalizedQuery,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = results;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
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
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  Future<void> _selectSearchResult(
    CrawlLocationSearchResult result,
  ) async {
    final destination =
        DetourEndpoint(
      name: result.name,
      address: result.address,
      latitude: result.latitude,
      longitude: result.longitude,
    );

    setState(() {
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

    setState(() {});
  }

  Future<void> _selectDestination(
    DetourEndpoint destination,
  ) async {
    setState(() {
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

    setState(() {});
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

    setState(() {});
  }

  void _clearDestination() {
    setState(() {
      _destination = null;
      _destinationController.clear();
      _searchResults = [];
    });
  }

  void _updatePreferences(
    DetourPreferences preferences,
  ) {
    setState(() {
      _preferences = preferences;
    });
  }

  Future<void> _planDetour() async {
    if (_startingPoint == null) {
      _showMessage(
        'Choose a starting location first.',
      );

      return;
    }

    if (_destination == null) {
      _showMessage(
        'Choose a destination first.',
      );

      return;
    }

    if (!_startingPoint!.isValid ||
        !_destination!.isValid) {
      _showMessage(
        'One of your locations is invalid.',
      );

      return;
    }

    if (_planning) {
      return;
    }

    setState(() {
      _planning = true;
      _route = null;
      _optimizedStops = [];
      _detourSaved = false;
      _currentTripId = null;
      _currentTripCreatedAt = null;
    });

    try {
      const routeProvider =
          GoogleRoutesProvider();

      const routeService =
          DetourRouteService(
        provider: routeProvider,
      );

      final route =
          await routeService.calculateRoute(
        start: _startingPoint!,
        destination: _destination!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _route = route;
      });

      const placesProvider =
          GooglePlacesProvider();

      final diningUnhingedReviewService =
          DiningUnhingedReviewService(
        apiClient: ApiClient(),
      );

      final candidateService =
          DetourCandidateService(
        placesProvider: placesProvider,
        diningUnhingedReviewService:
            diningUnhingedReviewService,
      );

      final candidates =
          await candidateService.findCandidates(
        route: route,
        preferences: _preferences,
      );

      if (!mounted) {
        return;
      }

      setState(() {
      });

      final optimizer = DetourRouteOptimizer(
        routingProvider: routeProvider,
      );

      final optimization =
          await optimizer.optimize(
        start: _startingPoint!,
        destination: _destination!,
        candidates: candidates,
        maximumStops: _preferences.maximumStops,
      );

      if (!mounted) {
        return;
      }

      final now = DateTime.now();

      setState(() {
        _route = optimization.route;
        _optimizedStops = optimization.stops;
        _currentTripId =
            'detour_trip_${now.microsecondsSinceEpoch}';
        _currentTripCreatedAt = now;
        _detourSaved = false;
      });

      debugPrint(
        'DETOUR OPTIMIZED STOPS: '
        '${optimization.stops.length}',
      );

      for (var index = 0;
          index < optimization.stops.length;
          index++) {
        final stop = optimization.stops[index];
        debugPrint(
          'DETOUR STOP ${index + 1}: '
          '${stop.name} | '
          'DU rating: ${stop.diningUnhingedRating}',
        );
      }

      for (final candidate
          in candidates) {
        final distanceToRoute =
            candidateService.geometryService
                .distanceToRouteMeters(
          geometry: route.geometry,
          latitude: candidate.latitude,
          longitude: candidate.longitude,
        );

        debugPrint(
          'DETOUR CANDIDATE: '
          '${candidate.name} | '
          'PLACE ID: ${candidate.placeId} | '
          'DU rating: '
          '${candidate.diningUnhingedRating} | '
          'lat: ${candidate.latitude} | '
          'lng: ${candidate.longitude} | '
          'distanceToRoute: '
          '${distanceToRoute.toStringAsFixed(0)}m',
        );
      }

      debugPrint(
        'DETOUR CANDIDATES FOUND: '
        '${candidates.length}',
      );
    } on DetourRouteException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on GoogleRoutesException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on GooglePlacesException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint(
        'DETOUR CANDIDATE SEARCH FAILED: '
        '$error',
      );

      _showMessage(
        'Could not calculate the detour. '
        'Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _planning = false;
        });
      }
    }
  }

  void _startEditingRoute() {
    if (_optimizedStops.isEmpty || _planning) {
      return;
    }

    setState(() {
      _editingRoute = true;
      _editingStops = List<DetourVenue>.from(
        _optimizedStops,
      );
    });
  }

  void _cancelEditingRoute() {
    setState(() {
      _editingRoute = false;
      _editingStops = [];
    });
  }

  void _reorderEditingStops(
    int oldIndex,
    int newIndex,
  ) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final stop = _editingStops.removeAt(oldIndex);
      _editingStops.insert(newIndex, stop);
    });
  }

  void _removeEditingStop(int index) {
    setState(() {
      _editingStops.removeAt(index);
    });
  }

  Future<void> _showAddStopDialog() async {
    if (_planning) {
      return;
    }

    final maximumStops =
        _preferences.maximumStops.clamp(1, 5);

    if (_editingStops.length >= maximumStops) {
      _showMessage(
        'You have reached your maximum of $maximumStops stops.',
      );
      return;
    }

    final controller = TextEditingController();
    final focusNode = FocusNode();
    var searching = false;
    var loadingKnownVenues = true;
    var searchResults = <CrawlLocationSearchResult>[];
    var knownReviews = <DiningUnhingedReview>[];

    try {
      try {
        knownReviews = await DiningUnhingedReviewService(
          apiClient: ApiClient(),
        ).fetchReviews();
      } catch (error) {
        debugPrint(
          'DETOUR KNOWN REVIEWED VENUES FAILED: $error',
        );
      }

      loadingKnownVenues = false;

      if (!mounted) {
        return;
      }

      final selected =
          await showDialog<_AddStopSelection>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> search(String value) async {
                final query = value.trim();

                if (query.isEmpty) {
                  setDialogState(() {
                    searchResults = [];
                    searching = false;
                  });
                  return;
                }

                setDialogState(() {
                  searching = true;
                });

                try {
                  final results =
                      await _searchService.search(query);

                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() {
                    searchResults = results;
                    searching = false;
                  });
                } catch (_) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  setDialogState(() {
                    searchResults = [];
                    searching = false;
                  });
                }
              }

              final filteredKnownReviews = knownReviews.where((review) {
                final query = controller.text.trim().toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                final name = review.venueName?.toLowerCase() ?? '';
                final address = review.address?.toLowerCase() ?? '';
                final city = review.city?.toLowerCase() ?? '';

                return name.contains(query) ||
                    address.contains(query) ||
                    city.contains(query);
              }).toList();

              return AlertDialog(
                backgroundColor: const Color(0xFF1C1C1E),
                title: const Text(
                  'ADD STOP',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 560,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          onChanged: (value) {
                            setDialogState(() {});
                            search(value);
                          },
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for a stop',
                            hintStyle: const TextStyle(
                              color: Colors.white38,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFFD4AF37),
                            ),
                            suffixIcon: searching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFF0D0D0F),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.white10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              if (filteredKnownReviews.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'REVIEWED BY DINING UNHINGED',
                                    style: TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                for (var index = 0;
                                    index < filteredKnownReviews.length;
                                    index++) ...[
                                  _buildKnownReviewTile(
                                    filteredKnownReviews[index],
                                    onTap: () {
                                      Navigator.of(dialogContext).pop(
                                        _AddStopSelection.review(
                                          filteredKnownReviews[index],
                                        ),
                                      );
                                    },
                                  ),
                                  if (index !=
                                      filteredKnownReviews.length - 1)
                                    const Divider(
                                      color: Colors.white10,
                                      height: 1,
                                    ),
                                ],
                                const SizedBox(height: 16),
                              ] else if (loadingKnownVenues) ...[
                                const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFD4AF37),
                                    ),
                                  ),
                                ),
                              ] else if (controller.text.trim().isEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(
                                    left: 4,
                                    bottom: 16,
                                  ),
                                  child: Text(
                                    'No known reviewed venues loaded.',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              if (searchResults.isNotEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'OTHER LOCATIONS',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                for (var index = 0;
                                    index < searchResults.length;
                                    index++) ...[
                                  _buildAddStopSearchTile(
                                    searchResults[index],
                                    onTap: () {
                                      Navigator.of(dialogContext).pop(
                                        _AddStopSelection.location(
                                          searchResults[index],
                                        ),
                                      );
                                    },
                                  ),
                                  if (index != searchResults.length - 1)
                                    const Divider(
                                      color: Colors.white10,
                                      height: 1,
                                    ),
                                ],
                              ] else if (!searching &&
                                  controller.text.trim().isNotEmpty &&
                                  filteredKnownReviews.isEmpty) ...[
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'No locations found.',
                                    style: TextStyle(
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selected == null || !mounted) {
        return;
      }

      final stop = selected.isReview
          ? _venueFromDiningUnhingedReview(selected.review!)
          : _venueFromSearchResult(selected.location!);

      if (_editingStops.any(
        (existing) =>
            (stop.placeId.isNotEmpty &&
                existing.placeId == stop.placeId) ||
            ((existing.latitude - stop.latitude).abs() < 0.0001 &&
                (existing.longitude - stop.longitude).abs() < 0.0001),
      )) {
        _showMessage('That stop is already on your route.');
        return;
      }

      setState(() {
        _editingStops.add(stop);
      });
    } finally {
      controller.dispose();
      focusNode.dispose();
    }
  }

  Widget _buildKnownReviewTile(
    DiningUnhingedReview review, {
    required VoidCallback onTap,
  }) {
    final rating = review.rating;
    final location = [
      review.city,
      review.province,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 5,
      ),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF0D0D0F),
        child: Icon(
          Icons.restaurant,
          color: Color(0xFFD4AF37),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              review.venueName ?? review.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (rating != null) ...[
            const SizedBox(width: 8),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Icon(
              Icons.star,
              size: 15,
              color: Color(0xFFD4AF37),
            ),
          ],
        ],
      ),
      subtitle: Text(
        location.isEmpty
            ? (review.address ?? 'Dining Unhinged review')
            : location,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.add_circle_outline,
        color: Color(0xFFD4AF37),
      ),
      onTap: onTap,
    );
  }

  Widget _buildAddStopSearchTile(
    CrawlLocationSearchResult result, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      leading: const Icon(
        Icons.location_on_outlined,
        color: Color(0xFFD4AF37),
      ),
      title: Text(
        result.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: result.address == null
          ? null
          : Text(
              result.address!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
      onTap: onTap,
    );
  }

  DetourVenue _venueFromDiningUnhingedReview(
    DiningUnhingedReview review,
  ) {
    final venueId = review.venueId?.trim();
    final placeId = venueId != null && venueId.isNotEmpty
        ? venueId
        : 'du_review_${review.reviewId}';

    return DetourVenue(
      placeId: placeId,
      name: review.venueName ?? review.title,
      address: review.address,
      latitude: review.latitude,
      longitude: review.longitude,
      primaryType: review.venueType,
      types: const [],
      isOpenNow: null,
      diningUnhingedRating: review.rating,
      diningUnhingedReviewId: review.reviewId,
      diningUnhingedSlug: review.slug,
    );
  }

  DetourVenue _venueFromSearchResult(
    CrawlLocationSearchResult selected,
  ) {
    return DetourVenue(
      placeId:
          'manual_${selected.latitude}_${selected.longitude}',
      name: selected.name,
      address: selected.address,
      latitude: selected.latitude,
      longitude: selected.longitude,
      primaryType: null,
      types: const [],
      isOpenNow: null,
    );
  }

  Future<void> _rebuildEditedRoute() async {
    if (_startingPoint == null ||
        _destination == null ||
        _planning) {
      return;
    }

    setState(() {
      _planning = true;
    });

    try {
      const routeProvider =
          GoogleRoutesProvider();

      final waypoints = _editingStops
          .map(
            (stop) => DetourEndpoint(
              name: stop.name,
              address: stop.address,
              latitude: stop.latitude,
              longitude: stop.longitude,
            ),
          )
          .toList();

      final route =
          await routeProvider.calculateRoute(
        start: _startingPoint!,
        destination: _destination!,
        waypoints: waypoints,
        optimizeWaypointOrder: false,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _route = route;
        _optimizedStops =
            List<DetourVenue>.from(
          _editingStops,
        );
        _editingRoute = false;
        _editingStops = [];
      });

      debugPrint(
        'DETOUR MANUAL ROUTE REBUILT: '
        '${_optimizedStops.length} stops',
      );
    } on GoogleRoutesException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint(
        'DETOUR MANUAL ROUTE REBUILD FAILED: '
        '$error',
      );

      _showMessage(
        'Could not rebuild the route. '
        'Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _planning = false;
        });
      }
    }
  }

  Future<void> _saveCurrentDetour() async {
    final start = _startingPoint;
    final destination = _destination;
    final route = _route;

    if (start == null ||
        destination == null ||
        route == null ||
        !start.isValid ||
        !destination.isValid ||
        !route.isValid) {
      _showMessage(
        'This detour is not ready to save.',
      );
      return;
    }

    final now = DateTime.now();

    final trip = DetourTrip.fromRoute(
      id:
          _currentTripId ??
          'detour_trip_${now.microsecondsSinceEpoch}',
      createdAt:
          _currentTripCreatedAt ?? now,
      updatedAt: now,
      start: start,
      destination: destination,
      stops: List<DetourVenue>.from(
        _optimizedStops,
      ),
      route: route,
    );

    try {
      await saveDetourTrip(trip);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentTripId = trip.id;
        _currentTripCreatedAt = trip.createdAt;
        _detourSaved = true;
      });

      _showMessage('Detour saved.');
    } catch (error) {
      debugPrint(
        'DETOUR SAVE FAILED: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not save this detour.',
      );
    }
  }

  Widget _buildDetourSaveActions() {
    if (_detourSaved) {
      return _buildSectionCard(
        title: 'DETOUR SAVED',
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'This detour is saved for later.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildSectionCard(
      title: 'KEEP THIS DETOUR?',
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _planning
                  ? null
                  : () {
                      setState(() {
                        _detourSaved = false;
                      });
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(
                  color: Colors.white24,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
              child: const Text(
                'NOT NOW',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed:
                  _planning ? null : _saveCurrentDetour,
              icon: const Icon(
                Icons.bookmark_border,
              ),
              label: const Text(
                'SAVE',
              ),
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFFD4AF37),
                foregroundColor:
                    const Color(0xFF0D0D0F),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0D0D0F),
        elevation: 0,
        title: const Text(
          'DETOUR',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            32,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRouteCard(),
            const SizedBox(height: 18),
            if (_searchResults.isNotEmpty)
              _buildSearchResults(),
            if (_searchResults.isNotEmpty)
              const SizedBox(height: 18),
            _buildDestinationLists(),
            const SizedBox(height: 18),
            _buildPreferencesCard(),
            if (_route != null) ...[
              const SizedBox(height: 18),
              _buildRouteResult(),
              const SizedBox(height: 18),
              _buildDetourStops(),
              const SizedBox(height: 18),
              _buildDetourSaveActions(),
            ],
            const SizedBox(height: 22),
            _buildPlanButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR ROUTE.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'OUR TERRIBLE SUGGESTIONS.',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tell us where you\'re going. '
          'We\'ll figure out where you should probably stop.',
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.65,
            ),
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          _buildStartingLocation(),
          const SizedBox(height: 14),
          _buildSwapButton(),
          const SizedBox(height: 14),
          _buildDestinationField(),
        ],
      ),
    );
  }

  Widget _buildStartingLocation() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'STARTING LOCATION',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _useCurrentLocation,
          borderRadius:
              BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0F),
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white10,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.my_location,
                  color: Color(0xFFD4AF37),
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _startingPoint?.name ??
                        'Use current location',
                    style: TextStyle(
                      color:
                          _startingPoint == null
                              ? Colors.white54
                              : Colors.white,
                      fontSize: 16,
                      fontWeight:
                          _startingPoint == null
                              ? FontWeight.w500
                              : FontWeight.w700,
                    ),
                  ),
                ),
                if (_loadingCurrentLocation)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          Color(0xFFD4AF37),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwapButton() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: _swapLocations,
          tooltip:
              'Swap start and destination',
          style: IconButton.styleFrom(
            backgroundColor:
                const Color(0xFF0D0D0F),
            side: const BorderSide(
              color: Colors.white10,
            ),
          ),
          icon: const Icon(
            Icons.swap_vert,
            color: Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'DESTINATION',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _destinationController,
          focusNode: _destinationFocusNode,
          onChanged: _searchDestination,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search destination',
            hintStyle: const TextStyle(
              color: Colors.white38,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFFD4AF37),
            ),
            suffixIcon:
                _destination != null
                    ? IconButton(
                        onPressed:
                            _clearDestination,
                        icon: const Icon(
                          Icons.clear,
                          color:
                              Colors.white54,
                        ),
                      )
                    : _searching
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              14,
                            ),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Color(
                                  0xFFD4AF37,
                                ),
                              ),
                            ),
                          )
                        : null,
            filled: true,
            fillColor:
                const Color(0xFF0D0D0F),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color: Colors.white10,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color: Colors.white10,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(12),
              borderSide:
                  const BorderSide(
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
        ),
        if (_destination != null)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 8,
              left: 4,
            ),
            child: Text(
              _destination!.address ??
                  'Destination selected',
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return _buildSectionCard(
      title: 'SEARCH RESULTS',
      child: Column(
        children: [
          for (var index = 0;
              index <
                  _searchResults.length;
              index++) ...[
            _buildSearchResultTile(
              _searchResults[index],
            ),
            if (index !=
                _searchResults.length - 1)
              const Divider(
                color: Colors.white10,
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(
    CrawlLocationSearchResult result,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      leading: const CircleAvatar(
        backgroundColor:
            Color(0xFF0D0D0F),
        child: Icon(
          Icons.location_on_outlined,
          color: Color(0xFFD4AF37),
        ),
      ),
      title: Text(
        result.name,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: result.address == null
          ? null
          : Text(
              result.address!,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
      onTap: () =>
          _selectSearchResult(result),
    );
  }

  Widget _buildDestinationLists() {
    if (_loadingDestinations) {
      return const SizedBox(
        height: 80,
        child: Center(
          child:
              CircularProgressIndicator(
            color: Color(0xFFD4AF37),
          ),
        ),
      );
    }

    final hasRecent =
        recentDetourDestinations
            .isNotEmpty;

    final hasSaved =
        savedDetourDestinations
            .isNotEmpty;

    if (!hasRecent && !hasSaved) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (hasRecent)
          _buildDestinationSection(
            title: 'RECENT DESTINATIONS',
            destinations:
                recentDetourDestinations,
          ),
        if (hasRecent && hasSaved)
          const SizedBox(height: 14),
        if (hasSaved)
          _buildDestinationSection(
            title: 'SAVED DESTINATIONS',
            destinations:
                savedDetourDestinations,
          ),
      ],
    );
  }

  Widget _buildDestinationSection({
    required String title,
    required List<DetourEndpoint>
        destinations,
  }) {
    return _buildSectionCard(
      title: title,
      child: Column(
        children: [
          for (var index = 0;
              index <
                  destinations.length;
              index++) ...[
            _buildDestinationTile(
              destinations[index],
            ),
            if (index !=
                destinations.length - 1)
              const Divider(
                color: Colors.white10,
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDestinationTile(
    DetourEndpoint destination,
  ) {
    final saved =
        isSavedDetourDestination(
      destination,
    );

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 3,
      ),
      leading: Icon(
        saved
            ? Icons.bookmark
            : Icons.history,
        color: const Color(0xFFD4AF37),
      ),
      title: Text(
        destination.name,
        maxLines: 1,
        overflow:
            TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: destination.address ==
              null
          ? null
          : Text(
              destination.address!,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
      trailing: IconButton(
        tooltip: saved
            ? 'Remove saved destination'
            : 'Save destination',
        onPressed: () =>
            _toggleSavedDestination(
          destination,
        ),
        icon: Icon(
          saved
              ? Icons.bookmark
              : Icons.bookmark_border,
          color:
              const Color(0xFFD4AF37),
        ),
      ),
      onTap: () =>
          _selectDestination(destination),
    );
  }

  Widget _buildPreferencesCard() {
    return _buildSectionCard(
      title: 'TRIP PREFERENCES',
      trailing: IconButton(
        onPressed: () {
          setState(() {
            _showPreferences =
                !_showPreferences;
          });
        },
        icon: Icon(
          _showPreferences
              ? Icons.expand_less
              : Icons.expand_more,
          color: const Color(0xFFD4AF37),
        ),
      ),
      child: Column(
        children: [
          _buildPreferenceSummary(),
          if (_showPreferences) ...[
            const SizedBox(height: 18),
            _buildPreferenceControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferenceSummary() {
    return Row(
      children: [
        Expanded(
          child:
              _preferenceSummaryItem(
            Icons.alt_route,
            '${_preferences.maximumDetourKm.toStringAsFixed(0)} km',
            'MAX DETOUR',
          ),
        ),
        Expanded(
          child:
              _preferenceSummaryItem(
            Icons.star_outline,
            _preferences.minimumRating
                .toStringAsFixed(1),
            'MIN RATING',
          ),
        ),
        Expanded(
          child:
              _preferenceSummaryItem(
            Icons.pin_drop_outlined,
            '${_preferences.maximumStops}',
            'MAX STOPS',
          ),
        ),
      ],
    );
  }

  Widget _preferenceSummaryItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFD4AF37),
          size: 22,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceControls() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'MAXIMUM ACCEPTABLE DETOUR',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        Slider(
          value: _preferences
              .maximumDetourKm
              .clamp(1, 100),
          min: 1,
          max: 100,
          divisions: 99,
          activeColor:
              const Color(0xFFD4AF37),
          inactiveColor: Colors.white12,
          label:
              '${_preferences.maximumDetourKm.toStringAsFixed(0)} km',
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                maximumDetourKm: value,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'MINIMUM DINING UNHINGED RATING',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        Slider(
          value: _preferences
              .minimumRating
              .clamp(0, 5),
          min: 0,
          max: 5,
          divisions: 10,
          activeColor:
              const Color(0xFFD4AF37),
          inactiveColor: Colors.white12,
          label: _preferences
              .minimumRating
              .toStringAsFixed(1),
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                minimumRating: value,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'MAXIMUM NUMBER OF STOPS',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        DropdownButtonFormField<int>(
          initialValue:
              _preferences.maximumStops,
          dropdownColor:
              const Color(0xFF1C1C1E),
          style: const TextStyle(
            color: Colors.white,
          ),
          decoration:
              _preferenceInputDecoration(),
          items: const [
            DropdownMenuItem(
              value: 1,
              child: Text('1 stop'),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('2 stops'),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('3 stops'),
            ),
            DropdownMenuItem(
              value: 4,
              child: Text('4 stops'),
            ),
            DropdownMenuItem(
              value: 5,
              child: Text('5 stops'),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            _updatePreferences(
              _preferences.copyWith(
                maximumStops: value,
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _buildSwitchTile(
          title: 'Open now only',
          subtitle:
              'Only consider venues currently open.',
          value:
              _preferences.openNowOnly,
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                openNowOnly: value,
              ),
            );
          },
        ),
        _buildSwitchTile(
          title: 'Avoid visited or saved',
          subtitle:
              'Skip places you have already saved or visited.',
          value: _preferences
              .avoidVisitedOrSaved,
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                avoidVisitedOrSaved:
                    value,
              ),
            );
          },
        ),
        _buildSwitchTile(
          title: 'Allow overnight stops',
          subtitle:
              'Allow the future route planner to consider overnight stops.',
          value: _preferences
              .allowOvernightStops,
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                allowOvernightStops:
                    value,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'ROUTE PREFERENCE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<
            DetourRoutePreference>(
          segments: const [
            ButtonSegment(
              value:
                  DetourRoutePreference
                      .flexible,
              label: Text('Flexible'),
              icon: Icon(
                Icons.alt_route,
              ),
            ),
            ButtonSegment(
              value:
                  DetourRoutePreference
                      .strict,
              label: Text('Strict'),
              icon: Icon(
                Icons.route,
              ),
            ),
          ],
          selected: {
            _preferences.routePreference,
          },
          onSelectionChanged:
              (selection) {
            _updatePreferences(
              _preferences.copyWith(
                routePreference:
                    selection.first,
              ),
            );
          },
          style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty
                    .resolveWith(
              (states) {
                if (states.contains(
                  WidgetState.selected,
                )) {
                  return const Color(
                    0xFF0D0D0F,
                  );
                }

                return Colors.white70;
              },
            ),
            backgroundColor:
                WidgetStateProperty
                    .resolveWith(
              (states) {
                if (states.contains(
                  WidgetState.selected,
                )) {
                  return const Color(
                    0xFFD4AF37,
                  );
                }

                return const Color(
                  0xFF0D0D0F,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PREFERRED CATEGORIES',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        _buildCategorySelector(),
      ],
    );
  }

  Widget _buildCategorySelector() {
    const categories = [
      'Restaurant',
      'Brewery',
      'Bar',
      'Cocktail',
      'Distillery',
      'CafÃƒÂ©',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map(
        (category) {
          final selected =
              _preferences
                  .preferredCategories
                  .contains(category);

          return FilterChip(
            label: Text(category),
            selected: selected,
            onSelected: (value) {
              final updated =
                  Set<String>.from(
                _preferences
                    .preferredCategories,
              );

              if (value) {
                updated.add(category);
              } else {
                updated.remove(category);
              }

              _updatePreferences(
                _preferences.copyWith(
                  preferredCategories:
                      updated,
                ),
              );
            },
            selectedColor:
                const Color(0xFFD4AF37),
            checkmarkColor:
                const Color(0xFF0D0D0F),
            backgroundColor:
                const Color(0xFF0D0D0F),
            side: const BorderSide(
              color: Colors.white10,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? const Color(
                      0xFF0D0D0F,
                    )
                  : Colors.white70,
              fontWeight:
                  FontWeight.w700,
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
        ),
      ),
      value: value,
      activeThumbColor:
          const Color(0xFF0D0D0F),
      activeTrackColor:
          const Color(0xFFD4AF37),
      inactiveThumbColor:
          Colors.white54,
      inactiveTrackColor:
          Colors.white12,
      onChanged: onChanged,
    );
  }

  InputDecoration
      _preferenceInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor:
          const Color(0xFF0D0D0F),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Colors.white10,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Colors.white10,
        ),
      ),
    );
  }

  Widget _buildRouteResult() {
    final route = _route;

    if (route == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionCard(
          title: 'ROUTE CALCULATED',
          child: Row(
            children: [
              Expanded(
                child: _routeSummaryItem(
                  Icons.route,
                  _formatDistance(
                    route.distanceKilometers,
                  ),
                  'DRIVING DISTANCE',
                ),
              ),
              Expanded(
                child: _routeSummaryItem(
                  Icons.schedule_outlined,
                  _formatDuration(
                    route.durationMinutes,
                  ),
                  'EST. DRIVE TIME',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _buildDetourMap(route),
      ],
    );
  }

  Widget _buildDetourMap(DetourRoute route) {
    final routePoints = route.geometry
        .where((point) => point.length == 2)
        .map(
          (point) => LatLng(
            point[0],
            point[1],
          ),
        )
        .toList();

    if (routePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final markers = <Marker>{};

    final startingPoint = _startingPoint;
    if (startingPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId(
            'detour_start',
          ),
          position: LatLng(
            startingPoint.latitude,
            startingPoint.longitude,
          ),
          infoWindow: const InfoWindow(
            title: 'START',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    for (var index = 0;
        index < _optimizedStops.length;
        index++) {
      final stop = _optimizedStops[index];

      markers.add(
        Marker(
          markerId: MarkerId(
            'detour_stop_$index',
          ),
          position: LatLng(
            stop.latitude,
            stop.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'STOP ${index + 1}',
            snippet: stop.name,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
        ),
      );
    }

    final destination = _destination;
    if (destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId(
            'detour_destination',
          ),
          position: LatLng(
            destination.latitude,
            destination.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'DESTINATION',
            snippet: destination.name,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    final polyline = Polyline(
      polylineId: const PolylineId(
        'detour_optimized_route',
      ),
      points: routePoints,
      width: 6,
      color: const Color(0xFFD4AF37),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 360,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: routePoints.first,
            zoom: 12,
          ),
          onMapCreated: (controller) {
            _detourMapController = controller;
            _fitDetourMap(routePoints);
          },
          markers: markers,
          polylines: {polyline},
          gestureRecognizers:
              <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          zoomControlsEnabled: false,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),
      ),
    );
  }

  Future<void> _fitDetourMap(
    List<LatLng> points,
  ) async {
    final controller = _detourMapController;

    if (controller == null || points.isEmpty) {
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    if ((maxLat - minLat).abs() < 0.001 &&
        (maxLng - minLng).abs() < 0.001) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          points.first,
          15,
        ),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        minLat,
        minLng,
      ),
      northeast: LatLng(
        maxLat,
        maxLng,
      ),
    );

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          50,
        ),
      );
    } catch (_) {
      await Future<void>.delayed(
        const Duration(milliseconds: 250),
      );

      if (!mounted ||
          _detourMapController != controller) {
        return;
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          50,
        ),
      );
    }
  }

  Widget _buildDetourStops() {
    final stopCount =
        _preferences.maximumStops.clamp(1, 5);

    if (_editingRoute) {
      return _buildEditingStops(stopCount);
    }

    final stops = _optimizedStops;

    return _buildSectionCard(
      title: 'OPTIMIZED STOPS',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${stops.length}/$stopCount',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed:
                _planning ? null : _startEditingRoute,
            style: TextButton.styleFrom(
              foregroundColor:
                  const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              minimumSize: Size.zero,
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'EDIT ROUTE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0;
              index < stops.length;
              index++) ...[
            _buildDetourStopTile(
              stops[index],
              index + 1,
            ),
            if (index != stops.length - 1)
              const Divider(
                color: Colors.white10,
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditingStops(int stopCount) {
    return _buildSectionCard(
      title: 'EDIT ROUTE',
      trailing: Text(
        '${_editingStops.length}/$stopCount',
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Column(
        children: [
          if (_editingStops.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _editingStops.length,
              onReorderItem: _reorderEditingStops,
              itemBuilder: (context, index) {
                final stop = _editingStops[index];

                return _buildEditableStopTile(
                  stop,
                  index,
                  key: ValueKey(
                    'detour-edit-${stop.placeId}',
                  ),
                );
              },
            ),
          if (_editingStops.isNotEmpty)
            const Divider(
              color: Colors.white10,
              height: 1,
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _planning ||
                          _editingStops.length >= stopCount
                      ? null
                      : _showAddStopDialog,
              icon: const Icon(Icons.add),
              label: Text(
                _editingStops.length >= stopCount
                    ? 'MAXIMUM STOPS REACHED'
                    : 'ADD STOP',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD4AF37),
                side: const BorderSide(
                  color: Color(0xFFD4AF37),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
            color: Colors.white10,
            height: 1,
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Drag stops to choose your own order.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _planning
                          ? null
                          : _cancelEditingRoute,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(
                      color: Colors.white24,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed:
                      _planning
                          ? null
                          : _rebuildEditedRoute,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFD4AF37),
                    foregroundColor:
                        const Color(0xFF0D0D0F),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                  child: _planning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Color(0xFF0D0D0F),
                          ),
                        )
                      : const Text(
                          'REBUILD ROUTE',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableStopTile(
    DetourVenue candidate,
    int index, {
    required Key key,
  }) {
    final rating = candidate.diningUnhingedRating;

    final ratingText = rating?.toStringAsFixed(1);

    return ListTile(
      key: key,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(
          Icons.drag_handle,
          color: Colors.white38,
        ),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor:
                const Color(0xFF0D0D0F),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              candidate.name,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      subtitle: ratingText == null
          ? null
          : Padding(
              padding:
                  const EdgeInsets.only(left: 42),
              child: Text(
                'Dining Unhinged rating: '
                '$ratingText',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
      trailing: IconButton(
        tooltip: 'Remove stop',
        onPressed: _planning
            ? null
            : () => _removeEditingStop(index),
        icon: const Icon(
          Icons.close,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildDetourStopTile(
    DetourVenue candidate,
    int stopNumber,
  ) {
    final rating = candidate.diningUnhingedRating;

    final ratingText = rating?.toStringAsFixed(1);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF0D0D0F),
        child: Text(
          '$stopNumber',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      title: Text(
        candidate.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: ratingText == null
          ? null
          : Text(
              'Dining Unhinged rating: $ratingText',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
      trailing: const Icon(
        Icons.alt_route,
        color: Color(0xFFD4AF37),
      ),
    );
  }

  Widget _routeSummaryItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFD4AF37),
          size: 22,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  String _formatDistance(
    double kilometers,
  ) {
    if (kilometers < 10) {
      return '${kilometers.toStringAsFixed(1)} km';
    }

    return '${kilometers.toStringAsFixed(0)} km';
  }

  String _formatDuration(
    double minutes,
  ) {
    final totalMinutes =
        minutes.round();

    final hours =
        totalMinutes ~/ 60;

    final remainingMinutes =
        totalMinutes % 60;

    if (hours == 0) {
      return '$remainingMinutes min';
    }

    if (remainingMinutes == 0) {
      return '$hours hr';
    }

    return '$hours hr '
        '$remainingMinutes min';
  }

  Widget _buildPlanButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed:
            _planning
                ? null
                : _planDetour,
        style:
            FilledButton.styleFrom(
          backgroundColor:
              const Color(0xFFD4AF37),
          foregroundColor:
              const Color(0xFF0D0D0F),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        icon: _planning
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(
                    0xFF0D0D0F,
                  ),
                ),
              )
            : const Icon(
                Icons.alt_route,
              ),
        label: Text(
          _planning
              ? 'CALCULATING ROUTE...'
              : 'PLAN MY DETOUR',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color:
                        Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
