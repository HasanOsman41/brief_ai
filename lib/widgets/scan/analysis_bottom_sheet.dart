// lib/widgets/scan/analysis_bottom_sheet.dart
import 'package:brief_ai/data/categories_data.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/analysis_result.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:brief_ai/services/notification_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shows the AI analysis result as a draggable bottom sheet.
/// Handles: category selection, deadline picker, reminder scheduling.
///
/// Call [show] as a static helper to open the sheet imperatively.
class AnalysisBottomSheet extends StatefulWidget {
  const AnalysisBottomSheet({
    super.key,
    required this.result,
    required this.initialDeadline,
    required this.imagePaths,
    required this.ocrText,
    required this.onSave,
    this.documentId,
  });

  final AnalysisResult result;
  final DateTime initialDeadline;
  final List<String> imagePaths;
  final String ocrText;
  final ValueChanged<DateTime> onSave;
  final int? documentId;

  static void show(
    BuildContext context, {
    required AnalysisResult result,
    required DateTime initialDeadline,
    required List<String> imagePaths,
    required String ocrText,
    required ValueChanged<DateTime> onSave,
    int? documentId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AnalysisBottomSheet(
        result: result,
        initialDeadline: initialDeadline,
        imagePaths: imagePaths,
        ocrText: ocrText,
        onSave: onSave,
        documentId: documentId,
      ),
    );
  }

  @override
  State<AnalysisBottomSheet> createState() => _AnalysisBottomSheetState();
}

class _AnalysisBottomSheetState extends State<AnalysisBottomSheet> {
  late DateTime _deadline;

  // Stores the localization KEY (e.g. 'categoryBills'), not the translated label.
  // This stays stable regardless of the active language.
  late String _selectedCategoryKey;
  late String _editableTitle;
  late String _editableSummary;

  bool _remindersEnabled = true;
  bool _remind3Days = true;
  bool _remind1Day = true;
  bool _remind12Hours = false;
  bool _remindCustom = false;
  DateTime? _customTime;

  @override
  void initState() {
    super.initState();
    _deadline = widget.initialDeadline;
    _editableTitle = widget.result.title;
    _editableSummary = widget.result.summary;

    // Try to match the AI-detected category to a known key.
    // The AI may return a translated label or the raw key — we handle both.
    final matched = categoryByKey(widget.result.category);
    _selectedCategoryKey = matched?.key ?? kDocumentCategories.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _Handle(isDark: isDark),
            _SheetHeader(
              primary: primary,
              isDark: isDark,
              onSave: _handleSave,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  children: [
                    _DocumentInfoCard(
                      result: widget.result,
                      isDark: isDark,
                      primary: primary,
                      selectedCategoryKey: _selectedCategoryKey,
                      onCategoryChanged: (key) =>
                          setState(() => _selectedCategoryKey = key),
                      editableTitle: _editableTitle,
                      onTitleChanged: (title) =>
                          setState(() => _editableTitle = title),
                      editableSummary: _editableSummary,
                      onSummaryChanged: (summary) =>
                          setState(() => _editableSummary = summary),
                    ),
                    const SizedBox(height: 16),
                    _DeadlineReminderCard(
                      isDark: isDark,
                      primary: primary,
                      deadline: _deadline,
                      remindersEnabled: _remindersEnabled,
                      remind3Days: _remind3Days,
                      remind1Day: _remind1Day,
                      remind12Hours: _remind12Hours,
                      remindCustom: _remindCustom,
                      customTime: _customTime,
                      onDeadlineChanged: (d) => setState(() => _deadline = d),
                      onRemindersToggled: (v) =>
                          setState(() => _remindersEnabled = v),
                      onToggle3Days: () =>
                          setState(() => _remind3Days = !_remind3Days),
                      onToggle1Day: () =>
                          setState(() => _remind1Day = !_remind1Day),
                      onToggle12Hours: () =>
                          setState(() => _remind12Hours = !_remind12Hours),
                      onToggleCustom: () =>
                          setState(() => _remindCustom = !_remindCustom),
                      onCustomTimeChanged: (d) =>
                          setState(() => _customTime = d),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    try {
      final base = DateTime(_deadline.year, _deadline.month, _deadline.day, 9);
      
      if (widget.documentId != null) {
        // Update existing document
        await DocumentService().updateDocument(
          widget.documentId!,
          title: _editableTitle,
          categoryKey: _selectedCategoryKey,
          deadline: _deadline,
          statusKey: 'pending',
          summary: _editableSummary,
          ocrText: widget.ocrText,
          reminder3DaysTime: _remindersEnabled && _remind3Days ? base.subtract(const Duration(days: 3)) : null,
          reminder1DayTime: _remindersEnabled && _remind1Day ? base.subtract(const Duration(days: 1)) : null,
          reminder12HoursTime: _remindersEnabled && _remind12Hours ? base.subtract(const Duration(hours: 12)) : null,
          reminderCustomTime: _remindersEnabled && _remindCustom ? _customTime : null,
        );
        
        // Update images: delete old ones and add new ones
        await DocumentService().deleteAllImages(widget.documentId!);
        if (widget.imagePaths.isNotEmpty) {
          await DocumentService().addImagesToDocument(widget.documentId!, widget.imagePaths);
        }
      } else {
        // Add new document
        await DocumentService().addDocument(
          title: _editableTitle,
          categoryKey: _selectedCategoryKey,
          deadline: _deadline,
          statusKey: 'pending',
          summary: _editableSummary,
          ocrText: widget.ocrText,
          imagePaths: widget.imagePaths,
          reminder3DaysTime: _remindersEnabled && _remind3Days ? base.subtract(const Duration(days: 3)) : null,
          reminder1DayTime: _remindersEnabled && _remind1Day ? base.subtract(const Duration(days: 1)) : null,
          reminder12HoursTime: _remindersEnabled && _remind12Hours ? base.subtract(const Duration(hours: 12)) : null,
          reminderCustomTime: _remindersEnabled && _remindCustom ? _customTime : null,
        );
      }

      widget.onSave(_deadline);
      if (_remindersEnabled) _scheduleReminders();
      Navigator.pop(context);
      _snack(AppLocalizations.tr(context, 'analysisSaved'), success: true);
    } catch (e) {
      _snack('Error: $e', success: false);
    }
  }

  void _scheduleReminders() {
    final raw = _editableTitle.isNotEmpty
        ? _editableTitle
        : _editableSummary.split('.').first;
    final title = raw.length > 50 ? raw.substring(0, 50) : raw;
    final body =
        '${AppLocalizations.tr(context, 'deadline')}: '
        '${_deadline.day}.${_deadline.month}.${_deadline.year}';
    final base = DateTime(_deadline.year, _deadline.month, _deadline.day, 9);

    void sched(int offset, DateTime dt) =>
        NotificationService().scheduleNotification(
          title.hashCode.abs() + offset,
          title,
          body,
          dt,
          payload:
              '${dt.day}.${dt.month}.${dt.year} '
              '${dt.hour.toString().padLeft(2, '0')}:'
              '${dt.minute.toString().padLeft(2, '0')}',
        );

    if (_remind3Days) sched(0, base.subtract(const Duration(days: 3)));
    if (_remind1Day) sched(1, base.subtract(const Duration(days: 1)));
    if (_remind12Hours) sched(2, base.subtract(const Duration(hours: 12)));
    if (_remindCustom && _customTime != null) sched(3, _customTime!);
  }

  void _snack(String msg, {required bool success, SnackBarAction? action}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success
            ? (isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess)
            : (isDark ? AppTheme.darkDanger : AppTheme.lightDanger),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: action,
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  const _Handle({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.primary,
    required this.isDark,
    required this.onSave,
    required this.onClose,
  });
  final Color primary;
  final bool isDark;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
    child: Row(
      children: [
        Icon(Icons.auto_awesome, color: primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.tr(context, 'aiAnalysisResults'),
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _SaveButton(primary: primary, onTap: onSave),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            Icons.close,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            size: 20,
          ),
          onPressed: onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    ),
  );
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.primary, required this.onTap});
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.save, color: Colors.white, size: 14),
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
  );
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

// ── Document Info Card ────────────────────────────────────────────────────────

class _DocumentInfoCard extends StatefulWidget {
  const _DocumentInfoCard({
    required this.result,
    required this.isDark,
    required this.primary,
    required this.selectedCategoryKey,
    required this.onCategoryChanged,
    required this.editableTitle,
    required this.onTitleChanged,
    required this.editableSummary,
    required this.onSummaryChanged,
  });

  final AnalysisResult result;
  final bool isDark;
  final Color primary;
  final String selectedCategoryKey;
  final ValueChanged<String> onCategoryChanged;
  final String editableTitle;
  final ValueChanged<String> onTitleChanged;
  final String editableSummary;
  final ValueChanged<String> onSummaryChanged;

  @override
  State<_DocumentInfoCard> createState() => _DocumentInfoCardState();
}

class _DocumentInfoCardState extends State<_DocumentInfoCard> {
  late TextEditingController _titleController;
  late TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editableTitle);
    _summaryController = TextEditingController(text: widget.editableSummary);
  }

  @override
  void didUpdateWidget(_DocumentInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editableTitle != widget.editableTitle) {
      _titleController.text = widget.editableTitle;
    }
    if (oldWidget.editableSummary != widget.editableSummary) {
      _summaryController.text = widget.editableSummary;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetCard(
    isDark: widget.isDark,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Editable category selector
        _CategorySelector(
          isDark: widget.isDark,
          primary: widget.primary,
          selectedKey: widget.selectedCategoryKey,
          onChanged: widget.onCategoryChanged,
        ),
        if (widget.editableTitle.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            AppLocalizations.tr(context, 'title'),
            style: TextStyle(
              color: widget.isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            onChanged: widget.onTitleChanged,
            style: TextStyle(
              color: widget.isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? AppTheme.darkBorder
                      : AppTheme.lightBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          AppLocalizations.tr(context, 'summary'),
          style: TextStyle(
            color: widget.isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _summaryController,
          onChanged: widget.onSummaryChanged,
          maxLines: null,
          style: TextStyle(
            color: widget.isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            fontSize: 14,
            height: 1.5,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.isDark
                    ? AppTheme.darkBorder
                    : AppTheme.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Category Selector ─────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.isDark,
    required this.primary,
    required this.selectedKey,
    required this.onChanged,
  });

  final bool isDark;
  final Color primary;

  /// The localization key of the currently selected category.
  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Text(
              AppLocalizations.tr(context, 'category'),
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Drop-down
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedKey,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              icon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.expand_more, color: primary, size: 20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),

              // Each item: translate the key at render time
              items: kDocumentCategories.map((cat) {
                final label = AppLocalizations.tr(context, cat.key);
                final isSelected = cat.key == selectedKey;
                return DropdownMenuItem<String>(
                  value: cat.key,
                  child: Row(
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? primary : textColor,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Selected item shown in the closed box
              selectedItemBuilder: (ctx) => kDocumentCategories.map((cat) {
                final label = AppLocalizations.tr(ctx, cat.key);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              onChanged: (key) {
                if (key != null) onChanged(key);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Deadline & Reminder Card ──────────────────────────────────────────────────

class _DeadlineReminderCard extends StatelessWidget {
  const _DeadlineReminderCard({
    required this.isDark,
    required this.primary,
    required this.deadline,
    required this.remindersEnabled,
    required this.remind3Days,
    required this.remind1Day,
    required this.remind12Hours,
    required this.remindCustom,
    required this.customTime,
    required this.onDeadlineChanged,
    required this.onRemindersToggled,
    required this.onToggle3Days,
    required this.onToggle1Day,
    required this.onToggle12Hours,
    required this.onToggleCustom,
    required this.onCustomTimeChanged,
  });

  final bool isDark;
  final Color primary;
  final DateTime deadline;
  final bool remindersEnabled,
      remind3Days,
      remind1Day,
      remind12Hours,
      remindCustom;
  final DateTime? customTime;
  final ValueChanged<DateTime> onDeadlineChanged;
  final ValueChanged<bool> onRemindersToggled;
  final VoidCallback onToggle3Days,
      onToggle1Day,
      onToggle12Hours,
      onToggleCustom;
  final ValueChanged<DateTime?> onCustomTimeChanged;

  @override
  Widget build(BuildContext context) => _SheetCard(
    isDark: isDark,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deadline label
        Text(
          AppLocalizations.tr(context, 'deadline'),
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        _DatePickerChip(
          isDark: isDark,
          primary: primary,
          date: deadline,
          onChanged: onDeadlineChanged,
        ),
        const SizedBox(height: 16),

        // Reminder toggle
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.tr(context, 'reminder'),
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Switch(
              value: remindersEnabled,
              onChanged: onRemindersToggled,
              activeColor: primary,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (remindersEnabled) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBackground
                  : AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _CheckRow(
                  label: '3 ${AppLocalizations.tr(context, 'daysBefore')}',
                  value: remind3Days,
                  onTap: onToggle3Days,
                  primary: primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _CheckRow(
                  label: '1 ${AppLocalizations.tr(context, 'dayBefore')}',
                  value: remind1Day,
                  onTap: onToggle1Day,
                  primary: primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _CheckRow(
                  label: '12 ${AppLocalizations.tr(context, 'hoursBefore')}',
                  value: remind12Hours,
                  onTap: onToggle12Hours,
                  primary: primary,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _CheckRow(
                  label: AppLocalizations.tr(context, 'customDateTime'),
                  value: remindCustom,
                  onTap: onToggleCustom,
                  primary: primary,
                  isDark: isDark,
                ),
                if (remindCustom) ...[
                  const SizedBox(height: 12),
                  _CustomDateTimePicker(
                    isDark: isDark,
                    primary: primary,
                    value: customTime,
                    onChanged: onCustomTimeChanged,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

// ── Micro widgets ─────────────────────────────────────────────────────────────

class _DatePickerChip extends StatelessWidget {
  const _DatePickerChip({
    required this.isDark,
    required this.primary,
    required this.date,
    required this.onChanged,
  });
  final bool isDark;
  final Color primary;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              surface: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              onSurface: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
            dialogBackgroundColor: isDark
                ? AppTheme.darkBackground
                : AppTheme.lightBackground,
          ),
          child: child!,
        ),
      );
      if (picked != null) onChanged(picked);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${date.day}.${date.month}.${date.year}',
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.edit_calendar, color: primary, size: 16),
        ],
      ),
    ),
  );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onTap,
    required this.primary,
    required this.isDark,
  });
  final String label;
  final bool value;
  final VoidCallback onTap;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            color: value
                ? primary
                : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CustomDateTimePicker extends StatelessWidget {
  const _CustomDateTimePicker({
    required this.isDark,
    required this.primary,
    required this.value,
    required this.onChanged,
  });
  final bool isDark;
  final Color primary;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        GestureDetector(
          onTap: () async {
            final p = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (p != null) {
              onChanged(
                DateTime(
                  p.year,
                  p.month,
                  p.day,
                  value?.hour ?? 9,
                  value?.minute ?? 0,
                ),
              );
            }
          },
          child: _dtChip(
            context,
            isDark,
            primary,
            Icons.calendar_today,
            value != null
                ? '${value!.day}.${value!.month}.${value!.year}'
                : AppLocalizations.tr(context, 'pickDate'),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            if (value == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.tr(context, 'pleasePickDateFirst'),
                  ),
                  backgroundColor: isDark
                      ? AppTheme.darkWarning
                      : AppTheme.lightWarning,
                ),
              );
              return;
            }
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: value!.hour, minute: value!.minute),
            );
            if (t != null) {
              onChanged(
                DateTime(
                  value!.year,
                  value!.month,
                  value!.day,
                  t.hour,
                  t.minute,
                ),
              );
            }
          },
          child: _dtChip(
            context,
            isDark,
            primary,
            Icons.access_time,
            value != null
                ? '${value!.hour.toString().padLeft(2, '0')}:'
                      '${value!.minute.toString().padLeft(2, '0')}'
                : AppLocalizations.tr(context, 'pickTime'),
          ),
        ),
      ],
    ),
  );

  Widget _dtChip(
    BuildContext context,
    bool isDark,
    Color primary,
    IconData icon,
    String label,
  ) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      ),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
