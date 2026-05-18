import 'package:flutter/material.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/main.dart'; // For BriefAIApp.setLocale
import 'package:shared_preferences/shared_preferences.dart';

/// Reusable language selection bottom sheet
class LanguageSheet {
  static const _languages = [
    _LangOption(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    _LangOption(code: 'en', name: 'English', flag: '🇬🇧'),
    _LangOption(code: 'ar', name: 'العربية', flag: '🇸🇦'),
  ];

  /// Shows the language selection bottom sheet
  static Future<void> show(BuildContext context) async {
    final primary = Theme.of(context).colorScheme.primary;
    final currentCode = Localizations.localeOf(context).languageCode;

    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LanguageSheetContent(
        languages: _languages,
        currentCode: currentCode,
        primaryColor: primary,
        onLanguageSelected: (code) => _handleLanguageChange(context, code),
      ),
    );
  }

  /// Handles language change: persists preference + updates app locale
  static Future<void> _handleLanguageChange(
    BuildContext context,
    String languageCode,
  ) async {
    try {
      // Save preference for persistence across app restarts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);

      // Update app locale using your global method
      BriefAIApp.setLocale(context, Locale(languageCode));

      // Show confirmation using localized strings
      if (context.mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr(context, 'languageChanged')),
            backgroundColor: isDark
                ? AppTheme.darkSuccess
                : AppTheme.lightSuccess,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Internal widget for the sheet content (keeps logic separate from static API)
class _LanguageSheetContent extends StatelessWidget {
  final List<_LangOption> languages;
  final String currentCode;
  final Color primaryColor;
  final Function(String) onLanguageSelected;

  const _LanguageSheetContent({
    required this.languages,
    required this.currentCode,
    required this.primaryColor,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              AppLocalizations.tr(context, 'language'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Language list
            for (int i = 0; i < languages.length; i++) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  languages[i].flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(languages[i].name),
                trailing: currentCode == languages[i].code
                    ? Icon(Icons.check_circle, color: primaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onLanguageSelected(languages[i].code);
                },
              ),
              if (i < languages.length - 1) const Divider(height: 1),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Simple data class for language options
class _LangOption {
  final String code;
  final String name;
  final String flag;
  const _LangOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}
