import 'package:flutter/material.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/services/notification_service.dart';
import 'package:brief_ai/widgets/confirm_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Ensure this import matches your project structure
import 'package:brief_ai/localization/app_localizations.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _notificationService = NotificationService();
  late Future<List<PendingNotificationRequest>> _pendingNotifications;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _pendingNotifications = _notificationService.getPendingNotifications();
    });
  }

  Future<void> _deleteReminder(int id) async {
    await _notificationService.cancel(id);
    _loadNotifications();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.tr(context, 'reminderCancelled')),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkSuccess
            : AppTheme.lightSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr(context, 'scheduledReminders')),
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        foregroundColor: isDark
            ? AppTheme.darkTextPrimary
            : AppTheme.lightTextPrimary,
      ),
      body: FutureBuilder<List<PendingNotificationRequest>>(
        future: _pendingNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${AppLocalizations.tr(context, 'error')}: ${snapshot.error}',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            );
          }

          final reminders = snapshot.data ?? [];

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.tr(context, 'noScheduledReminders'),
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];

              return Card(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reminder.title ??
                                      AppLocalizations.tr(context, 'reminder'),
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (reminder.body != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    reminder.body!,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${AppLocalizations.tr(context, 'id')}: ${reminder.id}',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (reminder.payload != null &&
                          reminder.payload!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${AppLocalizations.tr(context, 'scheduled')}: ${reminder.payload}',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ConfirmDialog(
                                  title: AppLocalizations.tr(
                                    context,
                                    'cancelReminder',
                                  ),
                                  content: AppLocalizations.tr(
                                    context,
                                    'cancelReminder',
                                  ),
                                  cancelText: AppLocalizations.tr(
                                    context,
                                    'keep',
                                  ),
                                  confirmText: AppLocalizations.tr(
                                    context,
                                    'cancel',
                                  ),
                                  isDestructive: true,
                                  onConfirm: () {
                                    Navigator.pop(context);
                                    _deleteReminder(reminder.id);
                                  },
                                ),
                              );
                            },
                            icon: Icon(Icons.delete, color: primaryColor),
                            label: Text(
                              AppLocalizations.tr(context, 'cancel'),
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
