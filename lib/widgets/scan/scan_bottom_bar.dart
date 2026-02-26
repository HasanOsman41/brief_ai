// lib/widgets/scan/scan_bottom_bar.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The floating bottom panel: AI button + scan / gallery action buttons.
class ScanBottomBar extends StatelessWidget {
  const ScanBottomBar({
    super.key,
    required this.pageCount,
    required this.onScan,
    required this.onAnalyze,
    required this.onOpenGallery,
  });

  final int pageCount;
  final VoidCallback onScan;
  final VoidCallback onAnalyze;
  final VoidCallback onOpenGallery;

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
          ),
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
    final secondary = isDark ? AppTheme.darkSecondary : AppTheme.lightSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [secondary.withOpacity(0.75), secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: secondary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
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
  });

  final int pageCount;
  final bool hasPages;
  final bool isDark;
  final Color primary;
  final VoidCallback onScan;
  final VoidCallback onOpenGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        mainAxisAlignment: hasPages ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
        children: [
          _CircleActionButton(
            icon: Icons.document_scanner_outlined,
            label: AppLocalizations.tr(context, hasPages ? 'addPage' : 'cameraPreview'),
            highlighted: !hasPages,
            isDark: isDark,
            primary: primary,
            onTap: onScan,
          ),
          if (hasPages) ...[
            _PageCountBadge(count: pageCount, isDark: isDark),
            _CircleActionButton(
              icon: Icons.photo_library_outlined,
              label: AppLocalizations.tr(context, 'filter'),
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

class _PageCountBadge extends StatelessWidget {
  const _PageCountBadge({required this.count, required this.isDark});
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(count == 1 ? 'page' : 'pages', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 11)),
      ],
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
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: highlighted ? primary : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
              shape: BoxShape.circle,
              boxShadow: highlighted ? [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Icon(icon, color: highlighted ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary), size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
