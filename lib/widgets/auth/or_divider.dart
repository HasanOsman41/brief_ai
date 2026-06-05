import 'package:brief_ai/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.textSecondary});

  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: textSecondary.withOpacity(0.25))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppLocalizations.tr(context, 'or_divider'),
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(child: Divider(color: textSecondary.withOpacity(0.25))),
      ],
    );
  }
}
