// lib/widgets/scan/analysis_bottom_sheet.dart
import 'package:brief_ai/data/brief_ai_categories.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/category_definition.dart';
import 'package:brief_ai/models/document_result.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/utils/raw_content.dart';
import 'package:brief_ai/widgets/what_you_should_card.dart';
import 'package:flutter/material.dart';

const String _kOtherCategoryId = 'other';

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

  final DocumentResult result;
  final DateTime? initialDeadline;
  final List<String> imagePaths;
  final String ocrText;
  final ValueChanged<DateTime?> onSave;
  final int? documentId;

  static void show(
    BuildContext context, {
    required DocumentResult result,
    required DateTime? initialDeadline,
    required List<String> imagePaths,
    required String ocrText,
    required ValueChanged<DateTime?> onSave,
    int? documentId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.background,
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
  DateTime? _deadline;

  // subCategoryKey = CategoryDefinition.id (e.g. 'jobcenter_termin')
  late String _subCategoryKey;
  // mainCategoryKey = MainCategory.key (e.g. 'categoryJobcenter')
  late String _mainCategoryKey;
  late String _titleKey;
  late String _editableTitle;

  // Free-form fields used when the user picks the "Other" category. When the
  // category is anything else these values are ignored and the read-only
  // translated summary / category step keys are shown instead.
  String _editableSummary = '';
  String _editableSteps = '';

  bool get _isOtherCategory => _subCategoryKey == _kOtherCategoryId;

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

    // The document title is stored as a localization key (labelKey).
    // We'll translate it for display once we have a valid BuildContext.
    _titleKey = widget.result.title;
    // If category is null the title key is 'categoryOther' — treat as empty
    // so the user sees a blank editable field rather than a translated fallback.
    _editableTitle = widget.result.category == null ? '' : '';

    // Resolve the detected sub-category from the result.
    // If category is null (undetected), leave keys empty — UI shows a banner.
    final detectedId = widget.result.category?.id;
    if (detectedId != null) {
      final matched = BriefAiCategories.all.firstWhere(
        (c) => c.id == detectedId,
        orElse: () => BriefAiCategories.all.first,
      );
      _subCategoryKey = matched.id;
      _mainCategoryKey = matched.mainCategory.key;
    } else {
      _subCategoryKey = '';
      _mainCategoryKey = '';
    }

    // When re-opening a document whose summary was saved as free-form text,
    // pre-fill the editable summary and step fields so the user can keep
    // editing instead of starting over.
    final raw = RawContent.tryDecode(widget.result.summaryKey);
    if (raw != null) {
      _editableSummary = raw.summary;
      _editableSteps = raw.steps.join('\n');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_editableTitle.isEmpty && widget.result.category != null) {
      final translated = AppLocalizations.tr(context, _titleKey);
      setState(() => _editableTitle = translated);
    }
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
                      selectedCategoryId: _subCategoryKey,
                      selectedCategoryKey: _mainCategoryKey,
                      categoryDetected: widget.result.category != null,
                      isOtherCategory: _isOtherCategory,
                      onCategoryChanged: (subKey, mainKey) => setState(() {
                        _subCategoryKey = subKey;
                        _mainCategoryKey = mainKey;
                      }),
                      editableTitle: _editableTitle,
                      onTitleChanged: (title) =>
                          setState(() => _editableTitle = title),
                      editableSummary: _editableSummary,
                      onSummaryChanged: (s) =>
                          setState(() => _editableSummary = s),
                      editableSteps: _editableSteps,
                      onStepsChanged: (s) =>
                          setState(() => _editableSteps = s),
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
      final base = _deadline != null
          ? DateTime(_deadline!.year, _deadline!.month, _deadline!.day, 9)
          : null;

      final reminder3Days = base != null && _remindersEnabled && _remind3Days
          ? base.subtract(const Duration(days: 3))
          : null;
      final reminder1Day = base != null && _remindersEnabled && _remind1Day
          ? base.subtract(const Duration(days: 1))
          : null;
      final reminder12Hours =
          base != null && _remindersEnabled && _remind12Hours
          ? base.subtract(const Duration(hours: 12))
          : null;
      final reminderCustom = _remindersEnabled && _remindCustom
          ? _customTime
          : null;

      // Block save if category was not detected and user hasn't picked one.
      if (_subCategoryKey.isEmpty) {
        _snack(
          AppLocalizations.tr(context, 'noCategoryDetected'),
          success: false,
        );
        return;
      }

      // If the user didn't change the title, store the key (language independent).
      final translatedDefault = AppLocalizations.tr(context, _titleKey);
      final titleToStore = _editableTitle.isEmpty
          ? _subCategoryKey
          : (_editableTitle == translatedDefault ? _titleKey : _editableTitle);

      // When the user picked "Other", encode their free-form summary + steps
      // into the existing summaryKey column so we don't need a schema change.
      // Otherwise pass the translation key from the analysis result.
      final String summaryToStore;
      if (_isOtherCategory) {
        final steps = _editableSteps
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false);
        summaryToStore = RawContent(
          summary: _editableSummary.trim(),
          steps: steps,
        ).encode();
      } else {
        summaryToStore = widget.result.summaryKey;
      }

      if (widget.documentId != null) {
        await DocumentService().updateDocumentWithImagesAndReminders(
          widget.documentId!,
          title: titleToStore,
          subCategoryKey: _subCategoryKey,
          mainCategoryKey: _mainCategoryKey,
          deadline: _deadline,
          statusKey: 'pending',
          summaryKey: summaryToStore,
          ocrText: widget.ocrText,
          imagePaths: widget.imagePaths,
          reminder3DaysTime: reminder3Days,
          reminder1DayTime: reminder1Day,
          reminder12HoursTime: reminder12Hours,
          reminderCustomTime: reminderCustom,
        );
      } else {
        await DocumentService().createDocumentWithImagesAndReminders(
          title: titleToStore,
          subCategoryKey: _subCategoryKey,
          mainCategoryKey: _mainCategoryKey,
          deadline: _deadline,
          statusKey: 'pending',
          summaryKey: summaryToStore,
          ocrText: widget.ocrText,
          imagePaths: widget.imagePaths,
          reminder3DaysTime: reminder3Days,
          reminder1DayTime: reminder1Day,
          reminder12HoursTime: reminder12Hours,
          reminderCustomTime: reminderCustom,
        );
      }

      widget.onSave(_deadline);
      Navigator.pop(context);
      _snack(AppLocalizations.tr(context, 'analysisSaved'), success: true);
    } catch (e) {
      _snack('Error: $e', success: false);
    }
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
          Icon(Icons.save, color: Theme.of(context).colorScheme.onPrimary, size: 14),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.tr(context, 'save'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
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
    required this.selectedCategoryId,
    required this.selectedCategoryKey,
    required this.categoryDetected,
    required this.isOtherCategory,
    required this.onCategoryChanged,
    required this.editableTitle,
    required this.onTitleChanged,
    required this.editableSummary,
    required this.onSummaryChanged,
    required this.editableSteps,
    required this.onStepsChanged,
  });

  final DocumentResult result;
  final bool isDark;
  final Color primary;
  final String selectedCategoryId;
  final String selectedCategoryKey;
  final bool categoryDetected;
  final bool isOtherCategory;
  final void Function(String subCategoryKey, String mainCategoryKey)
  onCategoryChanged;
  final String editableTitle;
  final ValueChanged<String> onTitleChanged;
  final String editableSummary;
  final ValueChanged<String> onSummaryChanged;
  final String editableSteps;
  final ValueChanged<String> onStepsChanged;

  @override
  State<_DocumentInfoCard> createState() => _DocumentInfoCardState();
}

class _DocumentInfoCardState extends State<_DocumentInfoCard> {
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _stepsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editableTitle);
    _summaryController = TextEditingController(text: widget.editableSummary);
    _stepsController = TextEditingController(text: widget.editableSteps);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void didUpdateWidget(_DocumentInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync external value back into the controller when it actually
    // diverges from what the user has typed. Blindly assigning .text on every
    // parent rebuild resets the caret to position 0 mid-edit.
    _syncController(_titleController, widget.editableTitle);
    _syncController(_summaryController, widget.editableSummary);
    _syncController(_stepsController, widget.editableSteps);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  InputDecoration _otherFieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: (widget.isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary)
            .withOpacity(0.6),
        fontSize: 13,
      ),
      isDense: false,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
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
    );
  }

  @override
  Widget build(BuildContext context) => _SheetCard(
    isDark: widget.isDark,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Undetected category banner
        if (!widget.categoryDetected) _NoCategoryBanner(isDark: widget.isDark),
        if (!widget.categoryDetected) const SizedBox(height: 12),
        // Editable category selector
        _CategorySelector(
          isDark: widget.isDark,
          primary: widget.primary,
          selectedCategoryId: widget.selectedCategoryId,
          selectedCategoryKey: widget.selectedCategoryKey,
          categoryDetected: widget.categoryDetected,
          onChanged: widget.onCategoryChanged,
        ),
        const SizedBox(height: 12),
        _TrustScoreSlider(
          isDark: widget.isDark,
          primary: widget.primary,
          score: widget.result.trustScore,
          categoryDetected: widget.categoryDetected,
        ),
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
          autofocus: !widget.categoryDetected,
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
        if (widget.isOtherCategory) ...[
          const SizedBox(height: 16),
          _FieldLabel(
            label: AppLocalizations.tr(context, 'aiSummary'),
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _summaryController,
            onChanged: widget.onSummaryChanged,
            maxLines: null,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: TextStyle(
              color: widget.isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: _otherFieldDecoration(),
          ),
          const SizedBox(height: 16),
          _FieldLabel(
            label: AppLocalizations.tr(context, 'whatYouShould'),
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _stepsController,
            onChanged: widget.onStepsChanged,
            maxLines: null,
            minLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: TextStyle(
              color: widget.isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: _otherFieldDecoration(
              hint: AppLocalizations.tr(context, 'stepsHint'),
            ),
          ),
        ] else if (widget.categoryDetected) ...[
          const SizedBox(height: 16),
          _FieldLabel(
            label: AppLocalizations.tr(context, 'aiSummary'),
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isDark
                    ? AppTheme.darkBorder
                    : AppTheme.lightBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              AppLocalizations.tr(context, widget.result.summaryKey),
              style: TextStyle(
                color: widget.isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel(
            label: AppLocalizations.tr(context, 'whatYouShould'),
            isDark: widget.isDark,
          ),
          const SizedBox(height: 6),
          WhatYouShouldCard(
            nextStepTitleKeys: BriefAiCategories.getStepsById(
              widget.selectedCategoryId,
            ),
            isDark: widget.isDark,
            primary: widget.primary,
            enablePulseAnimation: true,
          ),
        ],
      ],
    ),
  );
}

// ── Small Helper ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Category Selector ─────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.isDark,
    required this.primary,
    required this.selectedCategoryId,
    required this.selectedCategoryKey,
    required this.categoryDetected,
    required this.onChanged,
  });

  final bool isDark;
  final Color primary;
  final String selectedCategoryId;
  final String selectedCategoryKey;
  final bool categoryDetected;
  final void Function(String subCategoryKey, String mainCategoryKey) onChanged;

  @override
  Widget build(BuildContext context) {
    final warningColor = isDark ? AppTheme.darkWarning : AppTheme.lightWarning;

    // If no category was detected, show a tap-to-select placeholder
    if (!categoryDetected && selectedCategoryId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: warningColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: warningColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.tr(context, 'noCategoryDetected'),
                      style: TextStyle(
                        color: warningColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more, color: warningColor, size: 20),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final cat = BriefAiCategories.all.firstWhere(
      (c) => c.id == selectedCategoryId,
      orElse: () => BriefAiCategories.all.first,
    );
    final mainLabel = AppLocalizations.tr(context, cat.mainCategory.key);
    final subLabel = AppLocalizations.tr(context, cat.labelKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBackground
                  : AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(cat.mainCategory.iconData, size: 18, color: primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mainLabel,
                        style: TextStyle(
                          color: primary.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subLabel,
                        style: TextStyle(
                          color: primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.expand_more, color: primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      builder: (_) => _CategoryPickerSheet(
        isDark: isDark,
        primary: primary,
        currentCategoryId: selectedCategoryId,
        onSelected: (cat) {
          Navigator.pop(context);
          onChanged(cat.id, cat.mainCategory.key);
        },
      ),
    );
  }
}

// ── Category Picker Sheet ─────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.isDark,
    required this.primary,
    required this.currentCategoryId,
    required this.onSelected,
  });

  final bool isDark;
  final Color primary;
  final String currentCategoryId;
  final void Function(CategoryDefinition) onSelected;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  MainCategory? _selectedMain;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.currentCategoryId.isNotEmpty) {
      final current = BriefAiCategories.all.firstWhere(
        (c) => c.id == widget.currentCategoryId,
        orElse: () => BriefAiCategories.all.first,
      );
      _selectedMain = current.mainCategory;
    }
    // else: _selectedMain stays null — shows all categories
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CategoryDefinition> get _filtered {
    final pool = _selectedMain == null
        ? BriefAiCategories.all
        : BriefAiCategories.all
              .where((c) => c.mainCategory == _selectedMain)
              .toList();
    if (_query.isEmpty) return pool;
    return pool.where((c) {
      final label = AppLocalizations.tr(context, c.labelKey).toLowerCase();
      return label.contains(_query) || c.id.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? AppTheme.darkBackground
        : AppTheme.lightBackground;
    final cardColor = widget.isDark ? AppTheme.darkCard : AppTheme.lightCard;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.24)
                    : Theme.of(context).colorScheme.onBackground.withOpacity(0.26),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 20,
                end: 8,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.tr(context, 'changeCategory'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: AppLocalizations.tr(context, 'cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: AppLocalizations.tr(context, 'search'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Main category filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: AppLocalizations.tr(context, 'all'),
                    selected: _selectedMain == null,
                    primary: widget.primary,
                    onTap: () => setState(() => _selectedMain = null),
                  ),
                  ...MainCategory.values.map(
                    (m) => _FilterChip(
                      label: AppLocalizations.tr(context, m.key),
                      selected: _selectedMain == m,
                      primary: widget.primary,
                      onTap: () => setState(() => _selectedMain = m),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Sub-category list
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: widget.isDark
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.24)
                                : Theme.of(context).colorScheme.onBackground.withOpacity(0.26),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.tr(context, 'noCategoryDetected'),
                            style: TextStyle(
                              color: widget.isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.38)
                                  : Theme.of(context).colorScheme.onBackground.withOpacity(0.38),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final cat = _filtered[i];
                        final isCurrent = cat.id == widget.currentCategoryId;
                        final mainLabel = AppLocalizations.tr(
                          context,
                          cat.mainCategory.key,
                        );
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: isCurrent
                              ? widget.primary.withOpacity(0.1)
                              : null,
                          leading: Icon(
                            cat.mainCategory.iconData,
                            color: isCurrent
                                ? widget.primary
                                : (widget.isDark
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.54)
                                      : Theme.of(context).colorScheme.onBackground.withOpacity(0.45)),
                            size: 22,
                          ),
                          title: Text(
                            AppLocalizations.tr(context, cat.labelKey),
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isCurrent ? widget.primary : null,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            mainLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isDark
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.38)
                                  : Theme.of(context).colorScheme.onBackground.withOpacity(0.38),
                            ),
                          ),
                          trailing: isCurrent
                              ? Icon(
                                  Icons.check_circle,
                                  color: widget.primary,
                                  size: 18,
                                )
                              : null,
                          onTap: () => widget.onSelected(cat),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? primary : primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Theme.of(context).colorScheme.onPrimary : primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
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
  final DateTime? deadline;
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
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Theme.of(ctx).colorScheme.onPrimary,
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
      picked = picked?.add(
        const Duration(hours: 23, minutes: 59),
      ); // Set to end of day
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
            date != null
                ? '${date!.day}.${date!.month}.${date!.year}'
                : AppLocalizations.tr(context, 'noDateSelected'),
            style: TextStyle(
              color: date != null
                  ? (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary)
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
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

// ── No-Category Banner ─────────────────────────────────────────────────────────────────

class _NoCategoryBanner extends StatelessWidget {
  const _NoCategoryBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.tr(context, 'noCategoryDetectedHint'),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trust Score Slider ────────────────────────────────────────────────────────

class _TrustScoreSlider extends StatelessWidget {
  const _TrustScoreSlider({
    required this.isDark,
    required this.primary,
    required this.score,
    required this.categoryDetected,
  });

  final bool isDark;
  final Color primary;
  final int score;
  final bool categoryDetected;

  Color _getColor(BuildContext context) {
    if (!categoryDetected)
      return isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    if (score >= 70)
      return isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
    if (score >= 40)
      return isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
    return isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
  }

  String _label(BuildContext context) {
    if (!categoryDetected)
      return AppLocalizations.tr(context, 'noCategoryDetected');
    if (score >= 70) return AppLocalizations.tr(context, 'high');
    if (score >= 40) return AppLocalizations.tr(context, 'medium');
    return AppLocalizations.tr(context, 'low');
  }

  IconData get _icon {
    if (!categoryDetected) return Icons.help_outline_rounded;
    if (score >= 70) return Icons.verified_rounded;
    if (score >= 40) return Icons.info_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    final filled = categoryDetected ? (score / 10).round().clamp(0, 10) : 0;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final displayScore = categoryDetected ? '$score%' : '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.tr(context, 'trustScore'),
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_label(context)} · $displayScore',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(10, (i) {
                    final active = i < filled;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 3),
                        height: 5,
                        decoration: BoxDecoration(
                          color: active ? color : bg,
                          borderRadius: BorderRadius.circular(3),
                          border: active
                              ? null
                              : Border.all(
                                  color: color.withOpacity(0.2),
                                  width: 1,
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
