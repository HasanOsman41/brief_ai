// lib/screens/impressum_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class ImpressumScreen extends StatelessWidget {
  const ImpressumScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr(context, 'impressum')),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, 'legalInfo'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  AppLocalizations.tr(context, 'company'),
                  'BriefAI GmbH',
                ),
                _buildInfoRow(
                  context,
                  AppLocalizations.tr(context, 'address'),
                  'Musterstraße 123\n10115 Berlin',
                ),
                _buildInfoRow(
                  context,
                  AppLocalizations.tr(context, 'representedBy'),
                  'Max Mustermann',
                ),
                _buildInfoRow(
                  context,
                  AppLocalizations.tr(context, 'contact'),
                  'E-Mail: info@briefai.de\nTel: +49 30 123456789',
                ),
                _buildInfoRow(
                  context,
                  AppLocalizations.tr(context, 'register'),
                  'HRB 123456\nAmtsgericht Berlin',
                ),
                _buildInfoRow(
                  context,
                  AppLocalizations.tr(context, 'vatId'),
                  'DE123456789',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, 'disclaimer'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.tr(context, 'disclaimerContent1'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.tr(context, 'disclaimerContent2'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Additional GDPR/Privacy note
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.tr(context, 'dataProtection'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.tr(context, 'dataProtectionNote'),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
