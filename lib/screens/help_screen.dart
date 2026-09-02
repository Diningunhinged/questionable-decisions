// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/material.dart';

import 'placeholder_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    icon: Icons.help_outline,
    title: 'Help',
    message: 'How the questionable decisions work.',
  );
}

