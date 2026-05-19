// lib/services/notification_service.dart
import 'package:brief_ai/data/local/database_helper.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _prefKey = 'notifications';

  // ── Init ───────────────────────────────────────────────────

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(settings: initSettings);
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  Future<bool> requestPermission() async {
    // First try via flutter_local_notifications (shows the system dialog)
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      bool? granted = await android.requestNotificationsPermission();
      if (granted == true) return true;
      // If denied, check if permanently denied and offer settings
      final status = await Permission.notification.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        granted = (await Permission.notification.request()).isGranted;
        return granted;
      }
      return false;
    }

    final ios = _local
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  // ── Enabled state ─────────────────────────────────────────

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  // ── Enable ────────────────────────────────────────────────

  /// Saves preference, requests OS permission, reschedules all future reminders.
  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);

    await requestPermission();
    await rescheduleAllNotifications();
  }

  // ── Disable ───────────────────────────────────────────────

  /// Saves preference and cancels all OS-scheduled notifications.
  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);

    await _local.cancelAll();
  }

  // ── Reschedule ────────────────────────────────────────────

  /// Reads every document from the DB and re-schedules any future reminders.
  Future<void> rescheduleAllNotifications() async {
    try {
      final db = await DatabaseHelper().database;
      final rows = await db.query(
        'documents',
        columns: [
          'id',
          'title',
          'reminder3DaysTime',
          'reminder1DayTime',
          'reminder12HoursTime',
          'reminderCustomTime',
        ],
      );

      for (final row in rows) {
        final docId = row['id'] as int;
        final title = row['title'] as String? ?? '';

        final reminders = <int, String?>{
          0: row['reminder3DaysTime'] as String?,
          1: row['reminder1DayTime'] as String?,
          2: row['reminder12HoursTime'] as String?,
          3: row['reminderCustomTime'] as String?,
        };

        for (final entry in reminders.entries) {
          final timeStr = entry.value;
          if (timeStr == null || timeStr.isEmpty) continue;

          final scheduledDate = DateTime.tryParse(timeStr);
          if (scheduledDate == null) continue;

          // Only schedule future notifications
          if (scheduledDate.isBefore(DateTime.now())) continue;

          final notifId = docId * 10 + entry.key;
          await scheduleNotification(
            notifId,
            title,
            _reminderBody(entry.key),
            scheduledDate,
            payload: docId.toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('rescheduleAllNotifications error: $e');
    }
  }

  String _reminderBody(int slot) {
    switch (slot) {
      case 0:
        return 'Reminder: 3 days left';
      case 1:
        return 'Reminder: 1 day left';
      case 2:
        return 'Reminder: 12 hours left';
      default:
        return 'Custom reminder';
    }
  }

  // ── Schedule ────────────────────────────────────

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    String? payload,
  }) async {
    // Guard: skip if notifications are disabled
    if (!await areNotificationsEnabled()) return;

    final tz.TZDateTime tzScheduled = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
      scheduledDate.second,
    );
    if (tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    final now = tz.TZDateTime.now(tz.local);

    debugPrint('📅 Scheduling notification $id');
    debugPrint('   Now:       $now');
    debugPrint('   Scheduled: $tzScheduled');
    debugPrint('   Is future: ${tzScheduled.isAfter(now)}');
    debugPrint('---------------');
    debugPrint('datetime $scheduledDate');
    debugPrint('tzScheduled $tzScheduled');
    debugPrint('tz.local ${tz.local}');

    final androidDetails = AndroidNotificationDetails(
      'brief_ai_channel',
      'Reminders',
      channelDescription: 'Document reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: AppTheme.lightPrimary,
      colorized: true,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
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

    const iosDetails = DarwinNotificationDetails();

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
      debugPrint('Failed to schedule notification $id: $e');
    }
  }

  Future<void> cancel(int id) async => _local.cancel(id: id);
  Future<void> cancelAll() async => _local.cancelAll();

  Future<List<PendingNotificationRequest>> getPendingNotifications() async =>
      _local.pendingNotificationRequests();

  Future<void> cancelRemindersForDocument(int documentId) async {
    for (int i = 0; i < 4; i++) {
      await cancel(documentId * 10 + i);
    }
  }
}
