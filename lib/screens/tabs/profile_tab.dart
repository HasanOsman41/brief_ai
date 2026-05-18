// lib/screens/tabs/profile_tab.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/services/backup_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:brief_ai/widgets/language_sheet.dart';
import 'package:brief_ai/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final Function(Locale)? onLocaleChange;

  const ProfileTab({Key? key, required this.onToggleTheme, this.onLocaleChange})
    : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // ── Inline state ──────────────────────────────────────────
  bool _notificationsEnabled = true;

  // TODO: replace with real auth / user state
  bool _isLoggedIn = false;
  final String _userName = 'Max Mustermann';
  final String _userEmail = 'max@beispiel.de';
  final String _planKey = 'free'; // 'free' | 'pro' | 'team'

  // Backup helper instance
  final BackupService _backupService = BackupService();

  // ── Language ──────────────────────────────────────────────
  static const _languages = [
    _LangOption(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    _LangOption(code: 'en', name: 'English', flag: '🇬🇧'),
    _LangOption(code: 'ar', name: 'العربية', flag: '🇸🇦'),
  ];

  _LangOption get _currentLang {
    final code = Localizations.localeOf(context).languageCode;
    return _languages.firstWhere(
      (l) => l.code == code,
      orElse: () => _languages.first,
    );
  }

  // Working language change
  Future<void> _changeLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);

      final locale = Locale(languageCode);

      if (widget.onLocaleChange != null) {
        widget.onLocaleChange!(locale);
      }

      if (mounted) {
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
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing language: $e'),
            backgroundColor:
                isDark //
                ? AppTheme.darkDanger
                : AppTheme.lightDanger,
          ),
        );
      }
    }
  }

  void _showLanguageSheet() {
    LanguageSheet.show(context);
  }

  // ── Export/Import/Delete using BackupHelper ─────────────────
  Future<void> _exportBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final path = await _backupService.createBackup();

    if (mounted) {
      Navigator.pop(context);
      if (path != null) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr(context, 'exportSuccess')),
            backgroundColor: isDark
                ? AppTheme.darkSuccess
                : AppTheme.lightSuccess,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _backupService.restoreBackup();

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr(context, 'importSuccess')),
            backgroundColor: isDark
                ? AppTheme.darkSuccess
                : AppTheme.lightSuccess,
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {});
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: AppLocalizations.tr(ctx, 'deleteAllData'),
        content: AppLocalizations.tr(ctx, 'deleteAllDataConfirm'),
        confirmText: AppLocalizations.tr(ctx, 'delete'),
        cancelText: AppLocalizations.tr(ctx, 'cancel'),
        isDestructive: true,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _backupService.deleteAllData();

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);

      if (success) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr(context, 'dataDeleted')),
            backgroundColor: isDark
                ? AppTheme.darkSuccess
                : AppTheme.lightSuccess,
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {});
      } else {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr(context, 'deleteFailed')),
            backgroundColor: isDark
                ? AppTheme.darkDanger
                : AppTheme.lightDanger,
          ),
        );
      }
    }
  }

  void _showDeleteDialog() {
    _deleteAllData();
  }

  // ── Feedback / Report ──────────────────────────────────────
  void _showFeedbackSheet({required String title, required String hint}) {
    final primary = Theme.of(context).colorScheme.primary;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sendFeedback(controller.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.tr(context, 'send')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendFeedback(String message) async {
    if (message.trim().isEmpty) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final feedbackFile = File('${directory.path}/feedback_log.txt');
      final feedbackEntry = '${DateTime.now().toIso8601String()}: $message\n';
      await feedbackFile.writeAsString(feedbackEntry, mode: FileMode.append);

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.tr(context, 'feedbackSent')),
            backgroundColor: isDark
                ? AppTheme.darkSuccess
                : AppTheme.lightSuccess,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending feedback: $e'),
            backgroundColor: isDark
                ? AppTheme.darkDanger
                : AppTheme.lightDanger,
          ),
        );
      }
    }
  }

  // ── Legal bottom sheets ───────────────────────────────────
  void _showLegalSheet({required String title, required String bodyKey}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomScrollView(
                controller: scrollCtrl,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.tr(ctx, bodyKey),
                          style: Theme.of(
                            ctx,
                          ).textTheme.bodyMedium?.copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  String _getPlanLabel() {
    switch (_planKey) {
      case 'pro':
        return AppLocalizations.tr(context, 'planPro');
      case 'team':
        return AppLocalizations.tr(context, 'planTeam');
      default:
        return AppLocalizations.tr(context, 'planFree');
    }
  }

  Color _getPlanColor(bool isDark) {
    switch (_planKey) {
      case 'pro':
        return isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
      case 'team':
        return isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
      default:
        return isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary;
    }
  }

  // Load saved preferences on init
  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications') ?? true;
      });
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      print('Error saving preference: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final danger = isDark ? AppTheme.darkDanger : AppTheme.lightDanger;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // ── Account ───────────────────────────────────────────
        _SectionLabel(
          label: AppLocalizations.tr(context, 'account').toUpperCase(),
          color: textSecondary,
        ),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoggedIn
                ? _LoggedInAccount(
                    userName: _userName,
                    userEmail: _userEmail,
                    planLabel: _getPlanLabel(),
                    planColor: _getPlanColor(isDark),
                    primaryColor: primary,
                    onUpgrade: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Upgrade feature coming soon!'),
                        ),
                      );
                    },
                    onLogout: () {
                      setState(() {
                        _isLoggedIn = false;
                      });
                    },
                  )
                : _NotLoggedIn(
                    primaryColor: primary,
                    onLogin: () {
                      setState(() {
                        _isLoggedIn = true;
                      });
                    },
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // ── App ───────────────────────────────────────────────
        _SectionLabel(
          label: AppLocalizations.tr(context, 'appearance').toUpperCase(),
          color: textSecondary,
        ),
        GlassCard(
          child: Column(
            children: [
              _ToggleRow(
                icon: isDark ? Icons.dark_mode : Icons.light_mode,
                label: AppLocalizations.tr(context, 'darkMode'),
                subtitle: AppLocalizations.tr(context, 'darkModeDescription'),
                value: isDark,
                primaryColor: primary,
                onChanged: (_) => widget.onToggleTheme(),
              ),

              const Divider(height: 1),

              _NavRow(
                icon: Icons.language_outlined,
                label: AppLocalizations.tr(context, 'language'),
                subtitle: '${_currentLang.flag}  ${_currentLang.name}',
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: _showLanguageSheet,
              ),

              const Divider(height: 1),

              _ToggleRow(
                icon: Icons.notifications_outlined,
                label: AppLocalizations.tr(context, 'notifications'),
                subtitle: _notificationsEnabled
                    ? AppLocalizations.tr(context, 'enabled')
                    : AppLocalizations.tr(context, 'disabled'),
                value: _notificationsEnabled,
                primaryColor: primary,
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                  _savePreference('notifications', val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Daten & Datenschutz ───────────────────────────────
        _SectionLabel(
          label: AppLocalizations.tr(context, 'dataPrivacy').toUpperCase(),
          color: textSecondary,
        ),
        GlassCard(
          child: Column(
            children: [
              _NavRow(
                icon: Icons.backup_outlined,
                label: AppLocalizations.tr(context, 'exportBackup'),
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: _exportBackup,
              ),
              const Divider(height: 1),
              _NavRow(
                icon: Icons.restore_outlined,
                label: AppLocalizations.tr(context, 'importBackup'),
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: _importBackup,
              ),
              const Divider(height: 1),
              _NavRow(
                icon: Icons.delete_outline,
                label: AppLocalizations.tr(context, 'deleteAllData'),
                primaryColor: primary,
                textSecondary: textSecondary,
                labelColor: danger,
                iconColor: danger,
                onTap: _showDeleteDialog,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Hilfe & Rechtliches ───────────────────────────────
        _SectionLabel(
          label: AppLocalizations.tr(context, 'legal').toUpperCase(),
          color: textSecondary,
        ),
        GlassCard(
          child: Column(
            children: [
              _NavRow(
                icon: Icons.chat_bubble_outline,
                label: AppLocalizations.tr(context, 'sendFeedback'),
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: () => _showFeedbackSheet(
                  title: AppLocalizations.tr(context, 'sendFeedback'),
                  hint: AppLocalizations.tr(context, 'feedbackHint'),
                ),
              ),
              const Divider(height: 1),
              _NavRow(
                icon: Icons.flag_outlined,
                label: AppLocalizations.tr(context, 'reportProblem'),
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: () => _showFeedbackSheet(
                  title: AppLocalizations.tr(context, 'reportProblem'),
                  hint: AppLocalizations.tr(context, 'problemHint'),
                ),
              ),
              const Divider(height: 1),
              _NavRow(
                icon: Icons.privacy_tip_outlined,
                label: AppLocalizations.tr(context, 'privacyPolicy'),
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: () => _showLegalSheet(
                  title: AppLocalizations.tr(context, 'privacyPolicy'),
                  bodyKey: 'privacyPolicyBody',
                ),
              ),
              const Divider(height: 1),
              _NavRow(
                icon: Icons.info_outline,
                label: AppLocalizations.tr(context, 'impressum'),
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: () => _showLegalSheet(
                  title: AppLocalizations.tr(context, 'impressum'),
                  bodyKey: 'impressumBody',
                ),
              ),
              const Divider(height: 1),
              _NavRow(
                icon: Icons.gavel_outlined,
                label: AppLocalizations.tr(context, 'termsOfService'),
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: () => _showLegalSheet(
                  title: AppLocalizations.tr(context, 'termsOfService'),
                  bodyKey: 'termsOfServiceBody',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── App info ──────────────────────────────────────────
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
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: primary),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.tr(context, 'localOnly'),
                      style: TextStyle(
                        color: primary,
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

        const SizedBox(height: 16),

        // ── Disclaimer ────────────────────────────────────────
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Account states ────────────────────────────────────────────────────────────

class _LoggedInAccount extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String planLabel;
  final Color planColor;
  final Color primaryColor;
  final VoidCallback onUpgrade;
  final VoidCallback onLogout;

  const _LoggedInAccount({
    required this.userName,
    required this.userEmail,
    required this.planLabel,
    required this.planColor,
    required this.primaryColor,
    required this.onUpgrade,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isFreePlan = planLabel == AppLocalizations.tr(context, 'planFree');

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: planColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: planColor),
                  const SizedBox(width: 5),
                  Text(
                    planLabel,
                    style: TextStyle(
                      color: planColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isFreePlan)
              GestureDetector(
                onTap: onUpgrade,
                child: Text(
                  '${AppLocalizations.tr(context, 'upgrade')} →',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onLogout,
          child: Text(
            AppLocalizations.tr(context, 'logout'),
            style: TextStyle(
              color:
                  isDark(context) // ✅ Helper for theme-aware danger color
                  ? AppTheme.darkDanger
                  : AppTheme.lightDanger,
            ),
          ),
        ),
      ],
    );
  }

  bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

class _NotLoggedIn extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onLogin;

  const _NotLoggedIn({required this.primaryColor, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.person_outline, size: 48, color: primaryColor),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.tr(context, 'notLoggedIn'),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.tr(context, 'loginDescription'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onLogin,
            icon: const Icon(Icons.login, size: 18),
            label: Text(AppLocalizations.tr(context, 'login')),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Row helpers ───────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color primaryColor;
  final Color textSecondary;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.primaryColor,
    required this.textSecondary,
    this.labelColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = iconColor ?? primaryColor;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveIcon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveIcon, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: textSecondary),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: textSecondary, size: 20),
      onTap: onTap,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color primaryColor;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
      ),
    );
  }
}
