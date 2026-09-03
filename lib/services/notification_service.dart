import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/nearby_result.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize({
    required Future<void> Function(String? payload) onNotificationTap,
  }) async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        await onNotificationTap(response.payload);
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    const crawlChannel = AndroidNotificationChannel(
      'crawl_encounters',
      'Crawl Encounters',
      description:
          'Notifications when a reviewed Dining Unhinged spot is within 500 metres.',
      importance: Importance.high,
    );

    await android?.createNotificationChannel(crawlChannel);

    const detourChannel = AndroidNotificationChannel(
      'detour_encounters',
      'Detour Encounters',
      description:
          'Notifications when the next Detour stop is within 500 metres.',
      importance: Importance.high,
    );

    await android?.createNotificationChannel(detourChannel);
  }

  static Future<void> showDetourEncounter({
    required String title,
    required double distanceMeters,
  }) async {
    final distance = distanceMeters < 1000
        ? '${distanceMeters.round()} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'detour_encounters',
        'Detour Encounters',
        channelDescription:
            'Notifications when the next Detour stop is within 500 metres.',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Questionable Decision Nearby',
      ),
    );

    final id =
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    await _plugin.show(
      id,
      'QUESTIONABLE DECISION NEARBY',
      '$title is $distance away.',
      details,
      payload: 'detour|$title',
    );
  }

  static Future<void> showCrawlEncounter({
    required NearbyResult result,
    required double distanceMeters,
  }) async {
    final distance = distanceMeters < 1000
        ? '${distanceMeters.round()} m'
        : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'crawl_encounters',
        'Crawl Encounters',
        channelDescription:
            'Notifications when a reviewed Dining Unhinged spot is within 500 metres.',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Questionable Decision Nearby',
      ),
    );

    final id =
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    await _plugin.show(
      id,
      'QUESTIONABLE DECISION NEARBY',
      '${result.title} is $distance away.',
      details,
      payload: '${result.type}|${result.slug}',
    );
  }
}