// lib/screens/privacy_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr(context, 'privacyPolicy')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Main privacy card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.security,
                        color: primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.tr(context, 'yourDataIsSafe'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            AppLocalizations.tr(context, 'localStorage'),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPrivacyPoint(
                  context,
                  Icons.lock_outline,
                  AppLocalizations.tr(context, 'localStorage'),
                  AppLocalizations.tr(context, 'localStorageDetailed'),
                ),
                const SizedBox(height: 16),
                _buildPrivacyPoint(
                  context,
                  Icons.offline_bolt_outlined,
                  AppLocalizations.tr(context, 'offlineFirst'),
                  AppLocalizations.tr(context, 'offlineFirstDetailed'),
                ),
                const SizedBox(height: 16),
                _buildPrivacyPoint(
                  context,
                  Icons.backup_outlined,
                  AppLocalizations.tr(context, 'backups'),
                  AppLocalizations.tr(context, 'backupsDetailed'),
                ),
                const SizedBox(height: 16),
                _buildPrivacyPoint(
                  context,
                  Icons.notifications_outlined,
                  AppLocalizations.tr(context, 'notifications'),
                  AppLocalizations.tr(context, 'notificationsDetailed'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // GDPR Rights card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, 'yourRights'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildRightItem(
                  context,
                  AppLocalizations.tr(context, 'rightToAccess'),
                  AppLocalizations.tr(context, 'rightToAccessDescription'),
                ),
                _buildRightItem(
                  context,
                  AppLocalizations.tr(context, 'rightToErasure'),
                  AppLocalizations.tr(context, 'rightToErasureDescription'),
                ),
                _buildRightItem(
                  context,
                  AppLocalizations.tr(context, 'rightToPortability'),
                  AppLocalizations.tr(context, 'rightToPortabilityDescription'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.tr(context, 'backupCreating')),
                        backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
                      ),
                    );
                  },
                  child: Text(AppLocalizations.tr(context, 'exportMyData')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showDeleteDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
                    side: BorderSide(
                      color: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
                    ),
                  ),
                  child: Text(AppLocalizations.tr(context, 'deleteMyData')),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Additional info
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.tr(context, 'dataProtection'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.tr(context, 'dataProtectionNote'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(BuildContext context, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(AppLocalizations.tr(context, 'deleteConfirmTitle')),
        content: Text(AppLocalizations.tr(context, 'deleteConfirmMessage')),
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
                  content: Text(AppLocalizations.tr(context, 'dataDeleted')),
                  backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
            ),
            child: Text(AppLocalizations.tr(context, 'delete')),
          ),
        ],
      ),
    );
  }
}