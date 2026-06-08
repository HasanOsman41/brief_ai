// lib/screens/onboarding_screen.dart
import 'package:brief_ai/cubit/auth_cubit/auth_cubit.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/main.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:brief_ai/widgets/language_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo and title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Image.asset(
                    'assets/icons/logo.png', 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.document_scanner,
                        size: 60,
                        color: primaryColor,
                      );
                    },
                  ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.tr(context, 'appName'),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.tr(context, 'briefAIDescription'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Privacy features
              GlassCard(
                child: Column(
                  children: [
                    _buildPrivacyFeature(
                      context,
                      Icons.lock_outline,
                      AppLocalizations.tr(context, 'localStorage'),
                      AppLocalizations.tr(context, 'localStorageDescription'),
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyFeature(
                      context,
                      Icons.offline_bolt_outlined,
                      AppLocalizations.tr(context, 'offlineFirst'),
                      AppLocalizations.tr(context, 'offlineFirstDescription'),
                    ),
                    const SizedBox(height: 16),
                    _buildPrivacyFeature(
                      context,
                      Icons.privacy_tip_outlined,
                      AppLocalizations.tr(context, 'gdprCompliant'),
                      AppLocalizations.tr(context, 'gdprDescription'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Accept button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_completed', true);
                    if (!context.mounted) return;
                    final state = context.read<AuthCubit>().state;
                    final route = state is Authenticated ? '/home' : '/login';
                    Navigator.pushReplacementNamed(context, route);
                  },
                  child: Text(AppLocalizations.tr(context, 'acceptPrivacy')),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                AppLocalizations.tr(context, 'privacyConsent'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const Spacer(),
            ],
          ),
        ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      ),
                      color: primaryColor,
                      onPressed: () => BriefAIApp.toggleTheme(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.language_outlined),
                      color: primaryColor,
                      onPressed: () => LanguageSheet.show(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyFeature(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
