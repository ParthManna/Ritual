import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'ritual_daily';
  static const _notifId = 1;

  static Future<void> init() async {
    // Skip initialization on platforms that don't support the notification plugin used here
    if (kIsWeb || Platform.isLinux || Platform.isWindows) return;

    tz.initializeTimeZones();

    try {
      final String localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (e) {
      // Fallback if timezone detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Added iOS/Darwin settings to prevent crash
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios, // Required for iOS
        macOS: ios, // Required if targeting macOS
      ),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || Platform.isLinux || Platform.isWindows) return;

    await _plugin.cancel(_notifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notifId,
      'Time for your habits! 🔥',
      "Don't break your streak — check in now.",
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Daily Reminders',
          channelDescription: 'Reminds you to complete your daily habits',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        // Added iOS Details
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_hour', hour);
    await prefs.setInt('notif_minute', minute);
    await prefs.setBool('notif_enabled', true);
  }

  static Future<void> cancelReminder() async {
    if (kIsWeb || Platform.isLinux || Platform.isWindows) return;

    await _plugin.cancel(_notifId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', false);
  }

  static Future<Map<String, dynamic>> getSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notif_enabled') ?? false,
      'hour': prefs.getInt('notif_hour') ?? 9,
      'minute': prefs.getInt('notif_minute') ?? 0,
    };
  }
}
