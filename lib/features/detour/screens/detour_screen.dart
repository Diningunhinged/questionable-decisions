import 'package:flutter/material.dart';

import '../../crawl/models/crawl_location_search_result.dart';
import '../../crawl/services/crawl_location_search_service.dart';
import '../../crawl/services/nominatim_location_search_provider.dart';
import '../models/detour_endpoint.dart';
import '../models/detour_preferences.dart';
import '../services/detour_destination_store.dart';
import '../../../services/location_service.dart';

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

  DetourPreferences _preferences = const DetourPreferences();

  bool _searching = false;
  bool _loadingCurrentLocation = false;
  bool _loadingDestinations = true;
  bool _showPreferences = false;

  @override
  void initState() {
    super.initState();

    _searchService = CrawlLocationSearchService(
      provider: const NominatimLocationSearchProvider(),
    );

    _loadDestinations();
  }

  @override
  void dispose() {
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
      final position = await LocationService.getCurrentLocation();

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
    if (_startingPoint == null && _destination == null) {
      return;
    }

    setState(() {
      final oldStartingPoint = _startingPoint;

      _startingPoint = _destination;
      _destination = oldStartingPoint;

      _destinationController.text =
          _destination?.name ?? '';
    });
  }

  Future<void> _searchDestination(String query) async {
    final normalizedQuery = query.trim();

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
      final results = await _searchService.search(
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
    final destination = DetourEndpoint(
      name: result.name,
      address: result.address,
      latitude: result.latitude,
      longitude: result.longitude,
    );

    setState(() {
      _destination = destination;
      _destinationController.text = destination.name;
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
      _destinationController.text = destination.name;
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
    if (isSavedDetourDestination(destination)) {
      await removeDetourDestination(destination);
    } else {
      await saveDetourDestination(destination);
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

  void _planDetour() {
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

    _showMessage(
      'Detour setup complete. Route calculation is coming next.',
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
            const SizedBox(height: 22),
            _buildPlanButton(),
          ],
        ),
      ),
    );
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

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0F),
              borderRadius: BorderRadius.circular(12),
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
                      color: _startingPoint == null
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD4AF37),
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
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: _swapLocations,
          tooltip: 'Swap start and destination',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF0D0D0F),
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
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            suffixIcon: _destination != null
                ? IconButton(
                    onPressed: _clearDestination,
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.white54,
                    ),
                  )
                : _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.white10,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
        ),
        if (_destination != null)
          Padding(
            padding: const EdgeInsets.only(
              top: 8,
              left: 4,
            ),
            child: Text(
              _destination!.address ??
                  'Destination selected',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
              index < _searchResults.length;
              index++) ...[
            _buildSearchResultTile(
              _searchResults[index],
            ),
            if (index != _searchResults.length - 1)
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF0D0D0F),
        child: Icon(
          Icons.location_on_outlined,
          color: Color(0xFFD4AF37),
        ),
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
              ),
            ),
      onTap: () => _selectSearchResult(result),
    );
  }

  Widget _buildDestinationLists() {
    if (_loadingDestinations) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4AF37),
          ),
        ),
      );
    }

    final hasRecent =
        recentDetourDestinations.isNotEmpty;
    final hasSaved =
        savedDetourDestinations.isNotEmpty;

    if (!hasRecent && !hasSaved) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (hasRecent)
          _buildDestinationSection(
            title: 'RECENT DESTINATIONS',
            destinations: recentDetourDestinations,
          ),
        if (hasRecent && hasSaved)
          const SizedBox(height: 14),
        if (hasSaved)
          _buildDestinationSection(
            title: 'SAVED DESTINATIONS',
            destinations: savedDetourDestinations,
          ),
      ],
    );
  }

  Widget _buildDestinationSection({
    required String title,
    required List<DetourEndpoint> destinations,
  }) {
    return _buildSectionCard(
      title: title,
      child: Column(
        children: [
          for (var index = 0;
              index < destinations.length;
              index++) ...[
            _buildDestinationTile(
              destinations[index],
            ),
            if (index != destinations.length - 1)
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
        isSavedDetourDestination(destination);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
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
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: destination.address == null
          ? null
          : Text(
              destination.address!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            _toggleSavedDestination(destination),
        icon: Icon(
          saved
              ? Icons.bookmark
              : Icons.bookmark_border,
          color: const Color(0xFFD4AF37),
        ),
      ),
      onTap: () => _selectDestination(destination),
    );
  }

  Widget _buildPreferencesCard() {
    return _buildSectionCard(
      title: 'TRIP PREFERENCES',
      trailing: IconButton(
        onPressed: () {
          setState(() {
            _showPreferences = !_showPreferences;
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
          child: _preferenceSummaryItem(
            Icons.alt_route,
            '${_preferences.maximumDetourKm.toStringAsFixed(0)} km',
            'MAX DETOUR',
          ),
        ),
        Expanded(
          child: _preferenceSummaryItem(
            Icons.star_outline,
            _preferences.minimumRating
                .toStringAsFixed(1),
            'MIN RATING',
          ),
        ),
        Expanded(
          child: _preferenceSummaryItem(
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          value: _preferences.maximumDetourKm
              .clamp(1, 100),
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: const Color(0xFFD4AF37),
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
          value: _preferences.minimumRating
              .clamp(0, 5),
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: const Color(0xFFD4AF37),
          inactiveColor: Colors.white12,
          label:
              _preferences.minimumRating.toStringAsFixed(1),
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
          initialValue: _preferences.maximumStops,
          dropdownColor: const Color(0xFF1C1C1E),
          style: const TextStyle(
            color: Colors.white,
          ),
          decoration: _preferenceInputDecoration(),
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
            DropdownMenuItem(
              value: 6,
              child: Text('6 stops'),
            ),
            DropdownMenuItem(
              value: 7,
              child: Text('7 stops'),
            ),
            DropdownMenuItem(
              value: 8,
              child: Text('8 stops'),
            ),
            DropdownMenuItem(
              value: 9,
              child: Text('9 stops'),
            ),
            DropdownMenuItem(
              value: 10,
              child: Text('10 stops'),
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
          value: _preferences.openNowOnly,
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
          value: _preferences.avoidVisitedOrSaved,
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                avoidVisitedOrSaved: value,
              ),
            );
          },
        ),
        _buildSwitchTile(
          title: 'Allow overnight stops',
          subtitle:
              'Allow the future route planner to consider overnight stops.',
          value: _preferences.allowOvernightStops,
          onChanged: (value) {
            _updatePreferences(
              _preferences.copyWith(
                allowOvernightStops: value,
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
        SegmentedButton<DetourRoutePreference>(
          segments: const [
            ButtonSegment(
              value: DetourRoutePreference.flexible,
              label: Text('Flexible'),
              icon: Icon(
                Icons.alt_route,
              ),
            ),
            ButtonSegment(
              value: DetourRoutePreference.strict,
              label: Text('Strict'),
              icon: Icon(
                Icons.route,
              ),
            ),
          ],
          selected: {
            _preferences.routePreference,
          },
          onSelectionChanged: (selection) {
            _updatePreferences(
              _preferences.copyWith(
                routePreference: selection.first,
              ),
            );
          },
          style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(
                  WidgetState.selected,
                )) {
                  return const Color(0xFF0D0D0F);
                }

                return Colors.white70;
              },
            ),
            backgroundColor:
                WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(
                  WidgetState.selected,
                )) {
                  return const Color(0xFFD4AF37);
                }

                return const Color(0xFF0D0D0F);
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
      'Café',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map(
        (category) {
          final selected =
              _preferences.preferredCategories
                  .contains(category);

          return FilterChip(
            label: Text(category),
            selected: selected,
            onSelected: (value) {
              final updated =
                  Set<String>.from(
                _preferences.preferredCategories,
              );

              if (value) {
                updated.add(category);
              } else {
                updated.remove(category);
              }

              _updatePreferences(
                _preferences.copyWith(
                  preferredCategories: updated,
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
                  ? const Color(0xFF0D0D0F)
                  : Colors.white70,
              fontWeight: FontWeight.w700,
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
    required ValueChanged<bool> onChanged,
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

  InputDecoration _preferenceInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF0D0D0F),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.white10,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.white10,
        ),
      ),
    );
  }

  Widget _buildPlanButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _planDetour,
        style: FilledButton.styleFrom(
          backgroundColor:
              const Color(0xFFD4AF37),
          foregroundColor:
              const Color(0xFF0D0D0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(
          Icons.alt_route,
        ),
        label: const Text(
          'PLAN MY DETOUR',
          style: TextStyle(
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
        borderRadius: BorderRadius.circular(16),
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
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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