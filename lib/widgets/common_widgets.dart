import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatCard({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SortDropdown extends StatelessWidget {
  final Function(String) onSortChanged;

  const SortDropdown({
    Key? key,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xBF141928) : const Color(0xE5FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
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