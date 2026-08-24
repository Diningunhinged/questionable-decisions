import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'models/nearby_result.dart';
import 'services/dining_unhinged_api.dart';
import 'services/location_service.dart';
import 'widgets/nearby_result_card.dart';

void main() {
  runApp(const QuestionableDecisionsApp());
}

class QuestionableDecisionsApp extends StatelessWidget {
  const QuestionableDecisionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questionable Decisions Nearby',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFB87333),
          surface: Color(0xFF1C1C1E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    NearbyScreen(),
    CrawlScreen(),
    SavedScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1C1C1E),
        indicatorColor: const Color(0xFFD4AF37),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Crawl',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  bool _loading = false;
  String? _error;
  List<NearbyResult> _results = [];

  Future<void> _loadNearby() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      debugPrint('LOCATION: Starting location request');

      final position =
          await LocationService.getCurrentLocation();

      debugPrint(
        'LOCATION: Current position = '
        '${position.latitude}, ${position.longitude}',
      );

      final results =
          await DiningUnhingedApi.fetchNearbyResults();

      debugPrint(
        'DINING UNHINGED: Received ${results.length} results',
      );

      final nearbyResults = <NearbyResult>[];

      for (final result in results) {
        final location = result.venue.location;

        if (location == null || !location.isValid) {
          debugPrint(
            'Skipping ${result.venue.name}: '
            'no valid location',
          );
          continue;
        }

        final distanceMeters =
            Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude!,
          location.longitude!,
        );

        final distanceKm = distanceMeters / 1000;

        result.distanceKm = distanceKm;

        debugPrint(
          '${result.venue.name}: '
          '${distanceKm.toStringAsFixed(2)} km',
        );

        nearbyResults.add(result);
      }

      nearbyResults.sort(
        (a, b) =>
            (a.distanceKm ?? double.infinity)
                .compareTo(
              b.distanceKm ?? double.infinity,
            ),
      );

      if (!mounted) return;

      setState(() {
        _results = nearbyResults;
        _loading = false;
      });
    } on LocationPermissionException catch (e) {
      debugPrint(
        'LOCATION PERMISSION ERROR: ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } on LocationServiceException catch (e) {
      debugPrint(
        'LOCATION SERVICE ERROR: ${e.message}',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'NEARBY ERROR: $e',
      );

      debugPrint(
        'STACK TRACE: $stackTrace',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            "We couldn't find the questionable decisions.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1C1C1E),
        onRefresh: _loadNearby,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                24,
                20,
                24,
                32,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 20,
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  Text(
                    'QUESTIONABLE',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          color: const Color(0xFFD4AF37),
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'DECISIONS NEARBY',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Find somewhere worth making a questionable decision.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color: Colors.white70,
                        ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _loadNearby,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0D0D0F),
                              ),
                            )
                          : const Icon(
                              Icons.location_searching,
                            ),
                      label: Text(
                        _loading
                            ? 'SEARCHING...'
                            : 'FIND SOMETHING NEARBY',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFD4AF37),
                        foregroundColor:
                            const Color(0xFF0D0D0F),
                        disabledBackgroundColor:
                            const Color(0xFFD4AF37),
                        disabledForegroundColor:
                            const Color(0xFF0D0D0F),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_off,
                            color: Colors.redAccent,
                            size: 32,
                          ),

                          const SizedBox(height: 10),

                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 14),

                          TextButton(
                            onPressed: _loadNearby,
                            child: const Text(
                              'TRY AGAIN',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_loading &&
                      _error == null &&
                      _results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 24,
                      ),
                      child: Text(
                        'Tap the button and let the questionable decisions begin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                    ),

                  if (_results.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 16,
                      ),
                      child: Text(
                        '${_results.length} nearby questionable options',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ]),
              ),
            ),

            if (_results.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  32,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final result = _results[index];

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 18,
                        ),
                        child: NearbyResultCard(
                          result: result,
                        ),
                      );
                    },
                    childCount: _results.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CrawlScreen extends StatelessWidget {
  const CrawlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.route,
      title: 'Build A Crawl',
      message: 'Your questionable itinerary starts here.',
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.bookmark,
      title: 'Saved',
      message: 'Your questionable decisions will live here.',
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.settings,
      title: 'Settings',
      message: 'App settings will live here.',
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: const Color(0xFFD4AF37),
              ),

              const SizedBox(height: 24),

              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: Colors.white60,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}