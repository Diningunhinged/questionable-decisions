import 'package:flutter/material.dart';

class TutorialNearbyScreen extends StatelessWidget {
  const TutorialNearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: const Color(0xFFF5F2E8),
        title: const Text(
          'NEARBY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _TutorialSection(
                number: '01',
                title: 'HOW NEARBY WORKS',
                body:
                    'Nearby helps you find Dining Unhinged-reviewed places around your chosen starting location.',
              ),
              _TutorialSection(
                number: '02',
                title: 'CHOOSE YOUR STARTING LOCATION',
                body:
                    'Before Nearby can find places, choose a starting location. Use your GPS location or select a starting location manually.',
              ),
              _TutorialSection(
                number: '03',
                title: 'THE RADIUS',
                body:
                    'Choose how far you want to search from your starting location. Nearby only shows reviewed places within your selected radius.',
              ),
              _TutorialSection(
                number: '04',
                title: 'FIND SOMETHING NEARBY',
                body:
                    'Nearby searches for Dining Unhinged-reviewed venues around your starting location and shows the closest questionable decisions first.',
              ),
              _TutorialSection(
                number: '05',
                title: 'MAKE THE DECISION FOR ME',
                body:
                    'If you do not want to choose, let the app choose for you. Make the Decision For Me selects a place from the eligible venues in your radius.',
              ),
              _TutorialSection(
                number: '06',
                title: 'THE DECISION',
                body:
                    'The decision shows the selected venue, its Dining Unhinged rating, and its distance from your starting location.',
              ),
              _TutorialSection(
                number: '07',
                title: 'SAVE A VENUE',
                body:
                    'Save a venue when you want to remember it. Saved decisions stay available in the Saved section.',
              ),
              _TutorialSection(
                number: '08',
                title: 'OPEN THE REVIEW',
                body:
                    'Tap a venue to open its Dining Unhinged review and read the full story on the main website.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialSection extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _TutorialSection({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF0D0D0F),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
