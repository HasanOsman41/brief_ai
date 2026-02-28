// lib/widgets/document_card.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class DocumentCard extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final String? deadline; // Changed from DateTime? to String?
  final String status;
  final bool hasDeadline;
  final String? imagePath; // Renamed from image to imagePath and made nullable
  final VoidCallback onTap;

  const DocumentCard({
    Key? key,
    required this.title,
    required this.category,
    required this.date,
    this.deadline, // Now accepts String?
    required this.status,
    this.imagePath, // Now nullable
    this.hasDeadline = false,
    required this.onTap,
  }) : super(key: key);

  String _getDeadlineText(BuildContext context, String? deadlineStr) {
    if (deadlineStr == null) return '';

    try {
      // Parse the deadline string (format: "DD.MM.YYYY")
      final parts = deadlineStr.split('.');
      if (parts.length != 3) return '';

      final day = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 0;
      final year = int.tryParse(parts[2]) ?? 0;

      if (day == 0 || month == 0 || year == 0) return '';

      final deadlineDate = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final daysUntil = deadlineDate.difference(today).inDays;

      if (daysUntil == 0) {
        return AppLocalizations.tr(context, 'today');
      } else if (daysUntil == 1) {
        return AppLocalizations.tr(context, 'tomorrow');
      } else if (daysUntil > 1) {
        return '$daysUntil ${AppLocalizations.tr(context, 'daysLeft')}';
      } else if (daysUntil < 0) {
        return AppLocalizations.tr(context, 'overdue');
      }
    } catch (e) {
      // If parsing fails, return empty string
      return '';
    }

    return '';
  }

  bool _isDeadlineNear(String? deadlineStr) {
    if (deadlineStr == null) return false;

    try {
      final parts = deadlineStr.split('.');
      if (parts.length != 3) return false;

      final day = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 0;
      final year = int.tryParse(parts[2]) ?? 0;

      if (day == 0 || month == 0 || year == 0) return false;

      final deadlineDate = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final daysUntil = deadlineDate.difference(today).inDays;
      return daysUntil <= 3 && daysUntil >= 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isDeadlineNear = _isDeadlineNear(deadline);
    final deadlineText = _getDeadlineText(context, deadline);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Document preview thumbnail
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                image: imagePath != null
                    ? DecorationImage(
                        image: AssetImage('assets/docs/$imagePath'),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imagePath == null
                  ? Center(
                      child: Icon(
                        Icons.description_outlined,
                        size: 30,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Deadline warning badge
                      if (hasDeadline &&
                          isDeadlineNear &&
                          deadlineText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppTheme.darkWarning
                                        : AppTheme.lightWarning)
                                    .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('❗', style: TextStyle(fontSize: 10)),
                              const SizedBox(width: 2),
                              Text(
                                deadlineText,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkWarning
                                      : AppTheme.lightWarning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Document title
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(date, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),

            // Status icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: status == AppLocalizations.tr(context, 'done')
                    ? (isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess)
                          .withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == AppLocalizations.tr(context, 'done')
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: status == AppLocalizations.tr(context, 'done')
                    ? (isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess)
                    : Theme.of(context).textTheme.bodyMedium?.color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
