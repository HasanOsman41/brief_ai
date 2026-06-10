// lib/screens/tabs/profile_tab.dart
import 'package:brief_ai/cubit/auth_cubit/auth_cubit.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/services/backup_service.dart';
import 'package:brief_ai/services/notification_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:brief_ai/widgets/language_sheet.dart';
import 'package:brief_ai/widgets/confirm_dialog.dart';
import 'package:brief_ai/widgets/professional_snackbar.dart';
import 'package:brief_ai/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final Function(Locale)? onLocaleChange;

  const ProfileTab({super.key, required this.onToggleTheme, this.onLocaleChange});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // ── Inline state ──────────────────────────────────────────
  bool _notificationsEnabled = true;
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
        ProfessionalSnackbar.success(
          context,
          AppLocalizations.tr(context, 'languageChanged'),
        );
      }
    } catch (e) {
      if (mounted) {
        ProfessionalSnackbar.error(context, 'Error changing language: $e');
      }
    }
  }

  void _showLanguageSheet() {
    LanguageSheet.show(context);
  }

  // ── Export/Import/Delete using BackupHelper ─────────────────
  Future<void> _exportBackup() async {
    AppLoadingDialog.show(
      context,
      message: AppLocalizations.tr(context, 'exportingData'),
    );

    final path = await _backupService.createBackup();

    if (mounted) {
      Navigator.pop(context);
      if (path != null) {
        ProfessionalSnackbar.success(
          context,
          AppLocalizations.tr(context, 'exportSuccess'),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    AppLoadingDialog.show(
      context,
      message: AppLocalizations.tr(context, 'importingData'),
    );

    final success = await _backupService.restoreBackup();

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        ProfessionalSnackbar.success(
          context,
          AppLocalizations.tr(context, 'importSuccess'),
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
    AppLoadingDialog.show(
      context,
      message: AppLocalizations.tr(context, 'deletingData'),
    );

    final success = await _backupService.deleteAllData();

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);

      if (success) {
        ProfessionalSnackbar.success(
          context,
          AppLocalizations.tr(context, 'dataDeleted'),
        );

        setState(() {});
      } else {
        ProfessionalSnackbar.error(
          context,
          AppLocalizations.tr(context, 'deleteFailed'),
        );
      }
    }
  }

  void _showDeleteDialog() {
    _deleteAllData();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: AppLocalizations.tr(ctx, 'sign_out'),
        content: AppLocalizations.tr(ctx, 'logout_confirm'),
        confirmText: AppLocalizations.tr(ctx, 'sign_out'),
        cancelText: AppLocalizations.tr(ctx, 'cancel'),
        isDestructive: true,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await context.read<AuthCubit>().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
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
                    _sendFeedback(controller.text, title);
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

  // Where feedback / problem reports are delivered.
  static const String _feedbackEmail = 'hasanosman41303@gmail.com';

  void _sendFeedback(String message, String subject) async {
    if (message.trim().isEmpty) return;

    // Keep a best-effort local copy so nothing is lost if the mail app fails.
    try {
      final directory = await getApplicationDocumentsDirectory();
      final feedbackFile = File('${directory.path}/feedback_log.txt');
      final feedbackEntry =
          '${DateTime.now().toIso8601String()} [$subject]: $message\n';
      await feedbackFile.writeAsString(feedbackEntry, mode: FileMode.append);
    } catch (_) {
      // Non-fatal: continue to the email step regardless.
    }

    final mailUri = Uri(
      scheme: 'mailto',
      path: _feedbackEmail,
      query: _encodeMailQuery({
        'subject': 'BriefAI – $subject',
        'body': message,
      }),
    );

    try {
      final launched = await launchUrl(
        mailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('No email app available');

      if (mounted) {
        ProfessionalSnackbar.success(
          context,
          AppLocalizations.tr(context, 'feedbackSent'),
        );
      }
    } catch (_) {
      if (mounted) {
        ProfessionalSnackbar.error(
          context,
          AppLocalizations.tr(context, 'noEmailApp'),
        );
      }
    }
  }

  // mailto requires each parameter to be individually percent-encoded;
  // Uri's default query encoding turns spaces into '+', which some mail
  // clients render literally.
  static String _encodeMailQuery(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
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
      // final prefs = await SharedPreferences.getInstance();
      final enabled = await NotificationService().areNotificationsEnabled();
      setState(() {
        _notificationsEnabled = enabled;
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
          icon: Icons.person_outline,
        ),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is Authenticated) {
                  final user = authState.user;
                  final name = (user.displayName?.trim().isNotEmpty ?? false)
                      ? user.displayName!.trim()
                      : (user.email ?? '');
                  final email = user.email ?? '';
                  return _LoggedInAccount(
                    userName: name,
                    userEmail: email,
                    planLabel: _getPlanLabel(),
                    planColor: _getPlanColor(isDark),
                    primaryColor: primary,
                    onUpgrade: () {
                      ProfessionalSnackbar.info(
                        context,
                        AppLocalizations.tr(context, 'upgradeComingSoon'),
                      );
                    },
                  );
                }
                return _NotLoggedIn(
                  primaryColor: primary,
                  onLogin: () => Navigator.pushNamed(context, '/login'),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── App ───────────────────────────────────────────────
        _SectionLabel(
          label: AppLocalizations.tr(context, 'appearance').toUpperCase(),
          color: textSecondary,
          icon: Icons.tune_rounded,
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

              const _InsetDivider(),

              _NavRow(
                icon: Icons.language_outlined,
                label: AppLocalizations.tr(context, 'language'),
                subtitle: '${_currentLang.flag}  ${_currentLang.name}',
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: _showLanguageSheet,
              ),

              const _InsetDivider(),

              _ToggleRow(
                icon: Icons.notifications_outlined,
                label: AppLocalizations.tr(context, 'notifications'),
                subtitle: _notificationsEnabled
                    ? AppLocalizations.tr(context, 'enabled')
                    : AppLocalizations.tr(context, 'disabled'),
                value: _notificationsEnabled,
                primaryColor: primary,
                onChanged: (val) async {
                  setState(() => _notificationsEnabled = val);
                  if (val) {
                    await NotificationService().enableNotifications();
                  } else {
                    await NotificationService().disableNotifications();
                  }
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
          icon: Icons.shield_outlined,
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
              const _InsetDivider(),
              _NavRow(
                icon: Icons.restore_outlined,
                label: AppLocalizations.tr(context, 'importBackup'),
                primaryColor: primary,
                textSecondary: textSecondary,
                onTap: _importBackup,
              ),
              const _InsetDivider(),
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
          icon: Icons.help_outline_rounded,
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
              const _InsetDivider(),
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
              const _InsetDivider(),
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
              const _InsetDivider(),
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
              const _InsetDivider(),
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

        // ── Sign out — placed at the end of the page, like most apps ──
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is! Authenticated) return const SizedBox.shrink();
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: Icon(Icons.logout_rounded, size: 18, color: danger),
                label: Text(
                  AppLocalizations.tr(context, 'sign_out'),
                  style: TextStyle(
                    color: danger,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: danger.withOpacity(0.40)),
                  backgroundColor: danger.withOpacity(isDark ? 0.08 : 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 28),

        // ── App footer ────────────────────────────────────────
        Center(
          child: Column(
            children: [
              // Logo mark
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: primary.withOpacity(0.10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.document_scanner,
                        size: 24,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.tr(context, 'appName'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                      fontSize: 11,
                    ),
              ),
            
              const SizedBox(height: 16),
              // Disclaimer — quiet supporting text rather than a heavy card
              Text(
                AppLocalizations.tr(context, 'disclaimer'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.5,
                      color: textSecondary,
                    ),
              ),
            ],
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
  final IconData? icon;
  const _SectionLabel({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inset hairline that aligns with the row's text (past the leading icon),
/// direction-aware so it flips correctly in RTL.
class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, indent: 64, endIndent: 16);
}

// ── Account states ────────────────────────────────────────────────────────────

class _LoggedInAccount extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String planLabel;
  final Color planColor;
  final Color primaryColor;
  final VoidCallback onUpgrade;

  const _LoggedInAccount({
    required this.userName,
    required this.userEmail,
    required this.planLabel,
    required this.planColor,
    required this.primaryColor,
    required this.onUpgrade,
  });

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final isFreePlan = planLabel == AppLocalizations.tr(context, 'planFree');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Gradient avatar with halo
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withOpacity(0.28),
                          primaryColor.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor,
                          primaryColor.withOpacity(0.72),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    userEmail,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Plan + call-to-action as ONE unit, so they read as a single
        // statement ("you're on Free → upgrade") instead of three loose
        // controls fighting for attention.
        if (isFreePlan)
          _UpgradeCard(
            planLabel: planLabel,
            primaryColor: primaryColor,
            isDark: isDark,
            onUpgrade: onUpgrade,
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: planColor.withOpacity(isDark ? 0.14 : 0.08),
              border: Border.all(color: planColor.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 20, color: planColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.tr(context, 'currentPlan'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      Text(
                        planLabel,
                        style: TextStyle(
                          color: planColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded, size: 18, color: planColor),
              ],
            ),
          ),
      ],
    );
  }
}

/// Free-plan promo: plan name, value proposition, and upgrade CTA in one
/// tappable card.
class _UpgradeCard extends StatelessWidget {
  final String planLabel;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onUpgrade;

  const _UpgradeCard({
    required this.planLabel,
    required this.primaryColor,
    required this.isDark,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onUpgrade,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(isDark ? 0.22 : 0.14),
                primaryColor.withOpacity(isDark ? 0.10 : 0.05),
              ],
            ),
            border: Border.all(color: primaryColor.withOpacity(0.30)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.72)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planLabel,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.tr(context, 'upgradeTagline'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11.5,
                            height: 1.25,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.tr(context, 'upgrade'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onLogin;

  const _NotLoggedIn({required this.primaryColor, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Column(
      children: [
        // Hero icon with halo
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withOpacity(0.28),
                      primaryColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.72),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.tr(context, 'notLoggedIn'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.tr(context, 'loginDescription'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12.5,
                color: textSecondary,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: onLogin,
            icon: const Icon(Icons.login_rounded, size: 18),
            label: Text(
              AppLocalizations.tr(context, 'sign_in'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
        activeThumbColor: primaryColor,
      ),
    );
  }
}
