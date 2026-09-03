// Copyright (C) 2026 Cameron Dow. All rights reserved.

// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/material.dart';

class TutorialLocationPrivacyScreen extends StatelessWidget {
  const TutorialLocationPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'LOCATION & PRIVACY',
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
                title: 'WHY LOCATION IS USED',
                body:
                    'Questionable Decisions uses your location to help find venues around you and to provide location-based features such as Nearby.',
              ),
              _TutorialSection(
                number: '02',
                title: 'YOUR CURRENT LOCATION',
                body:
                    'When a feature needs your location, the app uses the location information provided by your device.',
              ),
              _TutorialSection(
                number: '03',
                title: 'LOCATION PERMISSION',
                body:
                    'Your device controls whether Questionable Decisions is allowed to access your location. You can manage location permissions through your device settings.',
              ),
              _TutorialSection(
                number: '04',
                title: 'USE LOCATION WHEN NEEDED',
                body:
                    'Location access is used to provide location-based features. If location access is unavailable, features that depend on your location may not work as intended.',
              ),
              _TutorialSection(
                number: '05',
                title: 'YOUR PRIVACY',
                body:
                    'Location information is sensitive. Review the app privacy information and your device permissions so you understand how location access is handled.',
              ),
              _TutorialSection(
                number: '06',
                title: 'CONTROL YOUR PERMISSIONS',
                body:
                    'You remain in control of your device permissions. If you change or revoke location access, you can update those permissions again through your device settings.',
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