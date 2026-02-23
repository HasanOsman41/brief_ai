// lib/screens/scan_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/services/notification_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Mock data models for prototype
class AnalysisResult {
  final String summary;
  final DateTime deadline;

  AnalysisResult({required this.summary, required this.deadline});
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  List<File> _capturedImages = [];
  File? _currentImage;
  final ImagePicker _picker = ImagePicker();
  bool _isFlashOn = false;
  int _currentIndex = 0;
  bool _showGalleryView = false;

  // State variables for prototype
  bool _isProcessing = false;
  AnalysisResult? _analysisResult;

  // Editable deadline
  late DateTime _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _selectedDeadline = DateTime.now().add(const Duration(days: 14));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _capturedImages.add(File(pickedFile.path));
          _currentImage = _capturedImages.last;
          _currentIndex = _capturedImages.length - 1;
          _showGalleryView = false;
        });
        _showSuccessMessage('Image added successfully');
      }
    } catch (e) {
      _showErrorMessage('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedImages.add(File(photo.path));
          _currentImage = _capturedImages.last;
          _currentIndex = _capturedImages.length - 1;
          _showGalleryView = false;
        });
        _showSuccessMessage('Photo captured successfully');
      }
    } catch (e) {
      _showErrorMessage('Error taking photo: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            _capturedImages.add(File(file.path));
          }
          _currentImage = _capturedImages.last;
          _currentIndex = _capturedImages.length - 1;
        });
        _showSuccessMessage('${pickedFiles.length} images added');
      }
    } catch (e) {
      _showErrorMessage('Error picking multiple images: $e');
    }
  }

  // Simple AI analysis function
  Future<void> _analyzeWithAI() async {
    if (_capturedImages.isEmpty) {
      _showErrorMessage('Please capture or select images first');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate AI analysis delay
    await Future.delayed(const Duration(seconds: 2));

    // Simple mock result
    AnalysisResult mockResult = AnalysisResult(
      summary:
          'Weiterbewilligungsantrag für Leistungen nach dem SGB II. '
          'Der Antrag muss vollständig ausgefüllt beim zuständigen Jobcenter eingereicht werden.',
      deadline: DateTime.now().add(const Duration(days: 14)),
    );

    setState(() {
      _analysisResult = mockResult;
      _selectedDeadline = mockResult.deadline;
      _isProcessing = false;
    });

    // Show simple bottom sheet
    _showSimpleBottomSheet();

    _showSuccessMessage('AI analysis complete');
  }

  void _showSimpleBottomSheet() {
    if (_analysisResult == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Create local variables for the bottom sheet
    DateTime localSelectedDeadline = _selectedDeadline;
    bool localReminderEnabled = true;

    // Local state for reminder options
    bool localReminder3Days = true;
    bool localReminder1Day = true;
    bool localReminder12Hours = false;
    bool localReminderCustom = false;
    DateTime? localCustomReminderTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBackground
                  : AppTheme.lightBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header with Save Button (fixed)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppLocalizations.tr(
                                  context,
                                  'aiAnalysisResults',
                                ),
                                maxLines: 2,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Save Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDeadline = localSelectedDeadline;
                              });

                              // Generate notification ID from summary (document title)
                              final docTitle = _analysisResult!.summary
                                  .split('.')
                                  .first
                                  .substring(
                                    0,
                                    (_analysisResult!.summary
                                                .split('.')
                                                .first
                                                .length >
                                            30
                                        ? 30
                                        : _analysisResult!.summary
                                              .split('.')
                                              .first
                                              .length),
                                  );

                              if (localReminderEnabled) {
                                final deadlineText =
                                    '${AppLocalizations.tr(context, 'deadline')}: ${localSelectedDeadline.day}.${localSelectedDeadline.month}.${localSelectedDeadline.year}';

                                // 3 days before
                                if (localReminder3Days) {
                                  final dt = DateTime(
                                    localSelectedDeadline.year,
                                    localSelectedDeadline.month,
                                    localSelectedDeadline.day,
                                    9,
                                  ).subtract(const Duration(days: 3));
                                  NotificationService().scheduleNotification(
                                    docTitle.hashCode.abs(),
                                    docTitle,
                                    deadlineText,
                                    dt,
                                    payload:
                                        '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                  );
                                }

                                // 1 day before
                                if (localReminder1Day) {
                                  final dt = DateTime(
                                    localSelectedDeadline.year,
                                    localSelectedDeadline.month,
                                    localSelectedDeadline.day,
                                    9,
                                  ).subtract(const Duration(days: 1));
                                  NotificationService().scheduleNotification(
                                    (docTitle.hashCode.abs() + 1),
                                    docTitle,
                                    deadlineText,
                                    dt,
                                    payload:
                                        '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                  );
                                }

                                // 12 hours before
                                if (localReminder12Hours) {
                                  final dt = DateTime(
                                    localSelectedDeadline.year,
                                    localSelectedDeadline.month,
                                    localSelectedDeadline.day,
                                    9,
                                  ).subtract(const Duration(hours: 12));
                                  NotificationService().scheduleNotification(
                                    (docTitle.hashCode.abs() + 2),
                                    docTitle,
                                    deadlineText,
                                    dt,
                                    payload:
                                        '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                  );
                                }

                                // Custom date/time
                                if (localReminderCustom &&
                                    localCustomReminderTime != null) {
                                  NotificationService().scheduleNotification(
                                    (docTitle.hashCode.abs() + 3),
                                    docTitle,
                                    deadlineText,
                                    localCustomReminderTime!,
                                    payload:
                                        '${localCustomReminderTime!.day}.${localCustomReminderTime!.month}.${localCustomReminderTime!.year} ${localCustomReminderTime!.hour.toString().padLeft(2, '0')}:${localCustomReminderTime!.minute.toString().padLeft(2, '0')}',
                                  );
                                }
                              }

                              Navigator.pop(context);
                              _showSuccessMessage(
                                AppLocalizations.tr(context, 'analysisSaved'),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.save,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.tr(context, 'save'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Summary
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkCard
                                : AppTheme.lightCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.tr(context, 'summary'),
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _analysisResult!.summary,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Editable Date with Reminder Switch
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkCard
                                : AppTheme.lightCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Date row
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.tr(
                                            context,
                                            'deadline',
                                          ),
                                          style: TextStyle(
                                            color: isDark
                                                ? AppTheme.darkTextSecondary
                                                : AppTheme.lightTextSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () async {
                                            DateTime?
                                            pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  localSelectedDeadline,
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(
                                                const Duration(days: 365),
                                              ),
                                              builder: (context, child) {
                                                return Theme(
                                                  data: Theme.of(context).copyWith(
                                                    colorScheme: ColorScheme.light(
                                                      primary: primaryColor,
                                                      onPrimary: Colors.white,
                                                      surface: isDark
                                                          ? AppTheme.darkCard
                                                          : AppTheme.lightCard,
                                                      onSurface: isDark
                                                          ? AppTheme
                                                                .darkTextPrimary
                                                          : AppTheme
                                                                .lightTextPrimary,
                                                    ),
                                                    dialogBackgroundColor:
                                                        isDark
                                                        ? AppTheme
                                                              .darkBackground
                                                        : AppTheme
                                                              .lightBackground,
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );
                                            if (pickedDate != null) {
                                              setSheetState(() {
                                                localSelectedDeadline =
                                                    pickedDate;
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppTheme.darkBackground
                                                  : AppTheme.lightBackground,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark
                                                    ? AppTheme.darkBorder
                                                    : AppTheme.lightBorder,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${localSelectedDeadline.day}.${localSelectedDeadline.month}.${localSelectedDeadline.year}',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? AppTheme
                                                              .darkTextPrimary
                                                        : AppTheme
                                                              .lightTextPrimary,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.edit_calendar,
                                                  color: primaryColor,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Reminder Switch
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_outlined,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.tr(context, 'reminder'),
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.lightTextPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: localReminderEnabled,
                                    onChanged: (value) {
                                      setSheetState(() {
                                        localReminderEnabled = value;
                                      });
                                    },
                                    activeColor: primaryColor,
                                  ),
                                ],
                              ),

                              // Reminder options (shown when reminder is enabled)
                              if (localReminderEnabled) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkBackground
                                        : AppTheme.lightBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      // 3 days before
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            localReminder3Days =
                                                !localReminder3Days;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                localReminder3Days
                                                    ? Icons.check_box
                                                    : Icons
                                                          .check_box_outline_blank,
                                                color: localReminder3Days
                                                    ? primaryColor
                                                    : (isDark
                                                          ? AppTheme
                                                                .darkTextSecondary
                                                          : AppTheme
                                                                .lightTextSecondary),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '3 ${AppLocalizations.tr(context, 'daysBefore')}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppTheme.darkTextPrimary
                                                      : AppTheme
                                                            .lightTextPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // 1 day before
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            localReminder1Day =
                                                !localReminder1Day;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                localReminder1Day
                                                    ? Icons.check_box
                                                    : Icons
                                                          .check_box_outline_blank,
                                                color: localReminder1Day
                                                    ? primaryColor
                                                    : (isDark
                                                          ? AppTheme
                                                                .darkTextSecondary
                                                          : AppTheme
                                                                .lightTextSecondary),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '1 ${AppLocalizations.tr(context, 'dayBefore')}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppTheme.darkTextPrimary
                                                      : AppTheme
                                                            .lightTextPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // 12 hours before
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            localReminder12Hours =
                                                !localReminder12Hours;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                localReminder12Hours
                                                    ? Icons.check_box
                                                    : Icons
                                                          .check_box_outline_blank,
                                                color: localReminder12Hours
                                                    ? primaryColor
                                                    : (isDark
                                                          ? AppTheme
                                                                .darkTextSecondary
                                                          : AppTheme
                                                                .lightTextSecondary),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '12 ${AppLocalizations.tr(context, 'hoursBefore')}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppTheme.darkTextPrimary
                                                      : AppTheme
                                                            .lightTextPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Custom date/time
                                      GestureDetector(
                                        onTap: () {
                                          setSheetState(() {
                                            localReminderCustom =
                                                !localReminderCustom;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                localReminderCustom
                                                    ? Icons.check_box
                                                    : Icons
                                                          .check_box_outline_blank,
                                                color: localReminderCustom
                                                    ? primaryColor
                                                    : (isDark
                                                          ? AppTheme
                                                                .darkTextSecondary
                                                          : AppTheme
                                                                .lightTextSecondary),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Custom date & time',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppTheme.darkTextPrimary
                                                      : AppTheme
                                                            .lightTextPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Custom date/time pickers (shown when custom is enabled)
                                      if (localReminderCustom) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppTheme.darkCard
                                                : AppTheme.lightCard,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              // Date picker
                                              GestureDetector(
                                                onTap: () async {
                                                  DateTime?
                                                  pickedDate = await showDatePicker(
                                                    context: context,
                                                    initialDate:
                                                        localCustomReminderTime ??
                                                        DateTime.now(),
                                                    firstDate: DateTime.now(),
                                                    lastDate: DateTime.now()
                                                        .add(
                                                          const Duration(
                                                            days: 365,
                                                          ),
                                                        ),
                                                    builder: (context, child) {
                                                      return Theme(
                                                        data: Theme.of(context).copyWith(
                                                          colorScheme: ColorScheme.light(
                                                            primary:
                                                                primaryColor,
                                                            onPrimary:
                                                                Colors.white,
                                                            surface: isDark
                                                                ? AppTheme
                                                                      .darkCard
                                                                : AppTheme
                                                                      .lightCard,
                                                            onSurface: isDark
                                                                ? AppTheme
                                                                      .darkTextPrimary
                                                                : AppTheme
                                                                      .lightTextPrimary,
                                                          ),
                                                          dialogBackgroundColor:
                                                              isDark
                                                              ? AppTheme
                                                                    .darkBackground
                                                              : AppTheme
                                                                    .lightBackground,
                                                        ),
                                                        child: child!,
                                                      );
                                                    },
                                                  );
                                                  if (pickedDate != null) {
                                                    setSheetState(() {
                                                      localCustomReminderTime =
                                                          DateTime(
                                                            pickedDate.year,
                                                            pickedDate.month,
                                                            pickedDate.day,
                                                            localCustomReminderTime
                                                                    ?.hour ??
                                                                9,
                                                            localCustomReminderTime
                                                                    ?.minute ??
                                                                0,
                                                          );
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? AppTheme
                                                              .darkBackground
                                                        : AppTheme
                                                              .lightBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? AppTheme.darkBorder
                                                          : AppTheme
                                                                .lightBorder,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.calendar_today,
                                                        size: 14,
                                                        color: primaryColor,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        localCustomReminderTime !=
                                                                null
                                                            ? '${localCustomReminderTime!.day}.${localCustomReminderTime!.month}.${localCustomReminderTime!.year}'
                                                            : 'Pick date',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? AppTheme
                                                                    .darkTextPrimary
                                                              : AppTheme
                                                                    .lightTextPrimary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Time picker
                                              GestureDetector(
                                                onTap: () async {
                                                  if (localCustomReminderTime ==
                                                      null) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: const Text(
                                                          'Please pick a date first',
                                                        ),
                                                        backgroundColor: isDark
                                                            ? AppTheme
                                                                  .darkWarning
                                                            : AppTheme
                                                                  .lightWarning,
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  TimeOfDay?
                                                  pickedTime = await showTimePicker(
                                                    context: context,
                                                    initialTime: TimeOfDay(
                                                      hour:
                                                          localCustomReminderTime!
                                                              .hour,
                                                      minute:
                                                          localCustomReminderTime!
                                                              .minute,
                                                    ),
                                                  );
                                                  if (pickedTime != null) {
                                                    setSheetState(() {
                                                      localCustomReminderTime = DateTime(
                                                        localCustomReminderTime!
                                                            .year,
                                                        localCustomReminderTime!
                                                            .month,
                                                        localCustomReminderTime!
                                                            .day,
                                                        pickedTime.hour,
                                                        pickedTime.minute,
                                                      );
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? AppTheme
                                                              .darkBackground
                                                        : AppTheme
                                                              .lightBackground,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: isDark
                                                          ? AppTheme.darkBorder
                                                          : AppTheme
                                                                .lightBorder,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: primaryColor,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        localCustomReminderTime !=
                                                                null
                                                            ? '${localCustomReminderTime!.hour.toString().padLeft(2, '0')}:${localCustomReminderTime!.minute.toString().padLeft(2, '0')}'
                                                            : 'Pick time',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? AppTheme
                                                                    .darkTextPrimary
                                                              : AppTheme
                                                                    .lightTextPrimary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _navigateImage(int direction) {
    setState(() {
      _currentIndex = (_currentIndex + direction) % _capturedImages.length;
      _currentImage = _capturedImages[_currentIndex];
    });
  }

  void _deleteCurrentImage() {
    if (_capturedImages.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Image',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this image?',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _capturedImages.removeAt(_currentIndex);
                if (_capturedImages.isNotEmpty) {
                  _currentIndex = _currentIndex.clamp(
                    0,
                    _capturedImages.length - 1,
                  );
                  _currentImage = _capturedImages[_currentIndex];
                } else {
                  _currentImage = null;
                  _showGalleryView = false;
                }
              });
              Navigator.pop(context);
              _showSuccessMessage('Image deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppTheme.darkDanger
                  : AppTheme.lightDanger,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              title: Text(
                'Choose from gallery',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              title: Text(
                'Take new photo',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMultiPageOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.add,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              title: Text(
                'Add page',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickMultipleImages();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              title: Text(
                'Choose multiple',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickMultipleImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullGallery() {
    setState(() {
      _showGalleryView = !_showGalleryView;
    });
  }

  Widget _buildGalleryView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gallery (${_capturedImages.length})',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  onPressed: _showFullGallery,
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _capturedImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                      _currentImage = _capturedImages[index];
                      _showGalleryView = false;
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _currentIndex == index
                                ? primaryColor
                                : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _capturedImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (_capturedImages.length > 1)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _capturedImages.removeAt(index);
                                if (_currentIndex >= _capturedImages.length) {
                                  _currentIndex = _capturedImages.length - 1;
                                }
                                if (_capturedImages.isNotEmpty) {
                                  _currentImage =
                                      _capturedImages[_currentIndex];
                                } else {
                                  _currentImage = null;
                                  _showGalleryView = false;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkDanger
                                    : AppTheme.lightDanger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isProcessing) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Processing...',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            if (!_showGalleryView)
              Stack(
                children: [
                  // Image display area
                  Container(
                    color: isDark
                        ? AppTheme.darkBackground
                        : AppTheme.lightBackground,
                    child: _currentImage != null
                        ? GestureDetector(
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity! > 0) {
                                if (_currentIndex > 0) {
                                  _navigateImage(-1);
                                }
                              } else if (details.primaryVelocity! < 0) {
                                if (_currentIndex <
                                    _capturedImages.length - 1) {
                                  _navigateImage(1);
                                }
                              }
                            },
                            child: Image.file(
                              _currentImage!,
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
                                  Icons.document_scanner,
                                  size: 80,
                                  color:
                                      (isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary)
                                          .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Camera Preview',
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

                  // Edge detection overlay
                  if (_currentImage == null)
                    CustomPaint(
                      painter: EdgeDetectionPainter(primaryColor),
                      child: Container(),
                    ),

                  // Image counter
                  if (_capturedImages.length > 1 && _currentImage != null)
                    Positioned(
                      top: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppTheme.darkSurface
                                        : AppTheme.lightSurface)
                                    .withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${_capturedImages.length}',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Navigation arrows
                  if (_capturedImages.length > 1 && _currentImage != null)
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentIndex > 0)
                            GestureDetector(
                              onTap: () => _navigateImage(-1),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Icon(
                                  Icons.chevron_left,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                  size: 40,
                                ),
                              ),
                            ),
                          if (_currentIndex < _capturedImages.length - 1)
                            GestureDetector(
                              onTap: () => _navigateImage(1),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Icon(
                                  Icons.chevron_right,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                  size: 40,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Top bar
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            if (_capturedImages.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                                onPressed: _deleteCurrentImage,
                              ),
                            if (_capturedImages.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.photo_library,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                                onPressed: _showFullGallery,
                              ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _toggleFlash,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? AppTheme.darkSurface
                                              : AppTheme.lightSurface)
                                          .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isFlashOn
                                          ? Icons.flash_on
                                          : Icons.flash_off,
                                      color: _isFlashOn
                                          ? Colors.yellow
                                          : (isDark
                                                ? AppTheme.darkTextPrimary
                                                : AppTheme.lightTextPrimary),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isFlashOn ? 'On' : 'Auto',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom control panel
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        // AI Analyze Button
                        if (_capturedImages.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GestureDetector(
                              onTap: _analyzeWithAI,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (isDark
                                              ? AppTheme.darkSecondary
                                              : AppTheme.lightSecondary)
                                          .withOpacity(0.7),
                                      isDark
                                          ? AppTheme.darkSecondary
                                          : AppTheme.lightSecondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isDark
                                                  ? AppTheme.darkSecondary
                                                  : AppTheme.lightSecondary)
                                              .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Analyze with AI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Bottom panel
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildControlButton(
                                    context,
                                    Icons.auto_awesome,
                                    'Auto',
                                  ),
                                  _buildControlButton(
                                    context,
                                    Icons.crop,
                                    'Crop',
                                  ),
                                  _buildControlButton(
                                    context,
                                    Icons.color_lens,
                                    'Filter',
                                  ),
                                  _buildControlButton(
                                    context,
                                    Icons.rotate_right,
                                    'Rotate',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.photo_library,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      _showImagePickerOptions(context);
                                    },
                                  ),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryColor,
                                        width: 3,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: primaryColor,
                                        size: 30,
                                      ),
                                      onPressed: _takePhoto,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.description_outlined,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      _showMultiPageOptions(context);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pages: ${_capturedImages.length}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontSize: 14,
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

            // Gallery view overlay
            if (_showGalleryView) _buildGalleryView(),

            // Processing overlay
            _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class EdgeDetectionPainter extends CustomPainter {
  final Color edgeColor;

  EdgeDetectionPainter(this.edgeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = edgeColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.5,
    );

    path.addRect(rect);
    canvas.drawPath(path, paint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 3;

    final corners = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
    ];

    for (var corner in corners) {
      canvas.drawLine(
        corner - const Offset(15, 0),
        corner + const Offset(15, 0),
        cornerPaint,
      );
      canvas.drawLine(
        corner - const Offset(0, 15),
        corner + const Offset(0, 15),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
