// lib/widgets/confirm_dialog.dart
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A reusable confirmation dialog with two actions (cancel + confirm).
///
/// Use in place of repeating AlertDialog setups across the app.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText = 'Cancel',
    this.onCancel,
    this.confirmColor,
    this.isDestructive = false,
  }) : super(key: key);

  final String title;
  final String content;
  final String confirmText;
  final VoidCallback onConfirm;
  final String cancelText;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveConfirmColor =
        confirmColor ??
        (isDestructive
            ? (isDark ? AppTheme.darkDanger : AppTheme.lightDanger)
            : (isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess));

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(title),
      content: Text(content),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onCancel ?? () => Navigator.pop(context),
                child: Text(
                  cancelText,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveConfirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(confirmText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
