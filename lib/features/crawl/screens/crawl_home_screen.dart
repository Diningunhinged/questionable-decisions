import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/crawl_configuration.dart';
import '../models/crawl_location_search_result.dart';
import '../models/crawl_starting_point.dart';
import '../services/crawl_location_service.dart';
import '../services/crawl_test_locations.dart';
import '../widgets/crawl_location_search.dart';

class CrawlHomeScreen extends StatefulWidget {
  const CrawlHomeScreen({
    super.key,
  });

  @override
  State<CrawlHomeScreen> createState() =>
      _CrawlHomeScreenState();
}

class _CrawlHomeScreenState
    extends State<CrawlHomeScreen> {
  CrawlConfiguration _configuration =
      const CrawlConfiguration();

  CrawlStartingPoint? _startingPoint;

  bool _loadingLocation = false;

  String? _locationError;

  bool _showLocationSearch = false;

  late final TextEditingController _distanceController;

  final CrawlLocationService _locationService =
      const CrawlLocationService();

  @override
  void initState() {
    super.initState();

    _distanceController = TextEditingController(
      text: _formatDistance(
        _configuration.displayedWalkingDistance,
      ),
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'CRAWL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'BUILD YOUR CRAWL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You pick the parameters. '
                'We figure out where you should go.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('STARTING POINT'),
              const SizedBox(height: 10),
              _startingPointCard(),
              const SizedBox(height: 28),
              _sectionTitle('HOW QUESTIONABLE?'),
              const SizedBox(height: 10),
              _crawlSizeSelector(),
              const SizedBox(height: 28),
              _sectionTitle(
                'WHAT ARE WE LOOKING FOR?',
              ),
              const SizedBox(height: 10),
              _categorySelector(),
              const SizedBox(height: 28),
              _sectionTitle(
                'HOW FAR ARE WE WALKING?',
              ),
              const SizedBox(height: 10),
              _walkingDistanceSelector(),
              const SizedBox(height: 32),
              _startButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFD4AF37),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _startingPointCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.my_location,
                color: Color(0xFFD4AF37),
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STARTING HERE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_loadingLocation)
                      const Text(
                        'Getting your location...',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      )
                    else if (_locationError != null)
                      Text(
                        _locationError!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      )
                    else
                      Text(
                        _startingPoint?.name ??
                            'Current location',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _loadingLocation
                          ? null
                          : _useCurrentLocation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFFD4AF37),
                    side: const BorderSide(
                      color: Color(0xFFD4AF37),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                  ),
                  child: const Text(
                    'USE GPS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _toggleLocationSearch,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.white70,
                    side: const BorderSide(
                      color: Colors.white24,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                  ),
                  child: Text(
                    _showLocationSearch
                        ? 'HIDE SEARCH'
                        : 'SEARCH',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    _useSpirosTestLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.white70,
                  side: const BorderSide(
                    color: Colors.white24,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                ),
                child: const Text(
                  'TEST: SPIRO\'S',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          if (_showLocationSearch) ...[
            const SizedBox(height: 16),
            CrawlLocationSearch(
              onLocationSelected:
                  _selectSearchResult,
            ),
          ],
        ],
      ),
    );
  }

  Widget _crawlSizeSelector() {
    return Column(
      children: [
        _optionTile(
          title: 'Responsible',
          subtitle: '2 stops',
          selected:
              _configuration.size ==
                  CrawlSize.responsible,
          onTap: () {
            _setSize(
              CrawlSize.responsible,
            );
          },
        ),
        _optionTile(
          title: 'Questionable',
          subtitle: '3 stops',
          selected:
              _configuration.size ==
                  CrawlSize.questionable,
          onTap: () {
            _setSize(
              CrawlSize.questionable,
            );
          },
        ),
        _optionTile(
          title: 'Unhinged',
          subtitle: '4 stops',
          selected:
              _configuration.size ==
                  CrawlSize.unhinged,
          onTap: () {
            _setSize(
              CrawlSize.unhinged,
            );
          },
        ),
        _optionTile(
          title: 'See You Tomorrow',
          subtitle: '5+ stops',
          selected:
              _configuration.size ==
                  CrawlSize.seeYouTomorrow,
          onTap: () {
            _setSize(
              CrawlSize.seeYouTomorrow,
            );
          },
        ),
      ],
    );
  }

  Widget _categorySelector() {
    return Column(
      children: [
        _categoryTile(
          'Breweries',
          CrawlCategory.breweries,
        ),
        _categoryTile(
          'Cocktail Bars',
          CrawlCategory.cocktailBars,
        ),
        _categoryTile(
          'Restaurants',
          CrawlCategory.restaurants,
        ),
        _categoryTile(
          'Distilleries',
          CrawlCategory.distilleries,
        ),
        _categoryTile(
          'Wine',
          CrawlCategory.wine,
        ),
        _categoryTile(
          'Coffee',
          CrawlCategory.coffee,
        ),
        _categoryTile(
          'Surprise Me',
          CrawlCategory.surpriseMe,
        ),
        _categoryTile(
          'Any Category',
          CrawlCategory.anyCategory,
        ),
      ],
    );
  }

  Widget _categoryTile(
    String title,
    CrawlCategory category,
  ) {
    final selected =
        _configuration.categories.contains(
      category,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? const Color(0xFFD4AF37)
              : Colors.white10,
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        activeColor: const Color(0xFFD4AF37),
        checkColor: const Color(0xFF0D0D0F),
        controlAffinity:
            ListTileControlAffinity.leading,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        onChanged: (_) {
          _toggleCategory(category);
        },
      ),
    );
  }

  Widget _walkingDistanceSelector() {
    final unit = _configuration.distanceUnit;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
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
              const Text(
                'DISTANCE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _unitButton(
                label: 'KM',
                selected:
                    unit == DistanceUnit.metric,
                onTap: () {
                  _setDistanceUnit(
                    DistanceUnit.metric,
                  );
                },
              ),
              const SizedBox(width: 8),
              _unitButton(
                label: 'MI',
                selected:
                    unit == DistanceUnit.imperial,
                onTap: () {
                  _setDistanceUnit(
                    DistanceUnit.imperial,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _distanceController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0D0D0F),
              suffixText:
                  _configuration
                      .walkingDistanceUnitLabel,
              suffixStyle: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
              ),
              hintText: 'Enter distance',
              hintStyle: const TextStyle(
                color: Colors.white30,
              ),
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
            onChanged: (_) {
              _updateWalkingDistance();
            },
            onSubmitted: (_) {
              _updateWalkingDistance();
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Choose any distance you are willing to walk.',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD4AF37)
              : const Color(0xFF0D0D0F),
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFFD4AF37)
                : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF0D0D0F)
                : Colors.white70,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? const Color(0xFFD4AF37)
              : Colors.white10,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
          ),
        ),
        trailing: Icon(
          selected
              ? Icons.radio_button_checked
              : Icons.radio_button_off,
          color: selected
              ? const Color(0xFFD4AF37)
              : Colors.white30,
        ),
      ),
    );
  }

  Widget _startButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _startCrawl,
        style: FilledButton.styleFrom(
          backgroundColor:
              const Color(0xFFD4AF37),
          foregroundColor:
              const Color(0xFF0D0D0F),
          padding:
              const EdgeInsets.symmetric(
            vertical: 17,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'BUILD MY CRAWL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  void _setSize(CrawlSize size) {
    setState(() {
      _configuration =
          _configuration.copyWith(
        size: size,
      );
    });
  }

  void _toggleCategory(
    CrawlCategory category,
  ) {
    final current =
        Set<CrawlCategory>.from(
      _configuration.categories,
    );

    if (category ==
        CrawlCategory.anyCategory) {
      current
        ..clear()
        ..add(CrawlCategory.anyCategory);
    } else {
      current.remove(
        CrawlCategory.anyCategory,
      );

      if (current.contains(category)) {
        current.remove(category);
      } else {
        current.add(category);
      }

      if (current.isEmpty) {
        current.add(
          CrawlCategory.anyCategory,
        );
      }
    }

    setState(() {
      _configuration =
          _configuration.copyWith(
        categories: current,
      );
    });
  }

  void _setDistanceUnit(
    DistanceUnit unit,
  ) {
    if (_configuration.distanceUnit ==
        unit) {
      return;
    }

    setState(() {
      _configuration =
          _configuration.copyWith(
        distanceUnit: unit,
      );

      _distanceController.text =
          _formatDistance(
        _configuration
            .displayedWalkingDistance,
      );

      _distanceController.selection =
          TextSelection.collapsed(
        offset:
            _distanceController.text.length,
      );
    });
  }

  void _updateWalkingDistance() {
    final input =
        _distanceController.text.trim();

    if (input.isEmpty) {
      return;
    }

    final value = double.tryParse(input);

    if (value == null || value <= 0) {
      return;
    }

    final meters =
        _configuration.distanceUnit ==
                DistanceUnit.metric
            ? value * 1000
            : value * 1609.344;

    setState(() {
      _configuration =
          _configuration.copyWith(
        walkingDistanceMeters: meters,
      );
    });
  }

  String _formatDistance(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    if (value < 10) {
      return value.toStringAsFixed(2);
    }

    return value.toStringAsFixed(1);
  }

  void _toggleLocationSearch() {
    setState(() {
      _showLocationSearch =
          !_showLocationSearch;
      _locationError = null;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final startingPoint =
          await _locationService
              .useCurrentLocation();

      if (!mounted) {
        return;
      }

      setState(() {
        _startingPoint = startingPoint;
        _loadingLocation = false;
        _showLocationSearch = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingLocation = false;
        _locationError = error.toString();
      });
    }
  }

  void _useSpirosTestLocation() {
    setState(() {
      _startingPoint =
          CrawlTestLocations
              .spirosLloydminster;

      _locationError = null;
      _showLocationSearch = false;
    });

    debugPrint(
      'CRAWL TEST LOCATION: '
      '${_startingPoint!.name}',
    );

    debugPrint(
      'Coordinates: '
      '${_startingPoint!.latitude}, '
      '${_startingPoint!.longitude}',
    );
  }

  void _selectSearchResult(
    CrawlLocationSearchResult result,
  ) {
    if (!result.isValid) {
      setState(() {
        _locationError =
            'The selected location has '
            'invalid coordinates.';
      });
      return;
    }

    setState(() {
      _startingPoint =
          CrawlStartingPoint(
        name: result.name,
        latitude: result.latitude,
        longitude: result.longitude,
      );

      _locationError = null;
      _showLocationSearch = false;
    });

    debugPrint(
      'CRAWL SEARCH LOCATION: '
      '${result.name}',
    );

    debugPrint(
      'Coordinates: '
      '${result.latitude}, '
      '${result.longitude}',
    );
  }

  void _startCrawl() {
    _updateWalkingDistance();

    debugPrint(
      'CRAWL CONFIGURATION',
    );

    debugPrint(
      'Starting point: '
      '${_startingPoint?.name ?? 'Not selected'}',
    );

    if (_startingPoint != null) {
      debugPrint(
        'Coordinates: '
        '${_startingPoint!.latitude}, '
        '${_startingPoint!.longitude}',
      );
    }

    debugPrint(
      'Stops: ${_configuration.stopCount}',
    );

    debugPrint(
      'Categories: '
      '${_configuration.categories}',
    );

    debugPrint(
      'Walking distance: '
      '${_configuration.displayedWalkingDistance} '
      '${_configuration.walkingDistanceUnitLabel}',
    );

    debugPrint(
      'Walking distance metres: '
      '${_configuration.walkingDistanceMeters}',
    );
  }
}