import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationData {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String? payload;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'scheduledTime': scheduledTime.toIso8601String(),
    'payload': payload,
  };

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      NotificationData(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        scheduledTime: DateTime.parse(json['scheduledTime'] as String),
        payload: json['payload'] as String?,
      );
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const String _storageKey = 'brief_ai_scheduled_notifications';

  Future<void> initialize() async {
    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings();

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(settings: initSettings);
    tz.initializeTimeZones();
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'brief_ai_channel',
      'Reminders',
      channelDescription: 'Document reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails();

    try {
      await _local.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
        matchDateTimeComponents: null,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // Store notification metadata
      await _saveNotificationData(
        NotificationData(
          id: id,
          title: title,
          body: body,
          scheduledTime: scheduledDate,
          payload: payload,
        ),
      );
    } catch (e) {
      print('Failed to schedule notification: $e');
    }
  }

  Future<void> _saveNotificationData(NotificationData data) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await _getStoredNotifications();

    // Remove if exists, then add new one
    notifications.removeWhere((n) => n.id == data.id);
    notifications.add(data);

    final jsonList = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  Future<List<NotificationData>> _getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    return jsonList
        .map((json) => NotificationData.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<List<NotificationDataWithPending>>
  getPendingNotificationsWithTime() async {
    final pending = await _local.pendingNotificationRequests();
    final stored = await _getStoredNotifications();

    return pending.map((pending) {
      final storedData = stored.firstWhere(
        (s) => s.id == pending.id,
        orElse: () => NotificationData(
          id: pending.id,
          title: pending.title ?? '',
          body: pending.body ?? '',
          scheduledTime: DateTime.now(),
          payload: pending.payload,
        ),
      );
      return NotificationDataWithPending(
        pending: pending,
        scheduledTime: storedData.scheduledTime,
      );
    }).toList();
  }

  Future<void> cancel(int id) async {
    await _local.cancel(id: id);

    // Remove from storage
    final prefs = await SharedPreferences.getInstance();
    final notifications = await _getStoredNotifications();
    notifications.removeWhere((n) => n.id == id);

    final jsonList = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  Future<void> cancelAll() async {
    await _local.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _local.pendingNotificationRequests();
  }
}

class NotificationDataWithPending {
  final PendingNotificationRequest pending;
  final DateTime scheduledTime;

  NotificationDataWithPending({
    required this.pending,
    required this.scheduledTime,
  });
}
