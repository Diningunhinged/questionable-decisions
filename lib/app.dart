import 'package:flutter/material.dart';

import 'navigation/app_navigation.dart';
import 'screens/crawl_screen.dart';
import 'screens/detour_screen.dart';
import 'screens/help_screen.dart';
import 'screens/nearby_screen.dart';
import 'screens/saved_screen.dart';

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
  int _currentIndex = 2;

  void showSaved() {
    setState(() {
      _currentIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const DetourScreen(),
      const CrawlScreen(),
      NearbyScreen(onDecisionCommitted: showSaved),
      const SavedScreen(),
      const HelpScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: QuestionableNavigationBar(
        currentIndex: _currentIndex,
        onSelect: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

