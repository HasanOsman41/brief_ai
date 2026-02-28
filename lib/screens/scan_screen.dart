// lib/screens/scan_screen.dart
import 'dart:io';

import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/analysis_result.dart';
import 'package:brief_ai/services/document_extractor_service.dart';
import 'package:brief_ai/services/ocr_service.dart';
import 'package:brief_ai/services/pdf_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/scan/analysis_bottom_sheet.dart';
import 'package:brief_ai/widgets/scan/scan_bottom_bar.dart';
import 'package:brief_ai/widgets/scan/scan_gallery.dart';
import 'package:brief_ai/widgets/scan/scan_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:open_file/open_file.dart';

/// Orchestrates the full scan flow:
///   1. Launch native scanner  →  collect image paths
///   2. Display images         →  viewer + gallery
///   3. Analyze                →  OCR → extraction → bottom sheet
///
/// All logic that is not state management lives in dedicated service classes.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // ── Pages ──────────────────────────────────────────────────────────────────
  final List<String> _pages = [];
  int _currentIndex = 0;

  // ── View ───────────────────────────────────────────────────────────────────
  bool _showGallery = false;

  // ── Processing ─────────────────────────────────────────────────────────────
  bool _processing = false;
  String _processingStep = '';
  bool _generatingPdf = false;

  // ── Analysis result ────────────────────────────────────────────────────────
  AnalysisResult? _result;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.now().add(const Duration(days: 14));
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchScanner());
  }

  // ── Scanner ────────────────────────────────────────────────────────────────

  Future<void> _launchScanner() async {
    try {
      final scan = await FlutterDocScanner().getScannedDocumentAsImages(
        page: 10,
      );
      if (!mounted) return;
      if (scan == null || scan.images.isEmpty) {
        if (_pages.isEmpty) Navigator.pop(context);
        return;
      }
      final cleaned = scan.images
          .map((p) => p.startsWith('file://') ? Uri.parse(p).toFilePath() : p)
          .where((p) => File(p).existsSync())
          .toList();
      setState(() {
        _pages.addAll(cleaned);
        _currentIndex = _pages.length - 1;
      });
      _snackSuccess(AppLocalizations.tr(context, 'photoCapturedSuccessfully'));
    } on DocScanException catch (e) {
      if (!mounted) return;
      final cancelled = e.code == 'SCAN_CANCELED' || e.code == 'SCAN_CANCELLED';
      if (!cancelled)
        _snackError(
          '${AppLocalizations.tr(context, 'errorTakingPhoto')}: ${e.message}',
        );
      if (_pages.isEmpty) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snackError('${AppLocalizations.tr(context, 'errorTakingPhoto')}: $e');
      if (_pages.isEmpty) Navigator.pop(context);
    }
  }

  // ── Analysis ───────────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    if (_pages.isEmpty) {
      _snackError(AppLocalizations.tr(context, 'pleaseCaptureOrSelectImages'));
      return;
    }
    setState(() {
      _processing = true;
      _processingStep = AppLocalizations.tr(context, 'startingOcr');
    });

    try {
      final text = await OcrService.instance.recogniseAll(
        _pages,
        onProgress: (cur, total) => setState(
          () => _processingStep =
              '${AppLocalizations.tr(context, 'ocrPage')} $cur / $total',
        ),
      );

      if (text.isEmpty) {
        setState(() {
          _processing = false;
          _processingStep = '';
        });
        _snackError(AppLocalizations.tr(context, 'noTextFound'));
        return;
      }

      setState(
        () => _processingStep = AppLocalizations.tr(
          context,
          'extractingDocumentInfo',
        ),
      );
      await Future.delayed(const Duration(milliseconds: 60));
      final result = DocumentExtractorService.instance.extract(text);

      setState(() {
        _result = result;
        _deadline =
            result.deadline ?? DateTime.now().add(const Duration(days: 14));
        _processing = false;
        _processingStep = '';
      });

      _showResults();
      _snackSuccess(AppLocalizations.tr(context, 'aiAnalysisComplete'));
    } catch (e) {
      setState(() {
        _processing = false;
        _processingStep = '';
      });
      _snackError('${AppLocalizations.tr(context, 'analysisFailed')}: $e');
    }
  }

  void _showResults() {
    if (_result == null) return;
    AnalysisBottomSheet.show(
      context,
      result: _result!,
      initialDeadline: _deadline,
      imagePaths: List.unmodifiable(_pages),
      onSave: (d) => setState(() => _deadline = d),
    );
  }

  Future<void> _handlePdfExport() async {
    setState(() => _generatingPdf = true);
    try {
      final path = await PdfService.instance.generateAndSave(_pages);
      if (!mounted) return;
      setState(() => _generatingPdf = false);
      if (path != null) {
        await OpenFile.open(path);
        _snackSuccess(
          AppLocalizations.tr(context, 'pdfDownloadStarted'),
          action: SnackBarAction(
            label: AppLocalizations.tr(context, 'open'),
            textColor: Colors.white,
            onPressed: () => OpenFile.open(path),
          ),
        );
      } else {
        _snackError(AppLocalizations.tr(context, 'errorPickingImage'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _generatingPdf = false);
      _snackError('Error: $e');
    }
  }

  // ── Page management ────────────────────────────────────────────────────────

  void _navigate(int dir) => setState(() {
    _currentIndex = (_currentIndex + dir).clamp(0, _pages.length - 1);
  });

  void _deleteCurrentPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.tr(context, 'deleteImage'),
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.tr(context, 'deleteImageConfirmation'),
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.tr(context, 'cancel'),
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppTheme.darkDanger
                  : AppTheme.lightDanger,
            ),
            onPressed: () {
              setState(() {
                _pages.removeAt(_currentIndex);
                if (_pages.isEmpty) {
                  _showGallery = false;
                  _currentIndex = 0;
                } else {
                  _currentIndex = _currentIndex.clamp(0, _pages.length - 1);
                }
              });
              Navigator.pop(ctx);
              _snackSuccess(AppLocalizations.tr(context, 'imageDeleted'));
            },
            child: Text(AppLocalizations.tr(context, 'delete')),
          ),
        ],
      ),
    );
  }

  void _deletePageAtIndex(int index) => setState(() {
    _pages.removeAt(index);
    if (_pages.isEmpty) {
      _showGallery = false;
      _currentIndex = 0;
    } else {
      _currentIndex = _currentIndex.clamp(0, _pages.length - 1);
    }
  });

  // ── Snackbars ──────────────────────────────────────────────────────────────

  void _snackSuccess(String msg, {SnackBarAction? action}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: action,
      ),
    );
  }

  void _snackError(String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (_showGallery)
              ScanGallery(
                imagePaths: _pages,
                selectedIndex: _currentIndex,
                onSelect: (i) => setState(() {
                  _currentIndex = i;
                  _showGallery = false;
                }),
                onDelete: _deletePageAtIndex,
                onClose: () => setState(() => _showGallery = false),
              )
            else
              _buildViewer(),
            if (_processing)
              _ProcessingOverlay(
                label: _processingStep.isNotEmpty
                    ? _processingStep
                    : AppLocalizations.tr(context, 'processing'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPages = _pages.isNotEmpty;
    final multiPage = _pages.length > 1;

    return Stack(
      children: [
        // Image / empty state
        Container(
          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          child: hasPages ? _buildImageViewer() : _buildEmptyState(isDark),
        ),

        if (multiPage)
          _PageCounter(current: _currentIndex + 1, total: _pages.length),
        if (multiPage)
          _SwipeNavArrows(
            canGoBack: _currentIndex > 0,
            canGoForward: _currentIndex < _pages.length - 1,
            onBack: () => _navigate(-1),
            onForward: () => _navigate(1),
          ),

        ScanTopBar(
          hasImages: hasPages,
          onClose: () => Navigator.pop(context),
          onDelete: _deleteCurrentPage,
          onToggleGallery: () => setState(() => _showGallery = true),
        ),

        ScanBottomBar(
          pageCount: _pages.length,
          onScan: _launchScanner,
          onAnalyze: _analyze,
          onDelete: _deleteCurrentPage,
          onOpenGallery: () => setState(() => _showGallery = true),
          onDownloadPdf: _handlePdfExport,
          isPdfLoading: _generatingPdf,
        ),
      ],
    );
  }

  Widget _buildImageViewer() {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity! > 0 && _currentIndex > 0)
          _navigate(-1);
        else if (d.primaryVelocity! < 0 && _currentIndex < _pages.length - 1)
          _navigate(1);
      },
      child: Hero(
        tag: 'scan-image-${_pages[_currentIndex]}',
        child: Image.file(
          File(_pages[_currentIndex]),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
                  .withOpacity(0.5),
            ),
            child: Icon(
              Icons.document_scanner_outlined,
              size: 80,
              color:
                  (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary)
                      .withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.tr(context, 'cameraPreview'),
            style: TextStyle(
              color:
                  (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary)
                      .withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr(context, 'tapToScan'),
            style: TextStyle(
              color:
                  (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary)
                      .withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Consolidated small widgets ─────────────────────────────────────────────

/// Small pill showing "current / total" page numbers.
class _PageCounter extends StatelessWidget {
  const _PageCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Center(
                  child: Text(
                    current.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                total.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Left / right arrow overlays for page-by-page navigation.
class _SwipeNavArrows extends StatelessWidget {
  const _SwipeNavArrows({
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (canGoBack)
            _Arrow(icon: Icons.chevron_left, onTap: onBack)
          else
            const SizedBox(width: 56),
          if (canGoForward)
            _Arrow(icon: Icons.chevron_right, onTap: onForward)
          else
            const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}

/// Semi-transparent overlay with a spinner and step label.
/// Shown during OCR and extraction.
class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark
                      ? AppTheme.darkCard.withOpacity(0.9)
                      : AppTheme.lightCard,
                  isDark
                      ? AppTheme.darkCard
                      : AppTheme.lightCard.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    Icon(Icons.auto_awesome, color: primaryColor, size: 24),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
