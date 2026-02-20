// lib/screens/backup_import_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
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
                                content: Text(AppLocalizations.tr(context, 'backupCreating')),
                                backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
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
                _buildBackupItem(
                  context,
                  'backup_2024_03_15.zip',
                  '15.03.2024, 14:30',
                  '245 MB',
                ),
                const Divider(height: 1),
                _buildBackupItem(
                  context,
                  'backup_2024_03_10.zip',
                  '10.03.2024, 09:15',
                  '198 MB',
                ),
                const Divider(height: 1),
                _buildBackupItem(
                  context,
                  'backup_2024_03_01.zip',
                  '01.03.2024, 18:45',
                  '312 MB',
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

  Widget _buildBackupItem(BuildContext context, String name, String date, String size) {
    return ListTile(
      title: Text(
        name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        '$date • $size',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.restore),
        onPressed: () {
          _showRestoreConfirmDialog(context, name);
        },
        color: Theme.of(context).colorScheme.primary,
        iconSize: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showImportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(AppLocalizations.tr(context, 'importBackup')),
        content: Text(AppLocalizations.tr(context, 'importConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.tr(context, 'cancel'),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.tr(context, 'backupImporting')),
                  backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(AppLocalizations.tr(context, 'import')),
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmDialog(BuildContext context, String backupName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(AppLocalizations.tr(context, 'restoreBackup')),
        content: Text(
          '${AppLocalizations.tr(context, 'restoreConfirmMessage')}\n\n$backupName',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.tr(context, 'cancel'),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.tr(context, 'backupRestoring')),
                  backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(AppLocalizations.tr(context, 'restore')),
          ),
        ],
      ),
    );
  }
}