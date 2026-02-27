// lib/widgets/scan/scan_top_bar.dart
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Close, delete, and gallery-toggle buttons overlaid at the top of the viewer.
class ScanTopBar extends StatelessWidget {
  const ScanTopBar({
    super.key,
    required this.hasImages,
    required this.onClose,
    required this.onDelete,
    required this.onToggleGallery,
  });

  final bool hasImages;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onToggleGallery;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Pill(icon: Icons.close, onTap: onClose),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.darkSurface : AppTheme.lightSurface).withOpacity(0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, size: 22),
      ),
    );
  }
}
