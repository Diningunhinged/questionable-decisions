// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../crawl/models/crawl_location_search_result.dart';
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
import '../services/detour_location_tracking_service.dart';
import '../../../services/location_service.dart';
import '../../../services/notification_service.dart';

part 'detour_screen_detour_tracking.dart';
part 'detour_screen_destination_search.dart';
part 'detour_screen_planning_and_editing.dart';
part 'detour_screen_destination_ui.dart';
part 'detour_screen_preferences_ui.dart';
part 'detour_screen_route_ui.dart';
part 'detour_screen_stops_and_tracking_ui.dart';

class _AddStopSelection {
  const _AddStopSelection.review(this.review) : location = null;

  const _AddStopSelection.location(this.location) : review = null;

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
  final http.Client _destinationSearchClient = http.Client();
  Timer? _destinationSearchDebounce;
  int _destinationSearchRequest = 0;

  final TextEditingController _destinationController =
      TextEditingController();

  final FocusNode _destinationFocusNode = FocusNode();

  DetourEndpoint? _startingPoint;
  DetourEndpoint? _destination;

  List<CrawlLocationSearchResult> _searchResults = [];

  List<DetourVenue> _optimizedStops = [];

  bool _editingRoute = false;
  List<DetourVenue> _editingStops = [];

  GoogleMapController? _detourMapController;

  DetourPreferences _preferences = const DetourPreferences();

  DetourRoute? _route;
  bool _planning = false;

  bool _searching = false;
  bool _loadingCurrentLocation = false;
  bool _loadingDestinations = true;
  bool _showPreferences = false;
  bool _detourSaved = false;
  String? _currentTripId;
  DateTime? _currentTripCreatedAt;

  static const double _encounterDistanceMeters = 500.0;
  static const double _arrivalDistanceMeters = 50.0;

  bool _detourActive = false;
  Position? _detourPosition;
  double? _distanceToNextStopMeters;
  int _activeStopIndex = 0;
  bool _detourProximityNotificationSent = false;
  bool _detourCompleted = false;

  void _updateState(VoidCallback callback) {
    setState(callback);
  }

  @override
  void initState() {
    super.initState();

    _loadDestinations();
  }

  @override
  void dispose() {
    DetourLocationTrackingService.stop();
    _destinationSearchDebounce?.cancel();
    _destinationSearchClient.close();
    _detourMapController?.dispose();
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
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
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            32,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 22),
            _buildRouteCard(),
            const SizedBox(height: 18),
            if (_searchResults.isNotEmpty) ...[
              _buildSearchResults(),
              const SizedBox(height: 18),
            ],
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
              const SizedBox(height: 18),
              _buildDetourTrackingActions(),
            ],
            const SizedBox(height: 22),
            _buildPlanButton(),
          ],
        ),
      ),
    );
  }
}

class _DestinationSearchException implements Exception {
  const _DestinationSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}