import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SortDropdown extends StatelessWidget {
  final Function(String) onSortChanged;

  const SortDropdown({Key? key, required this.onSortChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          onSortChanged(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sorted by ${_getSortLabel(context, value)}'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        offset: const Offset(0, 40),
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Text(
              AppLocalizations.tr(context, 'latest'),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ],
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'latest',
            child: Row(
              children: [
                Icon(Icons.access_time, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr(context, 'latest')),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'deadline',
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr(context, 'deadline')),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'category',
            child: Row(
              children: [
                Icon(Icons.category, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr(context, 'category')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(BuildContext context, String sortKey) {
    switch (sortKey) {
      case 'latest':
        return AppLocalizations.tr(context, 'latest');
      case 'deadline':
        return AppLocalizations.tr(context, 'deadline');
      case 'category':
        return AppLocalizations.tr(context, 'category');
      default:
        return sortKey;
    }
  }
}
