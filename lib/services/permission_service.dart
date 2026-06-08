// lib/services/permission_service.dart
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Outcome of a runtime permission request.
///
/// [granted]            — permission is currently usable.
/// [denied]             — user dismissed / refused this time; can be re-asked.
/// [permanentlyDenied]  — user picked "Don't ask again" (Android) or denied
///                        twice (iOS). Caller should direct them to system
///                        settings via [PermissionService.openSettings].
enum PermissionOutcome { granted, denied, permanentlyDenied }

/// Single entry point for every runtime permission the app needs.
///
/// **Design intent:**
///   * No feature module talks to `permission_handler` directly. All requests
///     go through this service so the rules for each Android API level live in
///     exactly one place.
///   * "Storage" is intentionally absent. Modern Android (11+) does not grant
///     blanket file-system access via `READ/WRITE_EXTERNAL_STORAGE`, and we
///     don't ship with `MANAGE_EXTERNAL_STORAGE`. Anything that needs to
///     persist a file uses either the app-specific external dir (no permission)
///     or the Storage Access Framework (no permission). See [PdfService] and
///     [BackupService].
///   * Image and camera flows go through `image_picker` /
///     `flutter_document_scanner`, both of which manage their own platform
///     permission UI internally. The methods here exist for explicit pre-check
///     UX (e.g. showing a custom rationale screen) and as an API surface for
///     future features.
///
/// Singleton: [PermissionService.instance].
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  // ── Camera ────────────────────────────────────────────────────────────────

  /// Used by document scanning flows.
  ///
  /// On Android: `image_picker` / `flutter_document_scanner` request the
  /// permission through their own intents; calling this is optional but lets
  /// the UI show its own rationale dialog beforehand.
  ///
  /// On iOS: the system shows the dialog defined by
  /// `NSCameraUsageDescription` in `Info.plist`.
  Future<PermissionOutcome> requestCamera() => _request(Permission.camera);

  // ── Photos / Gallery ──────────────────────────────────────────────────────

  /// Used when picking images from the device gallery.
  ///
  /// On Android 13+ the modern Photo Picker is permissionless and this returns
  /// granted without showing a dialog. On older Android and on iOS the system
  /// dialog appears.
  Future<PermissionOutcome> requestPhotos() async {
    if (Platform.isIOS) return _request(Permission.photos);
    // Android: `image_picker` uses the Photo Picker on API 33+, no permission
    // needed. On older devices `permission_handler` will map this to
    // READ_EXTERNAL_STORAGE for us.
    return _request(Permission.photos);
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Requests permission to display local notifications.
  ///
  /// Uses the `flutter_local_notifications` plugin's own request flow because
  /// it speaks the correct dialect on each OS version:
  ///   * Android 13+ → `POST_NOTIFICATIONS` runtime permission.
  ///   * Android <13 → no runtime permission; returns granted.
  ///   * iOS → `requestPermissions(alert/badge/sound)`.
  Future<PermissionOutcome> requestNotifications(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (Platform.isAndroid) {
      final android = plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return PermissionOutcome.granted;

      final granted = await android.requestNotificationsPermission();
      // The plugin returns null on Android <13 where the permission doesn't
      // exist. Treat that as already-granted.
      if (granted == null || granted) return PermissionOutcome.granted;

      final status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        return PermissionOutcome.permanentlyDenied;
      }
      return PermissionOutcome.denied;
    }

    if (Platform.isIOS) {
      final ios = plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (ios == null) return PermissionOutcome.granted;

      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted == true
          ? PermissionOutcome.granted
          : PermissionOutcome.denied;
    }

    return PermissionOutcome.granted;
  }

  /// Best-effort request for `SCHEDULE_EXACT_ALARM` on Android 12+.
  ///
  /// Failure is non-fatal: inexact alarms still fire, they just may drift by
  /// several minutes around the requested time. Callers should not block their
  /// flow on this.
  Future<void> requestExactAlarmIfNeeded() async {
    if (!Platform.isAndroid) return;
    try {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (_) {
      // Permission doesn't exist on Android <12 — silently ignore.
    }
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  Future<bool> hasCamera() async => Permission.camera.isGranted;

  Future<bool> hasNotifications() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  // ── Settings escape hatch ─────────────────────────────────────────────────

  /// Opens the OS-level settings page for the app so the user can flip a
  /// permanently-denied permission manually.
  Future<bool> openSettings() => openAppSettings();

  // ── Private ───────────────────────────────────────────────────────────────

  static Future<PermissionOutcome> _request(Permission p) async {
    final status = await p.request();
    if (status.isGranted || status.isLimited) {
      return PermissionOutcome.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionOutcome.permanentlyDenied;
    }
    return PermissionOutcome.denied;
  }
}
