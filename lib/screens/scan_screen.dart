// lib/screens/scan_screen.dart
import 'dart:io';

import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/analysis_result.dart';
import 'package:brief_ai/services/document_extractor_service.dart';
import 'package:brief_ai/services/ocr_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/scan/analysis_bottom_sheet.dart';
import 'package:brief_ai/widgets/scan/page_counter.dart';
import 'package:brief_ai/widgets/scan/processing_overlay.dart';
import 'package:brief_ai/widgets/scan/scan_bottom_bar.dart';
import 'package:brief_ai/widgets/scan/scan_gallery.dart';
import 'package:brief_ai/widgets/scan/scan_top_bar.dart';
import 'package:brief_ai/widgets/scan/swipe_nav_arrows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

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
      _processingStep = 'Starting OCR…';
    });

    try {
      final text = await OcrService.instance.recogniseAll(
        _pages,
        onProgress: (cur, total) =>
            setState(() => _processingStep = 'OCR – page $cur / $total'),
      );

      if (text.isEmpty) {
        setState(() {
          _processing = false;
          _processingStep = '';
        });
        _snackError('No text found in the scanned images.');
        return;
      }

      setState(() => _processingStep = 'Extracting document info…');
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
      _snackError('Analysis failed: $e');
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

  void _snackSuccess(String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              ProcessingOverlay(
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
          child: hasPages
              ? GestureDetector(
                  onHorizontalDragEnd: (d) {
                    if (d.primaryVelocity! > 0 && _currentIndex > 0)
                      _navigate(-1);
                    else if (d.primaryVelocity! < 0 &&
                        _currentIndex < _pages.length - 1)
                      _navigate(1);
                  },
                  child: Image.file(
                    File(_pages[_currentIndex]),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner_outlined,
                        size: 80,
                        color:
                            (isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary)
                                .withOpacity(0.25),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.tr(context, 'cameraPreview'),
                        style: TextStyle(
                          color:
                              (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary)
                                  .withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        if (multiPage)
          PageCounter(current: _currentIndex + 1, total: _pages.length),
        if (multiPage)
          SwipeNavArrows(
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
          onOpenGallery: () => setState(() => _showGallery = true),
        ),
      ],
    );
  }
}
