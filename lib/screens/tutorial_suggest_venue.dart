// Copyright (C) 2026 Cameron Dow. All rights reserved.

// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/material.dart';

class TutorialSuggestVenueScreen extends StatelessWidget {
  const TutorialSuggestVenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SUGGEST A VENUE',
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
                title: 'KNOW A PLACE?',
                body:
                    'Know a restaurant, bar, brewery, or other venue that should be on the radar? You can suggest it for consideration.',
              ),
              _TutorialSection(
                number: '02',
                title: 'WHAT MAKES A GOOD SUGGESTION?',
                body:
                    'Suggest venues that fit the kinds of places Questionable Decisions and Dining Unhinged are designed to discover.',
              ),
              _TutorialSection(
                number: '03',
                title: 'GIVE US THE DETAILS',
                body:
                    'Provide the venue name and any useful information that can help identify the place and understand why you are suggesting it.',
              ),
              _TutorialSection(
                number: '04',
                title: 'SEND IT OUR WAY',
                body:
                    'Send your venue suggestion and any relevant details to:',
              ),
              _EmailSection(
                number: '05',
                title: 'EMAIL',
                email: 'diningunhinged@gmail.com',
              ),
              _TutorialSection(
                number: '06',
                title: 'SUGGESTIONS ARE REVIEWED',
                body:
                    'A venue suggestion is a recommendation, not a guarantee that the venue will be added to the app.',
              ),
              _TutorialSection(
                number: '07',
                title: 'HELP US FIND MORE QUESTIONABLE DECISIONS',
                body:
                    'Good suggestions help expand the places available to discover and give everyone more opportunities to make questionable decisions.',
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

class _EmailSection extends StatelessWidget {
  const _EmailSection({
    required this.number,
    required this.title,
    required this.email,
  });

  final String number;
  final String title;
  final String email;

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
            email,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}