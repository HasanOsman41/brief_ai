// lib/screens/document_detail_screen.dart
import 'dart:io';

import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/confirm_dialog.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:brief_ai/widgets/what_you_should_card.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _reminderEnabled = true;
  bool _reminder3Days = true;
  bool _reminder1Day = true;
  bool _reminder12Hours = false;
  bool _reminderCustom = false;

  int _currentPage = 0;
  late DateTime _dueDate;
  late DateTime _addedDate;
  Document? _document;
  bool _isLoading = false;
  String ocrText = "";

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Use post-frame callback to access context safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocument();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);

    try {
      // Get the arguments - this needs to be done after the widget is built
      final args = _getArguments();

      if (args == null) {
        throw Exception('Document ID not provided');
      }

      final documentId = args['documentId'] as int?;

      if (documentId == null) {
        throw Exception('Document ID not provided');
      }

      final document = await DocumentService().getDocumentById(documentId);

      if (!mounted) return;

      if (document != null) {
        setState(() {
          _document = document;
          _dueDate =
              document.deadline ?? DateTime.now().add(const Duration(days: 30));
          _addedDate = document.createdAt;
          _reminderEnabled =
              document.reminder3DaysTime != null ||
              document.reminder1DayTime != null ||
              document.reminder12HoursTime != null ||
              document.reminderCustomTime != null;
          _reminder3Days = document.reminder3DaysTime != null;
          _reminder1Day = document.reminder1DayTime != null;
          _reminder12Hours = document.reminder12HoursTime != null;
          _reminderCustom = document.reminderCustomTime != null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Use WidgetsBinding to show snackbar after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar('Error loading document: $e');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper method to safely get arguments after build
  Map<String, dynamic>? _getArguments() {
    // This will be called from a post-frame callback or from build method
    return ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkDanger
            : AppTheme.lightDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return _buildLoadingScreen(primaryColor);
    }

    if (_document == null) {
      return _buildErrorScreen(context);
    }

    final imagePaths = _document?.imagePaths ?? [];

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen image viewer
          if (imagePaths.isNotEmpty)
            Positioned.fill(
              child: PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF2C3E50),
                      isDark
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFF34495E),
                    ],
                  ),
                ),
                pageController: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: Image.file(File(imagePaths[index])).image,
                    initialScale: PhotoViewComputedScale.contained,
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: imagePaths[index],
                    ),
                  );
                },
                itemCount: imagePaths.length,
              ),
            ),
          // App bar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Status badge at top
                    _buildStatusBadge(isDark),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () => _showShareOptions(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            color: isDark
                                ? AppTheme.darkCard
                                : AppTheme.lightCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (value) async {
                              switch (value) {
                                case 'edit':
                                  if (_document?.imagePaths != null &&
                                      _document?.id != null) {
                                    Navigator.pushNamed(
                                      context,
                                      '/scan',
                                      arguments: {
                                        'existingImages': _document!.imagePaths,
                                        'documentId': _document!.id,
                                      },
                                    );
                                  }
                                  break;
                                case 'export':
                                  break;
                                case 'delete':
                                  _showDeleteDialog(context);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(AppLocalizations.tr(context, 'edit')),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'export',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.tr(context, 'exportPDF'),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: isDark
                                          ? AppTheme.darkDanger
                                          : AppTheme.lightDanger,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.tr(context, 'delete'),
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.darkDanger
                                            : AppTheme.lightDanger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Page indicator
          if (imagePaths.length > 1)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imagePaths.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),

          // Scrollable content card
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const [0.35, 0.7, 0.95],
            builder: (context, scrollController) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, -8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, -15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Enhanced handle bar with indicator
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.6),
                                  primaryColor.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 30,
                            height: 2,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Enhanced content with fade effect
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.05, 0.95, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ListView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          children: [
                            _buildInfoPanel(context, isDark, primaryColor),
                            const SizedBox(height: 20),
                            _buildSummarySection(context, isDark),
                            const SizedBox(height: 20),
                            WhatYouShouldCard(
                              isDark: isDark,
                              primary: primaryColor,
                            ),
                            const SizedBox(height: 20),
                            if (_reminderEnabled)
                              _buildReminderOptions(context, primaryColor),
                            const SizedBox(height: 20),
                            _buildRiskLevelSection(context, isDark),
                            const SizedBox(height: 20),
                            _buildActionButtonsSection(context, isDark),
                            const SizedBox(height: 100),
                          ],
                        ),
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

  Widget _buildLoadingScreen(Color primaryColor) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(primaryColor),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.tr(context, 'loadingDocument')),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Document not found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.tr(context, 'goBack')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryChip(context, primaryColor),
              Row(
                children: [
                  _buildDueDateChip(context, isDark),
                  const SizedBox(width: 8),
                  _buildReminderSwitch(primaryColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _document!.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildAddedDateRow(context),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppLocalizations.tr(context, _document!.categoryKey),
        style: TextStyle(
          color: primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDueDateChip(BuildContext context, bool isDark) {
    final hasDeadline = _document!.hasDeadline;
    final color = hasDeadline
        ? (isDark ? AppTheme.darkWarning : AppTheme.lightWarning)
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hasDeadline
            ? '${AppLocalizations.tr(context, 'dueDate')} ${_formatDate(_dueDate)}'
            : AppLocalizations.tr(context, 'noDeadline'),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildReminderSwitch(Color primaryColor) {
    return Icon(
      _reminderEnabled ? Icons.notifications_active : Icons.notifications_off,
      color: _reminderEnabled ? primaryColor : Colors.grey,
      size: 20,
    );
  }

  Widget _buildAddedDateRow(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 14,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        const SizedBox(width: 4),
        Text(
          '${AppLocalizations.tr(context, 'addedDate')} ${_formatDate(_addedDate)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderOptions(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.notifications_outlined, size: 16, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.tr(context, 'reminderOptions'),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReminderItem(
          context,
          '3 ${AppLocalizations.tr(context, 'daysBefore')}',
          _reminder3Days,
        ),
        const SizedBox(height: 8),
        _buildReminderItem(
          context,
          '1 ${AppLocalizations.tr(context, 'dayBefore')}',
          _reminder1Day,
        ),
        const SizedBox(height: 8),
        _buildReminderItem(
          context,
          '12 ${AppLocalizations.tr(context, 'hoursBefore')}',
          _reminder12Hours,
        ),
        const SizedBox(height: 8),
        _buildReminderItem(
          context,
          AppLocalizations.tr(context, 'customDateTime'),
          _reminderCustom,
        ),
        if (_reminderCustom) ...[
          const SizedBox(height: 12),
          _buildCustomReminderDisplay(context),
        ],
      ],
    );
  }

  Widget _buildCustomReminderDisplay(BuildContext context) {
    final customTime = _document?.reminderCustomTime;
    if (customTime == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(customTime),
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${customTime.hour.toString().padLeft(2, '0')}:${customTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(
    BuildContext context,
    String label,
    bool isChecked,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.circle_outlined,
            color: isChecked
                ? primaryColor
                : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context, bool isDark) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tr(context, 'summary'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _document!.summary.isNotEmpty
                ? _document!.summary
                : 'No summary available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelSection(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final daysLeft = _dueDate.difference(now).inDays;

    Color riskColor;
    String riskText;
    IconData riskIcon;

    if (daysLeft < 0) {
      riskColor = isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
      riskText = AppLocalizations.tr(context, 'overdue');
      riskIcon = Icons.error_outline;
    } else if (daysLeft <= 3) {
      riskColor = isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
      riskText = AppLocalizations.tr(context, 'high');
      riskIcon = Icons.warning_amber_rounded;
    } else if (daysLeft <= 7) {
      riskColor = Colors.orange;
      riskText = AppLocalizations.tr(context, 'medium');
      riskIcon = Icons.info_outline;
    } else {
      riskColor = isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
      riskText = AppLocalizations.tr(context, 'low');
      riskIcon = Icons.check_circle_outline;
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.speed_outlined, color: riskColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.tr(context, 'riskLevel'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(riskIcon, color: riskColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    riskText,
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    final isDone = _document?.statusKey == 'done';

    if (!isDone) {
      return const SizedBox.shrink();
    }

    final successColor = isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: successColor.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: successColor, size: 16),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.tr(context, 'done'),
            style: TextStyle(
              color: successColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection(BuildContext context, bool isDark) {
    final successColor = isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
    final isDone = _document?.statusKey == 'done';

    // Show completed label if document is done
    if (isDone) {
      return GlassCard(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [successColor, successColor.withOpacity(0.85)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.tr(context, 'done'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show action button if not done
    return GlassCard(
      child: SizedBox(
        height: 56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showMarkAsDoneDialog(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [successColor, successColor.withOpacity(0.85)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.tr(context, 'markAsDone'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(AppLocalizations.tr(context, 'shareImage')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'sharingImage')),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(AppLocalizations.tr(context, 'sharePDF')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'sharingPDF')),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: Text(AppLocalizations.tr(context, 'shareText')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'sharingText')),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkAsDoneDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: AppLocalizations.tr(context, 'markAsDone'),
        content: AppLocalizations.tr(context, 'markAsDoneConfirm'),
        confirmText: AppLocalizations.tr(context, 'markAsDone'),
        onConfirm: () async {
          Navigator.pop(context); // Close dialog

          if (_document?.id != null) {
            try {
              await DocumentService().markDocumentAsDone(_document!.id!);

              if (!mounted) return;

              // Update local state
              setState(() {
                _document = _document?.copyWith(statusKey: 'done');
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.tr(context, 'documentMarkedAsDone'),
                  ),
                  backgroundColor: isDark
                      ? AppTheme.darkSuccess
                      : AppTheme.lightSuccess,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              _showErrorSnackBar('Error marking document as done: $e');
            }
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: AppLocalizations.tr(context, 'deleteDocument'),
        content: AppLocalizations.tr(context, 'deleteDocumentConfirm'),
        confirmText: AppLocalizations.tr(context, 'delete'),
        isDestructive: true,
        onConfirm: () async {
          Navigator.pop(context); // Close dialog

          if (_document?.id != null) {
            try {
              await DocumentService().deleteDocument(_document!.id!);

              if (!mounted) return;

              Navigator.pop(context); // Return to previous screen

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.tr(context, 'documentDeleted'),
                  ),
                  backgroundColor: isDark
                      ? AppTheme.darkSuccess
                      : AppTheme.lightSuccess,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              _showErrorSnackBar('Error deleting document: $e');
            }
          }
        },
      ),
    );
  }
}
