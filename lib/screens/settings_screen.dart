// lib/screens/settings_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const SettingsScreen({Key? key, required this.onToggleTheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final currentLanguage = _getCurrentLanguage(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr(context, 'settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance section
          Text(
            AppLocalizations.tr(context, 'appearance').toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: primaryColor,
                    ),
                  ),
                  title: Text(AppLocalizations.tr(context, 'darkMode')),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      onToggleTheme();
                    },
                    activeColor: primaryColor,
                  ),
                ),
                const Divider(height: 1),
                // Language Settings Item
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.language,
                      color: primaryColor,
                    ),
                  ),
                  title: Text(AppLocalizations.tr(context, 'language')),
                  subtitle: Text(
                    _getLanguageName(currentLanguage, context),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getLanguageFlag(currentLanguage),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ],
                  ),
                  onTap: () async {
                    final result = await Navigator.pushNamed(context, '/language');
                    if (result != null && context.mounted) {
                      // Language was changed, show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.tr(context, 'languageChanged')),
                          backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Data & Privacy section
          Text(
            AppLocalizations.tr(context, 'dataPrivacy').toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                _buildSettingsItem(
                  context: context,
                  icon: Icons.backup_outlined,
                  label: AppLocalizations.tr(context, 'exportBackup'),
                  onTap: () {
                    Navigator.pushNamed(context, '/backup');
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  context: context,
                  icon: Icons.restore_outlined,
                  label: AppLocalizations.tr(context, 'importBackup'),
                  onTap: () {
                    Navigator.pushNamed(context, '/backup');
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  context: context,
                  icon: Icons.privacy_tip_outlined,
                  label: AppLocalizations.tr(context, 'privacyPolicy'),
                  onTap: () {
                    Navigator.pushNamed(context, '/privacy');
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  context: context,
                  icon: Icons.delete_outline,
                  label: AppLocalizations.tr(context, 'deleteAllData'),
                  textColor: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
                  onTap: () {
                    _showDeleteDialog(context);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Legal section
          Text(
            AppLocalizations.tr(context, 'legal').toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                _buildSettingsItem(
                  context: context,
                  icon: Icons.info_outline,
                  label: AppLocalizations.tr(context, 'impressum'),
                  onTap: () {
                    Navigator.pushNamed(context, '/impressum');
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  context: context,
                  icon: Icons.gavel_outlined,
                  label: AppLocalizations.tr(context, 'termsOfService'),
                  onTap: () {
                    // Navigate to terms screen
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App info
          Center(
            child: Column(
              children: [
                Text(
                  '${AppLocalizations.tr(context, 'appName')} v1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.tr(context, 'localOnly'),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Disclaimer
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.tr(context, 'disclaimer'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: textColor ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      onTap: onTap,
    );
  }

  String _getCurrentLanguage(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode;
  }

  String _getLanguageName(String languageCode, BuildContext context) {
    switch (languageCode) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'Deutsch';
    }
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'de':
        return '🇩🇪';
      case 'en':
        return '🇬🇧';
      case 'ar':
        return '🇸🇦';
      default:
        return '🇩🇪';
    }
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