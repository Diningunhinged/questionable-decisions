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

