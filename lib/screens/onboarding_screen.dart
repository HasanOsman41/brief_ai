// lib/screens/onboarding_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
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
                      child: Icon(
                        Icons.document_scanner,
                        size: 50,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.tr(context, 'appName'),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.tr(context, 'safeDocumentScanner'),
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
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
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
