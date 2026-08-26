import 'package:flutter/material.dart';

import 'placeholder_screen.dart';

class DetourScreen extends StatelessWidget {
  const DetourScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    icon: Icons.alt_route,
    title: 'Detour',
    message: 'Your route. Our questionable suggestions.',
  );
}

