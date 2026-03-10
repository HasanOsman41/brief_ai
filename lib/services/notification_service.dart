import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings();

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(settings: initSettings);
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if timezone cannot be determined
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    String? payload,
  }) async {
    final tz.TZDateTime tzScheduled = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );
    if (tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    final androidDetails = AndroidNotificationDetails(
      'brief_ai_channel',
      'Reminders',
      channelDescription: 'Document reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: const Color(0xFF6366F1),
      colorized: true,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'ok_action',
          'OK',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Reminder',
        htmlFormatContent: true,
        htmlFormatContentTitle: true,
      ),
    );

    final iosDetails = DarwinNotificationDetails();

    try {
      await _local.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } catch (e) {
      print('Failed to schedule notification: $e');
    }
  }

  Future<void> cancel(int id) async {
    await _local.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _local.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _local.pendingNotificationRequests();
  }

  /// Cancel all reminders for a document (4 possible reminder types)
  Future<void> cancelRemindersForDocument(int documentId) async {
    // Reminder IDs are: documentId * 10, documentId * 10 + 1, etc.
    for (int i = 0; i < 4; i++) {
      await cancel(documentId * 10 + i);
    }
  }
}
