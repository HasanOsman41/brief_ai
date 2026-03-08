// lib/widgets/scan/scan_bottom_bar.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The floating bottom panel: AI button + scan / gallery / delete action buttons.
class ScanBottomBar extends StatelessWidget {
  const ScanBottomBar({
    super.key,
    required this.pageCount,
    required this.onScan,
    required this.onAnalyze,
    required this.onOpenGallery,
    required this.onDelete,
    required this.onDownloadPdf,
    this.isPdfLoading = false,
  });

  final int pageCount;
  final VoidCallback onScan;
  final VoidCallback onAnalyze;
  final VoidCallback onOpenGallery;
  final VoidCallback onDelete;
  final VoidCallback onDownloadPdf;
  final bool isPdfLoading;

  bool get _hasPages => pageCount > 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasPages) ...[
            _AnalyzeButton(onTap: onAnalyze, isDark: isDark),
            const SizedBox(height: 14),
          ],
          _ActionBar(
            pageCount: pageCount,
            hasPages: _hasPages,
            isDark: isDark,
            primary: primary,
            onScan: onScan,
            onOpenGallery: onOpenGallery,
            onDelete: onDelete,            onDownloadPdf: onDownloadPdf,
            isPdfLoading: isPdfLoading,          ),
        ],
      ),
    );
  }
}

// ── Analyze button ─────────────────────────────────────────────────────────

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({required this.onTap, required this.isDark});
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.75), primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.tr(context, 'analyzeWithAI'),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action pill bar ────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.pageCount,
    required this.hasPages,
    required this.isDark,
    required this.primary,
    required this.onScan,
    required this.onOpenGallery,
    required this.onDelete,
    required this.onDownloadPdf,
    this.isPdfLoading = false,
  });

  final int pageCount;
  final bool hasPages;
  final bool isDark;
  final Color primary;
  final VoidCallback onScan;
  final VoidCallback onOpenGallery;
  final VoidCallback onDelete;
  final VoidCallback onDownloadPdf;
  final bool isPdfLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Camera/Scan button (always visible)
          _CircleActionButton(
            icon: Icons.document_scanner_outlined,
            label: AppLocalizations.tr(context, hasPages ? 'addPage' : 'cameraPreview'),
            highlighted: !hasPages,
            isDark: isDark,
            primary: primary,
            onTap: onScan,
          ),
          
          if (hasPages) ...[
            // Download PDF button
            _CircleActionButton(
              icon: Icons.picture_as_pdf_outlined,
              label: AppLocalizations.tr(context, 'downloadPdf'),
              isDark: isDark,
              primary: primary,
              onTap: onDownloadPdf,
              isLoading: isPdfLoading,
            ),
            
            // Delete button
            _CircleActionButton(
              icon: Icons.delete_outline,
              label: AppLocalizations.tr(context, 'delete'),
              isDark: isDark,
              primary: primary,
              onTap: onDelete,
              isDestructive: true,
            ),
            
            // Gallery button
            _CircleActionButton(
              icon: Icons.photo_library_outlined,
              label: AppLocalizations.tr(context, 'gallery'),
              isDark: isDark,
              primary: primary,
              onTap: onOpenGallery,
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.primary,
    required this.onTap,
    this.highlighted = false,
    this.isDestructive = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  final bool highlighted;
  final bool isDestructive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    if (isDestructive) {
      iconColor = isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
    } else if (highlighted) {
      iconColor = Colors.white;
    } else {
      iconColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlighted 
                ? primary 
                : (isDestructive 
                    ? (isDark ? AppTheme.darkDanger.withOpacity(0.15) : AppTheme.lightDanger.withOpacity(0.1))
                    : (isDark ? AppTheme.darkCard : AppTheme.lightCard)),
              shape: BoxShape.circle,
              boxShadow: highlighted 
                ? [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] 
                : null,
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              color: isDestructive 
                ? (isDark ? AppTheme.darkDanger : AppTheme.lightDanger)
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary), 
              fontSize: 10,
              fontWeight: isDestructive ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}