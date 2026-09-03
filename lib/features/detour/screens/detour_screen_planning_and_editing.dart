part of 'detour_screen.dart';

extension _DetourPlanningAndEditing on _DetourScreenState {
  void _updatePreferences(
    DetourPreferences preferences,
  ) {
    _updateState(() {
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

    _updateState(() {
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

      _updateState(() {
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

      _updateState(() {});

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

      _updateState(() {
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

      for (final candidate in candidates) {
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
        error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on GoogleRoutesException catch (
        error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on GooglePlacesException catch (
        error) {
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
        _updateState(() {
          _planning = false;
        });
      }
    }
  }

  void _startEditingRoute() {
    if (_optimizedStops.isEmpty || _planning) {
      return;
    }

    _updateState(() {
      _editingRoute = true;
      _editingStops = List<DetourVenue>.from(
        _optimizedStops,
      );
    });
  }

  void _cancelEditingRoute() {
    _updateState(() {
      _editingRoute = false;
      _editingStops = [];
    });
  }

  void _reorderEditingStops(
    int oldIndex,
    int newIndex,
  ) {
    _updateState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final stop = _editingStops.removeAt(oldIndex);
      _editingStops.insert(newIndex, stop);
    });
  }

  void _removeEditingStop(int index) {
    _updateState(() {
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
    var searchResults =
        <CrawlLocationSearchResult>[];
    var knownReviews =
        <DiningUnhingedReview>[];

    try {
      try {
        knownReviews =
            await DiningUnhingedReviewService(
          apiClient: ApiClient(),
        ).fetchReviews();
      } catch (error) {
        debugPrint(
          'DETOUR KNOWN REVIEWED VENUES FAILED: '
          '$error',
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
            builder: (
              context,
              setDialogState,
            ) {
              Future<void> search(
                String value,
              ) async {
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
                      await _searchDestinationPlaces(
                    query,
                  );

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

              final filteredKnownReviews =
                  knownReviews.where((review) {
                final query =
                    controller.text.trim().toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                final name =
                    review.venueName?.toLowerCase() ?? '';
                final address =
                    review.address?.toLowerCase() ?? '';
                final city =
                    review.city?.toLowerCase() ?? '';

                return name.contains(query) ||
                    address.contains(query) ||
                    city.contains(query);
              }).toList();

              return AlertDialog(
                backgroundColor:
                    const Color(0xFF1C1C1E),
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
                    constraints:
                        const BoxConstraints(
                      maxHeight: 560,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
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
                          decoration:
                              InputDecoration(
                            hintText:
                                'Search for a stop',
                            hintStyle:
                                const TextStyle(
                              color: Colors.white38,
                            ),
                            prefixIcon:
                                const Icon(
                              Icons.search,
                              color:
                                  Color(0xFFD4AF37),
                            ),
                            suffixIcon: searching
                                ? const Padding(
                                    padding:
                                        EdgeInsets.all(
                                      12,
                                    ),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(
                                          0xFFD4AF37,
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor:
                                const Color(
                              0xFF0D0D0F,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                              borderSide:
                                  const BorderSide(
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
                              if (filteredKnownReviews
                                  .isNotEmpty) ...[
                                const Padding(
                                  padding:
                                      EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'REVIEWED BY DINING UNHINGED',
                                    style: TextStyle(
                                      color: Color(
                                        0xFFD4AF37,
                                      ),
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w900,
                                      letterSpacing:
                                          1.2,
                                    ),
                                  ),
                                ),
                                for (
                                  var index = 0;
                                  index <
                                      filteredKnownReviews
                                          .length;
                                  index++
                                ) ...[
                                  _buildKnownReviewTile(
                                    filteredKnownReviews[
                                        index],
                                    onTap: () {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(
                                        _AddStopSelection
                                            .review(
                                          filteredKnownReviews[
                                              index],
                                        ),
                                      );
                                    },
                                  ),
                                  if (index !=
                                      filteredKnownReviews
                                              .length -
                                          1)
                                    const Divider(
                                      color:
                                          Colors.white10,
                                      height: 1,
                                    ),
                                ],
                                const SizedBox(
                                  height: 16,
                                ),
                              ] else if (
                                  loadingKnownVenues) ...[
                                const Padding(
                                  padding:
                                      EdgeInsets.all(
                                    18,
                                  ),
                                  child: Center(
                                    child:
                                        CircularProgressIndicator(
                                      color: Color(
                                        0xFFD4AF37,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (
                                  controller.text
                                      .trim()
                                      .isEmpty) ...[
                                const Padding(
                                  padding:
                                      EdgeInsets.only(
                                    left: 4,
                                    bottom: 16,
                                  ),
                                  child: Text(
                                    'No known reviewed venues loaded.',
                                    style: TextStyle(
                                      color:
                                          Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              if (searchResults
                                  .isNotEmpty) ...[
                                const Padding(
                                  padding:
                                      EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'OTHER LOCATIONS',
                                    style: TextStyle(
                                      color:
                                          Colors.white54,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w900,
                                      letterSpacing:
                                          1.2,
                                    ),
                                  ),
                                ),
                                for (
                                  var index = 0;
                                  index <
                                      searchResults
                                          .length;
                                  index++
                                ) ...[
                                  _buildAddStopSearchTile(
                                    searchResults[
                                        index],
                                    onTap: () {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(
                                        _AddStopSelection
                                            .location(
                                          searchResults[
                                              index],
                                        ),
                                      );
                                    },
                                  ),
                                  if (index !=
                                      searchResults.length -
                                          1)
                                    const Divider(
                                      color:
                                          Colors.white10,
                                      height: 1,
                                    ),
                                ],
                              ] else if (
                                  !searching &&
                                  controller.text
                                      .trim()
                                      .isNotEmpty &&
                                  filteredKnownReviews
                                      .isEmpty) ...[
                                const Padding(
                                  padding:
                                      EdgeInsets.all(
                                    12,
                                  ),
                                  child: Text(
                                    'No locations found.',
                                    style: TextStyle(
                                      color:
                                          Colors.white38,
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
                        Navigator.of(
                      dialogContext,
                    ).pop(),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight:
                            FontWeight.w800,
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
          ? _venueFromDiningUnhingedReview(
              selected.review!,
            )
          : _venueFromSearchResult(
              selected.location!,
            );

      if (_editingStops.any(
        (existing) =>
            (stop.placeId.isNotEmpty &&
                existing.placeId ==
                    stop.placeId) ||
            ((existing.latitude -
                        stop.latitude)
                    .abs() <
                0.0001 &&
                (existing.longitude -
                            stop.longitude)
                        .abs() <
                    0.0001),
      )) {
        _showMessage(
          'That stop is already on your route.',
        );
        return;
      }

      _updateState(() {
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
    ]
        .whereType<String>()
        .where(
          (value) => value.isNotEmpty,
        )
        .join(', ');

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 5,
      ),
      leading: const CircleAvatar(
        backgroundColor:
            Color(0xFF0D0D0F),
        child: Icon(
          Icons.restaurant,
          color: Color(0xFFD4AF37),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              review.venueName ??
                  review.title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
          if (rating != null) ...[
            const SizedBox(width: 8),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight:
                    FontWeight.w900,
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
            ? (review.address ??
                'Dining Unhinged review')
            : location,
        maxLines: 2,
        overflow:
            TextOverflow.ellipsis,
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
      contentPadding:
          const EdgeInsets.symmetric(
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
        overflow:
            TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.w700,
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
                fontSize: 12,
              ),
            ),
      onTap: onTap,
    );
  }

  DetourVenue _venueFromDiningUnhingedReview(
    DiningUnhingedReview review,
  ) {
    final venueId =
        review.venueId?.trim();

    final placeId =
        venueId != null &&
                venueId.isNotEmpty
            ? venueId
            : 'du_review_${review.reviewId}';

    return DetourVenue(
      placeId: placeId,
      name:
          review.venueName ??
          review.title,
      address: review.address,
      latitude: review.latitude,
      longitude: review.longitude,
      primaryType: review.venueType,
      types: const [],
      isOpenNow: null,
      diningUnhingedRating:
          review.rating,
      diningUnhingedReviewId:
          review.reviewId,
      diningUnhingedSlug:
          review.slug,
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

    _updateState(() {
      _planning = true;
    });

    try {
      const routeProvider =
          GoogleRoutesProvider();

      final waypoints =
          _editingStops
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

      _updateState(() {
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
    } on GoogleRoutesException catch (
        error) {
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
        _updateState(() {
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

      _updateState(() {
        _currentTripId = trip.id;
        _currentTripCreatedAt =
            trip.createdAt;
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
                  fontWeight:
                      FontWeight.w700,
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
                      _updateState(() {
                        _detourSaved = false;
                      });
                    },
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.white70,
                side:
                    const BorderSide(
                  color: Colors.white24,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
              child: const Text(
                'NOT NOW',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _planning
                  ? null
                  : _saveCurrentDetour,
              icon: const Icon(
                Icons.bookmark_border,
              ),
              label: const Text(
                'SAVE',
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFFD4AF37),
                foregroundColor:
                    const Color(0xFF0D0D0F),
                padding:
                    const EdgeInsets.symmetric(
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
}