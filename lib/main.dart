import 'package:flutter/material.dart';

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D0F),
          foregroundColor: Colors.white,
          elevation: 0,
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

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dining Unhinged brand logo
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
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFD4AF37),
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 4),

            Text(
              'DECISIONS NEARBY',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),

            const SizedBox(height: 12),

            Text(
              'Find somewhere worth making a questionable decision.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),

            const SizedBox(height: 36),

            _ActionCard(
              icon: Icons.location_searching,
              title: 'Find Something Nearby',
              subtitle: 'Show me restaurants, pubs and bars around me.',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            _ActionCard(
              icon: Icons.casino,
              title: 'Make The Decision For Me',
              subtitle: 'I have no fucking idea where I want to go.',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            _ActionCard(
              icon: Icons.route,
              title: 'Build A Crawl',
              subtitle: 'Plan an evening of questionable decisions.',
              onTap: () {},
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0D0D0F),
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 12),

              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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