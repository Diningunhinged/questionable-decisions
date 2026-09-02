// Copyright (C) 2026 Cameron Dow. All rights reserved.
// Questionable Decisions - Copyright Registration No. 1249281.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize(
    onNotificationTap: (payload) async {
      if (payload == null || payload.isEmpty) return;

      final parts = payload.split('|');
      if (parts.length != 2) return;

      final type = parts[0];
      final slug = parts[1];
      final section = type == 'drink' ? 'drinks' : 'venues';

      final url = Uri.parse(
        'https://www.diningunhinged.ca/$section/$slug',
      );

      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    },
  );

  runApp(const QuestionableDecisionsApp());
}
