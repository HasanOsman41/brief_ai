// lib/services/notification_service.dart
import 'package:brief_ai/data/local/database_helper.dart';
import 'package:brief_ai/localization/l10n.dart';
import 'package:brief_ai/services/permission_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _prefKey = 'notifications';

  /// Notification payloads are `doc_<documentId>`.
  static const _payloadPrefix = 'doc_';

  /// Attached to the root [MaterialApp] so notification taps — which arrive
  /// without a [BuildContext] — can still drive navigation.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Document id captured from the notification that cold-started the app.
  /// Consumed once by the splash screen via [consumeLaunchDocumentId].
  int? _launchDocumentId;

  // ── Init ───────────────────────────────────────────────────

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // If the app was launched from a terminated state by tapping a
    // notification, remember its target so the splash flow can open it after
    // the normal startup routing finishes.
    final launch = await _local.getNotificationAppLaunchDetails();
    if ((launch?.didNotificationLaunchApp ?? false) &&
        launch?.notificationResponse?.actionId != 'ok_action') {
      _launchDocumentId =
          _documentIdFromPayload(launch?.notificationResponse?.payload);
    }

    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }
  }

  // ── Tap handling ──────────────────────────────────────────

  /// Fired when a notification is tapped while the app is running or in the
  /// background. The "OK" action only dismisses, so it never navigates.
  void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'ok_action') return;
    final id = _documentIdFromPayload(response.payload);
    if (id != null) _openDocument(id);
  }

  void _openDocument(int documentId) {
    navigatorKey.currentState?.pushNamed(
      '/document-detail',
      arguments: {'documentId': documentId},
    );
  }

  static int? _documentIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    return int.tryParse(payload.substring(_payloadPrefix.length));
  }

  /// Returns (and clears) the document id of the notification that cold-started
  /// the app, or null if the app wasn't launched from a notification.
  int? consumeLaunchDocumentId() {
    final id = _launchDocumentId;
    _launchDocumentId = null;
    return id;
  }

  /// Requests notification permission via the central [PermissionService].
  ///
  /// Also opportunistically requests `SCHEDULE_EXACT_ALARM` on Android 12+ so
  /// reminders fire at the exact requested minute instead of drifting under
  /// the OS's inexact-alarm batching.
  Future<bool> requestPermission() async {
    await PermissionService.instance.requestExactAlarmIfNeeded();
    final outcome = await PermissionService.instance.requestNotifications(_local);
    return outcome == PermissionOutcome.granted;
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
          'deadline',
          'reminder3DaysTime',
          'reminder1DayTime',
          'reminder12HoursTime',
          'reminderCustomTime',
        ],
      );

      final deadlineLabel = await L10n.tr('deadline');

      for (final row in rows) {
        final docId = row['id'] as int;
        // Titles are stored as localization keys; translate to the user's
        // language (free-form titles pass through unchanged).
        final title = await L10n.tr(row['title'] as String? ?? '');

        final deadline = DateTime.tryParse(row['deadline'] as String? ?? '');
        final body = deadline != null
            ? '$deadlineLabel: ${deadline.day}.${deadline.month}.${deadline.year}'
            : deadlineLabel;

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
            body,
            scheduledDate,
            payload: 'doc_$docId',
          );
        }
      }
    } catch (e) {
      debugPrint('rescheduleAllNotifications error: $e');
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

/// Background isolate handler for notification taps that occur while the app is
/// terminated. It runs without a UI/navigator, so it can't navigate; a body tap
/// instead launches the app and is handled via `getNotificationAppLaunchDetails`
/// in [NotificationService.initialize]. Required by the plugin to be a
/// top-level, vm:entry-point function.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}
