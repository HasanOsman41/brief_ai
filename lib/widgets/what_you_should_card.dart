// lib/widgets/what_you_should_card.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A small highlighted card used to surface a quick action reminder.
///
/// Designed to be shown prominently in forms or dialogs where the user needs
/// to take a specific next step.
class WhatYouShouldCard extends StatelessWidget {
  const WhatYouShouldCard({
    Key? key,
    required this.isDark,
    required this.primary,
    this.titleKey = 'whatYouShould',
    this.hintKey = 'whatYouShouldHint',
  }) : super(key: key);

  final bool isDark;
  final Color primary;
  final String titleKey;
  final String hintKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? primary.withOpacity(0.18) : primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, titleKey),
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.tr(context, hintKey),
                  style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ) ??
                      TextStyle(
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
    );
  }
}
