// lib/screens/scan_screen.dart
import 'dart:io';
import 'dart:math' show pi, sin, cos;

import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/analysis_result.dart';
import 'package:brief_ai/services/document_extractor_service.dart';
import 'package:brief_ai/services/file_storage_service.dart';
import 'package:brief_ai/services/ocr_service.dart';
import 'package:brief_ai/services/pdf_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/confirm_dialog.dart';
import 'package:brief_ai/widgets/scan/analysis_bottom_sheet.dart';
import 'package:brief_ai/widgets/scan/scan_bottom_bar.dart';
import 'package:brief_ai/widgets/scan/scan_gallery.dart';
import 'package:brief_ai/widgets/scan/scan_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart';

/// Orchestrates the full scan flow with professional UI/UX:
///   1. Launch native scanner → collect image paths
///   2. Display images with immersive viewer
///   3. Analyze with beautiful animations
///   4. Show results with elegant bottom sheet
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  // ── Pages ──────────────────────────────────────────────────────────────────
  final List<String> _pages = [];
  int _currentIndex = 0;
  int? _documentId; // Track document ID for updates

  // ── View ───────────────────────────────────────────────────────────────────
  bool _showGallery = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ── Processing ─────────────────────────────────────────────────────────────
  bool _processing = false;
  String _processingStep = '';
  bool _generatingPdf = false;
  bool _showingMagicEffect = false;

  // ── Analysis result ────────────────────────────────────────────────────────
  AnalysisResult? _result;
  String _ocrText = '';
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.now().add(const Duration(days: 14));

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final existingImages = args?['existingImages'] as List<String>?;
      _documentId = args?['documentId'] as int?;

      if (existingImages != null && existingImages.isNotEmpty) {
        setState(() {
          _pages.addAll(existingImages);
          _currentIndex = 0;
        });
        _animationController.forward();
      } else {
        _launchScanner();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Scanner ────────────────────────────────────────────────────────────────

  Future<void> _launchScanner() async {
    HapticFeedback.lightImpact();
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

      final permanentPaths = await FileStorageService.instance.copyToAppStorage(
        cleaned,
      );

      setState(() {
        _pages.addAll(permanentPaths);
        _currentIndex = _pages.length - 1;
      });

      _animationController.forward();
      _snackSuccess(AppLocalizations.tr(context, 'photoCapturedSuccessfully'));

      await _performOcrAndShowDialog();
    } on DocScanException catch (e) {
      if (!mounted) return;
      final cancelled = e.code == 'SCAN_CANCELED' || e.code == 'SCAN_CANCELLED';
      if (!cancelled) {
        _snackError(
          '${AppLocalizations.tr(context, 'errorTakingPhoto')}: ${e.message}',
        );
      }
      if (_pages.isEmpty) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snackError('${AppLocalizations.tr(context, 'errorTakingPhoto')}: $e');
      if (_pages.isEmpty) Navigator.pop(context);
    }
  }

  // ── Category Dialog ────────────────────────────────────────────────────────

  Future<void> _performOcrAndShowDialog() async {
    setState(() => _showingMagicEffect = true);

    try {
      // Add slight delay for better UX
      // await Future.delayed(const Duration(milliseconds: 600));
      final data = await _detectCategory();

      setState(() => _showingMagicEffect = false);
      if (!mounted) return;

      HapticFeedback.mediumImpact();
      _showCategoryDialog(data);
    } catch (e) {
      setState(() => _showingMagicEffect = false);
      if (!mounted) return;
      _snackError('${AppLocalizations.tr(context, 'analysisFailed')}: $e');
    }
  }

  Future<void> _showCategoryDialog(Map<String, dynamic> data) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = data['category'] == null
        ? AppLocalizations.tr(context, 'generalDocument')
        : AppLocalizations.tr(context, data['category']);
    final deadline =
        data['deadline'] as DateTime? ??
        DateTime.now().add(const Duration(days: 14));

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppTheme.darkCard, AppTheme.darkBackground]
                    : [AppTheme.lightCard, Colors.white],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary)
                      .withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                                  ? AppTheme.darkPrimary
                                  : AppTheme.lightPrimary)
                              .withOpacity(0.2),
                          (isDark
                                  ? AppTheme.darkPrimary
                                  : AppTheme.lightPrimary)
                              .withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.5, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isDark
                                    ? AppTheme.darkPrimary
                                    : AppTheme.lightPrimary),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isDark
                                                ? AppTheme.darkPrimary
                                                : AppTheme.lightPrimary)
                                            .withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.description_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    AppLocalizations.tr(context, 'documentDetected'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    AppLocalizations.tr(context, 'weFoundDocument'),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Category card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppTheme.darkPrimary
                                  : AppTheme.lightPrimary)
                              .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            (isDark
                                    ? AppTheme.darkPrimary
                                    : AppTheme.lightPrimary)
                                .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        _buildInfoRow(
                          icon: Icons.label_outline,
                          label: AppLocalizations.tr(context, 'category'),
                          value: category,
                          isDark: isDark,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),

                        // Deadline
                        _buildInfoRow(
                          icon: Icons.event_outlined,
                          label: AppLocalizations.tr(context, 'deadline'),
                          value:
                              '${deadline.day}/${deadline.month}/${deadline.year}',
                          isDark: isDark,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),

                        // Risk Level
                        _buildRiskRow(deadline: deadline, isDark: isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      // PDF Button
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.picture_as_pdf_rounded,
                          label: AppLocalizations.tr(context, 'savePdf'),
                          isPrimary: false,
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(ctx);
                            _handlePdfExport();
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // AI Analyze Button
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.bolt_rounded,
                          label: AppLocalizations.tr(context, 'whatNext'),
                          isPrimary: true,
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(ctx);
                            _analyze();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskRow({required DateTime deadline, required bool isDark}) {
    final now = DateTime.now();
    final daysLeft = deadline.difference(now).inDays;

    Color riskColor;
    IconData riskIcon;
    String riskText;

    if (daysLeft < 0) {
      riskColor = isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
      riskIcon = Icons.error_outline;
      riskText = AppLocalizations.tr(context, 'overdue');
    } else if (daysLeft <= 3) {
      riskColor = isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
      riskIcon = Icons.warning_amber_rounded;
      riskText =
          '${AppLocalizations.tr(context, 'high')} - $daysLeft ${AppLocalizations.tr(context, 'daysLeft')}';
    } else if (daysLeft <= 7) {
      riskColor = Colors.orange;
      riskIcon = Icons.info_outline;
      riskText =
          '${AppLocalizations.tr(context, 'medium')} - $daysLeft ${AppLocalizations.tr(context, 'daysLeft')}';
    } else {
      riskColor = isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
      riskIcon = Icons.check_circle_outline;
      riskText =
          '${AppLocalizations.tr(context, 'low')} - $daysLeft ${AppLocalizations.tr(context, 'daysLeft')}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed_outlined, size: 18, color: riskColor),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.tr(context, 'riskLevel'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Row(
            children: [
              Icon(riskIcon, size: 16, color: riskColor),
              const SizedBox(width: 6),
              Text(
                riskText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: riskColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    if (isPrimary) {
      return _PulsingActionButton(
        icon: icon,
        label: label,
        isDark: isDark,
        onTap: onTap,
      );
    } else {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? AppTheme.darkTextPrimary
              : AppTheme.lightTextPrimary,
          side: BorderSide(
            width: 1.5,
            color:
                (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary)
                    .withOpacity(0.3),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _detectCategory() async {
    if (_pages.isEmpty) return {'category': 'Unknown'};
    try {
      final text = await OcrService.instance.recogniseAll(_pages);
      final result = DocumentExtractorService.instance.extract(text);
      return {'category': result.category, 'deadline': result.deadline};
    } catch (e) {
      return {'category': null};
    }
  }

  // ── Analysis ───────────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    if (_pages.isEmpty) {
      _snackError(AppLocalizations.tr(context, 'pleaseCaptureOrSelectImages'));
      return;
    }

    HapticFeedback.mediumImpact();

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

      await Future.delayed(const Duration(milliseconds: 600));
      final result = DocumentExtractorService.instance.extract(text);

      setState(() {
        _result = result;
        _ocrText = text;
        _deadline =
            result.deadline ?? DateTime.now().add(const Duration(days: 14));
        _processing = false;
        _processingStep = '';
      });

      HapticFeedback.heavyImpact();
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
      ocrText: _ocrText,
      documentId: _documentId,
      onSave: (d) => setState(() => _deadline = d),
    );
  }

  Future<void> _handlePdfExport() async {
    setState(() => _generatingPdf = true);
    HapticFeedback.lightImpact();

    try {
      final path = await PdfService.instance.generateAndSave(_pages);
      if (!mounted) return;
      setState(() => _generatingPdf = false);

      if (path != null) {
        HapticFeedback.heavyImpact();
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

  void _navigate(int dir) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = (_currentIndex + dir).clamp(0, _pages.length - 1);
    });
  }

  void _deleteCurrentPage() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: AppLocalizations.tr(context, 'deleteImage'),
        content: AppLocalizations.tr(context, 'deleteImageConfirmation'),
        confirmText: AppLocalizations.tr(context, 'delete'),
        isDestructive: true,
        onConfirm: () {
          HapticFeedback.heavyImpact();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [AppTheme.darkBackground, AppTheme.darkSurface]
                      : [AppTheme.lightBackground, Colors.white],
                ),
              ),
            ),

            // Main content with animations
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                );
              },
              child: _showGallery
                  ? ScanGallery(
                      imagePaths: _pages,
                      selectedIndex: _currentIndex,
                      onSelect: (i) => setState(() {
                        _currentIndex = i;
                        _showGallery = false;
                        HapticFeedback.selectionClick();
                      }),
                      onDelete: _deletePageAtIndex,
                      onClose: () => setState(() => _showGallery = false),
                    )
                  : _buildViewer(),
            ),

            // Processing overlay
            if (_processing)
              _ProcessingOverlay(
                label: _processingStep.isNotEmpty
                    ? _processingStep
                    : AppLocalizations.tr(context, 'processing'),
              ),

            // Magic animation
            if (_showingMagicEffect) const _MagicLoadingAnimation(),
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: hasPages ? _buildImageViewer() : _buildEmptyState(isDark),
        ),

        // Page counter with animation
        if (multiPage)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * value,
                      child: child,
                    ),
                  );
                },
                child: _PageCounter(
                  current: _currentIndex + 1,
                  total: _pages.length,
                ),
              ),
            ),
          ),

        // Navigation arrows with animations
        if (multiPage)
          _SwipeNavArrows(
            canGoBack: _currentIndex > 0,
            canGoForward: _currentIndex < _pages.length - 1,
            onBack: () => _navigate(-1),
            onForward: () => _navigate(1),
          ),

        // Top bar
        ScanTopBar(
          hasImages: hasPages,
          onClose: () => Navigator.pop(context),
          onDelete: _deleteCurrentPage,
          onToggleGallery: () => setState(() => _showGallery = true),
        ),

        // Bottom bar
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
        if (d.primaryVelocity! > 0 && _currentIndex > 0) {
          _navigate(-1);
        } else if (d.primaryVelocity! < 0 &&
            _currentIndex < _pages.length - 1) {
          _navigate(1);
        }
      },
      child: Hero(
        tag: 'scan-image-${_pages[_currentIndex]}',
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(20),
              child: Image.file(
                File(_pages[_currentIndex]),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
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
              );
            },
          ),

          const SizedBox(height: 32),

          // Text with fade animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.tr(context, 'cameraPreview'),
                      style: TextStyle(
                        color:
                            (isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary)
                                .withOpacity(0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
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
                                .withOpacity(0.6),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Consolidated small widgets ─────────────────────────────────────────────

/// Small pill showing "current / total" page numbers with modern design.
class _PageCounter extends StatelessWidget {
  const _PageCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Text(
                current.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'of',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Left / right arrow overlays for page-by-page navigation with modern design.
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
            const SizedBox(width: 60),
          if (canGoForward)
            _Arrow(icon: Icons.chevron_right, onTap: onForward)
          else
            const SizedBox(width: 60),
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
        margin: const EdgeInsets.all(16),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.3),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: Icon(icon, size: 32, color: Colors.white)),
      ),
    );
  }
}

/// Semi-transparent overlay with a spinner and step label.
/// Shown during OCR and extraction with modern design.
class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppTheme.darkCard, AppTheme.darkBackground]
                    : [AppTheme.lightCard, Colors.white],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 0,
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
                // Animated spinner
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    Icon(Icons.auto_awesome, color: primaryColor, size: 28),
                  ],
                ),

                const SizedBox(height: 28),

                // Step label
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

/// Professional magic loading animation - Google Lens/Image Search style
class _MagicLoadingAnimation extends StatefulWidget {
  const _MagicLoadingAnimation();

  @override
  State<_MagicLoadingAnimation> createState() => _MagicLoadingAnimationState();
}

class _MagicLoadingAnimationState extends State<_MagicLoadingAnimation>
    with TickerProviderStateMixin {
  // Changed to TickerProviderStateMixin
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller for continuous effects
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Pulse controller for breathing effects
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Shimmer controller for text effects
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Ripple animation
    _rippleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation for scanning effect
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _mainController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Container(
      color: isDark
          ? Colors.black.withOpacity(0.85)
          : Colors.white.withOpacity(0.85),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _pulseController,
          _shimmerController,
        ]),
        builder: (context, child) {
          return Stack(
            children: [
              // Subtle gradient background with movement
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        0.5 + 0.1 * sin(_mainController.value * 2 * pi),
                        0.5 + 0.1 * cos(_mainController.value * 2 * pi),
                      ),
                      colors: [
                        primaryColor.withOpacity(0.1),
                        secondaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
              ),

              // Scanning beam effect (like Google Lens)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanningBeamPainter(
                    animation: _mainController.value,
                    color: primaryColor,
                  ),
                ),
              ),

              // Corner brackets (Google Lens style)
              ..._buildCornerBrackets(primaryColor),

              // Center content with Google Lens style
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Outer ripple ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                primaryColor.withOpacity(0.0),
                                primaryColor.withOpacity(
                                  0.1 * _rippleAnimation.value,
                                ),
                                primaryColor.withOpacity(0.0),
                              ],
                              stops: const [0.4, 0.7, 1.0],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  startAngle: 0,
                                  endAngle: 2 * pi,
                                  transform: GradientRotation(
                                    _rotateAnimation.value,
                                  ),
                                  colors: [
                                    primaryColor.withOpacity(0.3),
                                    secondaryColor.withOpacity(0.3),
                                    primaryColor.withOpacity(0.3),
                                    Colors.transparent,
                                    primaryColor.withOpacity(0.3),
                                  ],
                                  stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [primaryColor, secondaryColor],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Google Lens style text with shimmer
                    _ShimmerText(
                      text: 'Analyzing document',
                      controller: _shimmerController,
                      primaryColor: primaryColor,
                      secondaryColor: secondaryColor,
                    ),

                    const SizedBox(height: 12),

                    // Subtle hint text
                    Text(
                      'Detecting content and structure',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Progress indicator (Google Lens style)
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _mainController,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                widthFactor:
                                    0.3 +
                                    0.4 * sin(_mainController.value * pi).abs(),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryColor, secondaryColor],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Floating particles (Google Lens style)
              ..._buildParticles(primaryColor, secondaryColor),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerBrackets(Color primaryColor) {
    return [
      // Top-left bracket
      Positioned(
        top: 50,
        left: 30,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: primaryColor, width: 2),
                    left: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // Top-right bracket
      Positioned(
        top: 50,
        right: 30,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: primaryColor, width: 2),
                    right: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // Bottom-left bracket
      Positioned(
        bottom: 50,
        left: 30,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: primaryColor, width: 2),
                    left: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // Bottom-right bracket
      Positioned(
        bottom: 50,
        right: 30,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: primaryColor, width: 2),
                    right: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildParticles(Color primaryColor, Color secondaryColor) {
    return List.generate(12, (index) {
      final angle = (index / 12) * 2 * pi + _mainController.value * 2 * pi;
      final radius =
          200.0 + 30 * sin(_mainController.value * 2 * pi + index).abs();
      final size = MediaQuery.of(context).size;

      return Positioned(
        left: size.width / 2 + radius * cos(angle) - 4,
        top: size.height / 2 + radius * sin(angle) - 4,
        child: Opacity(
          opacity:
              0.2 + 0.2 * sin(_mainController.value * 2 * pi + index).abs(),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index % 2 == 0 ? primaryColor : secondaryColor,
              boxShadow: [
                BoxShadow(
                  color: (index % 2 == 0 ? primaryColor : secondaryColor)
                      .withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Custom painter for scanning beam effect (Google Lens style)
class _ScanningBeamPainter extends CustomPainter {
  final double animation;
  final Color color;

  _ScanningBeamPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final beamY = size.height * (0.3 + 0.4 * sin(animation * 2 * pi).abs());

    // Gradient beam
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.15),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, beamY - 40, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, beamY - 40, size.width, 80), beamPaint);

    // Main scan line
    final linePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, beamY), Offset(size.width, beamY), linePaint);

    // Scanning dots
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.2 + 0.6 * (i / 4));
      final dotOpacity = 0.4 + 0.4 * sin(animation * 2 * pi + i * 2).abs();

      dotPaint.color = color.withOpacity(dotOpacity);
      canvas.drawCircle(Offset(x, beamY), 3, dotPaint);

      // Small glow
      dotPaint.color = color.withOpacity(dotOpacity * 0.3);
      canvas.drawCircle(Offset(x, beamY), 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Professional shimmer text effect - Google Lens style
class _ShimmerText extends StatefulWidget {
  final String text;
  final AnimationController controller;
  final Color primaryColor;
  final Color secondaryColor;

  const _ShimmerText({
    required this.text,
    required this.controller,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText> {
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Create a subtle opacity pulse
    _opacityAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: widget.controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _opacityAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: ShaderMask(
            shaderCallback: (bounds) {
              // Create a sweeping gradient that moves across the text
              final gradientWidth = bounds.width * 2;
              final position =
                  (widget.controller.value * gradientWidth) - bounds.width;

              return LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  widget.primaryColor,
                  widget.secondaryColor,
                  widget.primaryColor,
                  Colors.white.withOpacity(0.2),
                ],
                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                transform: _SlideGradientTransform(position),
              ).createShader(
                Rect.fromLTWH(
                  -position,
                  0,
                  bounds.width + gradientWidth,
                  bounds.height,
                ),
              );
            },
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom gradient transform for sliding effect
class _SlideGradientTransform extends GradientTransform {
  final double offset;

  const _SlideGradientTransform(this.offset);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(offset, 0, 0);
  }
}

/// Pulsing animated button for AI Analyze action
class _PulsingActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _PulsingActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_PulsingActionButton> createState() => _PulsingActionButtonState();
}

class _PulsingActionButtonState extends State<_PulsingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start the infinite pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            onPressed: widget.onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isDark
                  ? AppTheme.darkPrimary
                  : AppTheme.lightPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 22),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
