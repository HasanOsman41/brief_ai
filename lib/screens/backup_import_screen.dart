// lib/screens/backup_import_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/backup_item_tile.dart';
import 'package:brief_ai/widgets/confirm_dialog.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class BackupImportScreen extends StatelessWidget {
  const BackupImportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr(context, 'backupImport')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            child: Column(
              children: [
                // First ListTile - Export
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Leading icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.backup_outlined,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      // Expanded content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.tr(context, 'createBackup'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.tr(context, 'exportDescription'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      // Trailing button
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.tr(
                                    context,
                                    'backupCreating',
                                  ),
                                ),
                                backgroundColor: isDark
                                    ? AppTheme.darkSuccess
                                    : AppTheme.lightSuccess,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.tr(context, 'export'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 32),

                // Second ListTile - Import
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Leading icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.restore_outlined,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      // Expanded content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.tr(context, 'restoreBackup'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.tr(context, 'importDescription'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      // Trailing button
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            _showImportDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.tr(context, 'import'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Recent backups section
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.tr(context, 'lastBackups'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                BackupItemTile(
                  name: 'backup_2024_03_15.zip',
                  date: '15.03.2024, 14:30',
                  size: '245 MB',
                  onRestorePressed: () => _showRestoreConfirmDialog(
                    context,
                    'backup_2024_03_15.zip',
                  ),
                ),
                const Divider(height: 1),
                BackupItemTile(
                  name: 'backup_2024_03_10.zip',
                  date: '10.03.2024, 09:15',
                  size: '198 MB',
                  onRestorePressed: () => _showRestoreConfirmDialog(
                    context,
                    'backup_2024_03_10.zip',
                  ),
                ),
                const Divider(height: 1),
                BackupItemTile(
                  name: 'backup_2024_03_01.zip',
                  date: '01.03.2024, 18:45',
                  size: '312 MB',
                  onRestorePressed: () => _showRestoreConfirmDialog(
                    context,
                    'backup_2024_03_01.zip',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Information section
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.tr(context, 'information'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.tr(context, 'backupInfo'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: AppLocalizations.tr(context, 'importBackup'),
        content: AppLocalizations.tr(context, 'importConfirmMessage'),
        confirmText: AppLocalizations.tr(context, 'import'),
        onConfirm: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.tr(context, 'backupImporting')),
              backgroundColor: isDark
                  ? AppTheme.darkSuccess
                  : AppTheme.lightSuccess,
            ),
          );
        },
      ),
    );
  }

  void _showRestoreConfirmDialog(BuildContext context, String backupName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: AppLocalizations.tr(context, 'restoreBackup'),
        content:
            '${AppLocalizations.tr(context, 'restoreConfirmMessage')}\n\n$backupName',
        confirmText: AppLocalizations.tr(context, 'restore'),
        onConfirm: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.tr(context, 'backupRestoring')),
              backgroundColor: isDark
                  ? AppTheme.darkSuccess
                  : AppTheme.lightSuccess,
            ),
          );
        },
      ),
    );
  }
}
