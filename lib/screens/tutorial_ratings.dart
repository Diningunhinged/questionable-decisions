// Copyright (C) 2026 Cameron Dow. All rights reserved.

// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/material.dart';

class TutorialRatingsScreen extends StatelessWidget {
  const TutorialRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RATINGS',
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
                title: 'DINING UNHINGED',
                body:
                    'Questionable Decisions uses Dining Unhinged reviews to help you decide where to go.',
              ),
              _TutorialSection(
                number: '02',
                title: 'THE OVERALL RATING',
                body:
                    'The overall rating is the Dining Unhinged score assigned to a reviewed venue. It gives you a quick way to understand how the venue was judged.',
              ),
              _TutorialSection(
                number: '03',
                title: 'THE SCORING SYSTEM',
                body:
                    'Dining Unhinged uses its own scoring system rather than relying on a generic collection of ratings from other platforms.',
              ),
              _TutorialSection(
                number: '04',
                title: 'WHY DINING UNHINGED?',
                body:
                    'The app is built around Dining Unhinged recommendations, so the places you discover are connected to the same review system and editorial voice.',
              ),
              _TutorialSection(
                number: '05',
                title: 'READ THE FULL REVIEW',
                body:
                    'A rating is only part of the story. When a full Dining Unhinged review is available, open it to see the reasoning, food, drinks, and experience behind the score.',
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