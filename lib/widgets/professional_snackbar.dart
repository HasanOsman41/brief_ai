import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SnackbarType {
  success,
  error,
  warning,
  info,
}

class ProfessionalSnackbar {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    SnackbarType type = SnackbarType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color getColor() {
      switch (type) {
        case SnackbarType.success:
          return isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
        case SnackbarType.error:
          return isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
        case SnackbarType.warning:
          return isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
        case SnackbarType.info:
          return isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
      }
    }

    IconData getIcon() {
      switch (type) {
        case SnackbarType.success:
          return Icons.check_circle;
        case SnackbarType.error:
          return Icons.error;
        case SnackbarType.warning:
          return Icons.warning;
        case SnackbarType.info:
          return Icons.info;
      }
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: getColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  getIcon(),
                  color: getColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        duration: duration,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}