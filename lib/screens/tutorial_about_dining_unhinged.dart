// Copyright (C) 2026 Cameron Dow. All rights reserved.

// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/material.dart';

class TutorialAboutDiningUnhingedScreen extends StatelessWidget {
  const TutorialAboutDiningUnhingedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'ABOUT DINING UNHINGED',
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
            children: const [
              _TutorialSection(
                number: '01',
                title: 'WHAT IS DINING UNHINGED?',
                body:
                    'Dining Unhinged is the review and editorial side of Questionable Decisions, providing the food and drink experiences behind the places you discover.',
              ),
              _TutorialSection(
                number: '02',
                title: 'FOOD REVIEWS WITH EXCELLENT TASTE',
                body:
                    'Dining Unhinged reviews restaurants, bars, breweries, and other places worth eating and drinking at, with its own voice, opinions, and scoring system.',
              ),
              _TutorialSection(
                number: '03',
                title: 'THE CONNECTION',
                body:
                    'Questionable Decisions uses Dining Unhinged information to help you discover places instead of relying solely on generic ratings.',
              ),
              _TutorialSection(
                number: '04',
                title: 'READ THE FULL STORY',
                body:
                    'When a venue has a Dining Unhinged review, you can follow through to the main website to read the complete review and get the story behind the rating.',
              ),
              _TutorialSection(
                number: '05',
                title: 'THE POINT',
                body:
                    'Good times. Questionable judgment. And the stories that come with it.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialSection extends StatelessWidget {
  const _TutorialSection({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFFA8A8A8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}