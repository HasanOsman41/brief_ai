// lib/widgets/what_you_should_card.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A small highlighted card used to surface a quick action reminder.
///
/// Designed to be shown prominently in forms or dialogs where the user needs
/// to take a specific next step.
class WhatYouShouldCard extends StatefulWidget {
  const WhatYouShouldCard({
    super.key,
    required this.isDark,
    required this.primary,
    required this.nextStepTitleKeys,
    this.customStepTexts,
    this.enablePulseAnimation = false,
  });

  final bool isDark;
  final Color primary;
  final List<String> nextStepTitleKeys;
  /// When provided (non-null and non-empty), these strings are rendered
  /// verbatim instead of looking up [nextStepTitleKeys] in localization.
  /// Used for free-form steps entered by the user when the category is "Other".
  final List<String>? customStepTexts;
  final bool enablePulseAnimation;

  @override
  State<WhatYouShouldCard> createState() => _WhatYouShouldCardState();
}

class _WhatYouShouldCardState extends State<WhatYouShouldCard>
    with SingleTickerProviderStateMixin {
  List<String> _resolveSteps(BuildContext context) {
    final custom = widget.customStepTexts;
    if (custom != null && custom.isNotEmpty) return custom;
    return widget.nextStepTitleKeys
        .map((k) => AppLocalizations.tr(context, k))
        .toList(growable: false);
  }

  AnimationController? _pulseController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.enablePulseAnimation) {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );

      // Start the infinite pulse animation
      _pulseController!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? widget.primary.withOpacity(0.18)
            : widget.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.primary.withOpacity(0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: widget.primary.withOpacity(0.25),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: widget.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, 'whatYouShould'),
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.w700,
                        color: widget.isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                ),
                const SizedBox(height: 6),
                ..._resolveSteps(context).asMap().entries.map((entry) {
                  int index = entry.key;
                  String text = entry.value;

                  return Text(
                    "${index + 1}. $text",
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ) ??
                        TextStyle(
                          color: widget.isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );

    // Return animated version if pulse is enabled
    if (widget.enablePulseAnimation && _scaleAnimation != null) {
      return AnimatedBuilder(
        animation: _scaleAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation!.value,
            child: cardContent,
          );
        },
      );
    }

    // Return static version if no animation
    return cardContent;
  }
}
