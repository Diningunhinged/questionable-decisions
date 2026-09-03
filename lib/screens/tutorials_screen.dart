// Copyright (C) 2026 Cameron Dow. All rights reserved.

// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/material.dart';

import 'tutorial_crawl.dart';
import 'tutorial_detour.dart';
import 'tutorial_nearby.dart';
import 'tutorial_saved.dart';

class TutorialsScreen extends StatelessWidget {
  const TutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TUTORIALS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUESTIONABLE DECISIONS 101',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Learn how this whole thing works.',
                style: TextStyle(
                  color: Color(0xFFA8A8A8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),

              _TutorialCard(
                title: 'NEARBY',
                description:
                    'Find questionable decisions around you and let us make one for you.',
                icon: Icons.location_on_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TutorialNearbyScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _TutorialCard(
                title: 'CRAWL',
                description:
                    'Build a crawl, choose your stops, and work your way through them.',
                icon: Icons.route_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TutorialCrawlScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _TutorialCard(
                title: 'DETOUR',
                description:
                    'Plan a road trip and discover Dining Unhinged stops along the way.',
                icon: Icons.alt_route,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TutorialDetourScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _TutorialCard(
                title: 'SAVED DECISIONS',
                description:
                    'Learn how to save, remove, review, and use your questionable decisions.',
                icon: Icons.bookmark_border,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TutorialSavedScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: const Color(0xFFD4AF37),
                size: 30,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFFA8A8A8),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFA8A8A8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}