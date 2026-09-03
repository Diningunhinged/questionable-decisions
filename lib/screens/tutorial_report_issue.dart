// Copyright (C) 2026 Cameron Dow. All rights reserved.

// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/material.dart';

class TutorialReportIssueScreen extends StatelessWidget {
  const TutorialReportIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'REPORT AN ISSUE',
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
                title: 'FOUND A PROBLEM?',
                body:
                    'If something in Questionable Decisions is not working correctly, let us know so it can be investigated.',
              ),
              _TutorialSection(
                number: '02',
                title: 'WHAT TO REPORT',
                body:
                    'Report things such as incorrect venue information, broken functionality, unexpected behaviour, or other problems you encounter while using the app.',
              ),
              _TutorialSection(
                number: '03',
                title: 'GIVE US THE DETAILS',
                body:
                    'Include enough information to help explain what happened, including the feature you were using and what you expected to happen.',
              ),
              _TutorialSection(
                number: '04',
                title: 'SCREENSHOTS HELP',
                body:
                    'When appropriate, include screenshots or other useful details that make the problem easier to understand.',
              ),
              _TutorialSection(
                number: '05',
                title: 'CONTACT US',
                body:
                    'Send your issue and any relevant details to diningunhinged@gmail.com.',
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