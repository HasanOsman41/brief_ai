import 'package:flutter/material.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';

class DeadlinePicker extends StatelessWidget {
  const DeadlinePicker({
    super.key,
    required this.isDark,
    required this.primary,
    required this.date,
    required this.onChanged,
  });

  final bool isDark;
  final Color primary;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: primary,
                onPrimary: Theme.of(ctx).colorScheme.onPrimary,
                surface: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                onSurface: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ), dialogTheme: DialogThemeData(backgroundColor: isDark
                  ? AppTheme.darkBackground
                  : AppTheme.lightBackground),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              date != null
                  ? '${date!.day}.${date!.month}.${date!.year}'
                  : AppLocalizations.tr(context, 'noDateSelected'),
              style: TextStyle(
                color: date != null
                    ? (isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary)
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_calendar, color: primary, size: 16),
          ],
        ),
      ),
    );
  }
}
