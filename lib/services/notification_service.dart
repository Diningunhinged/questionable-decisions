import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/nearby_result.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'crawl_encounters';
  static const String _channelName = 'Crawl Encounters';

  static Future<void> initialize({
    required Future<void> Function(String? payload) onNotificationTap,
  }) async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        await onNotificationTap(response.payload);
      },
    );

    await _requestPermissions();
    await _createAndroidChannel();
  }

  static Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _createAndroidChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description:
          'Notifications when a reviewed Dining Unhinged spot is nearby.',
      importance: Importance.high,
    );

    await android?.createNotificationChannel(channel);
  }

  static Future<void> showCrawlEncounter({
    required NearbyResult result,
    required double distanceMeters,
  }) async {
    final distance = _formatDistance(distanceMeters);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          'Notifications when a reviewed Dining Unhinged spot is nearby.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Questionable Decision Nearby',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final id =
        DateTime.now().millisecondsSinceEpoch.remainder(
          2147483647,
        );

    await _plugin.show(
      id,
      'QUESTIONABLE DECISION NEARBY',
      '${result.title} is $distance away.',
      details,
      payload: '${result.type}|${result.slug}',
    );
  }

  static String _formatDistance(
    double distanceMeters,
  ) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }

    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}