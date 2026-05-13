import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/models/document_result.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/category_chip.dart';
import 'package:brief_ai/widgets/document_card.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:brief_ai/widgets/sort_dropdown.dart';
import 'package:flutter/material.dart';

class DocumentsTab extends StatefulWidget {
  const DocumentsTab({Key? key}) : super(key: key);

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  String _selectedCategory = 'all';
  List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;

  // Search & filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final documents = await DocumentService().getAllDocuments();
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDocuments() async {
    await _loadDocuments();
  }

  String _getStatusLabel(String statusKey) {
    switch (statusKey) {
      case 'pending':
        return AppLocalizations.tr(context, 'pending');
      case 'inProgress':
        return AppLocalizations.tr(context, 'inProgress');
      case 'done':
        return AppLocalizations.tr(context, 'done');
      case 'archived':
        return AppLocalizations.tr(context, 'archived');
      default:
        return statusKey;
    }
  }

  void _onSortChanged(String sortType) {
    setState(() {
      switch (sortType) {
        case 'latest':
          _documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'deadline':
          _documents.sort((a, b) {
            if (a.deadline == null && b.deadline == null) return 0;
            if (a.deadline == null) return 1;
            if (b.deadline == null) return -1;
            return a.deadline!.compareTo(b.deadline!);
          });
          break;
        case 'category':
          _documents.sort(
            (a, b) => a.mainCategoryKey.compareTo(b.mainCategoryKey),
          );
          break;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
  }

  /// Checks whether a document's created date falls within ±1 day
  /// of the selected date (i.e. same day, day before, or day after).
  bool _matchesDate(Document doc) {
    if (_selectedDate == null) return true;
    final from = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    ).subtract(const Duration(days: 1));
    final to = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    ).add(const Duration(days: 2)); // exclusive upper bound (next day midnight)
    return doc.createdAt.isAfter(from) && doc.createdAt.isBefore(to);
  }

  /// Checks whether the translated title or translated category contains
  /// the current search query.
  bool _matchesSearch(Document doc) {
    if (_searchQuery.isEmpty) return true;
    final translatedTitle = AppLocalizations.tr(
      context,
      doc.title,
    ).toLowerCase();
    // final translatedCategory = AppLocalizations.tr(
    //   context,
    //   doc.mainCategoryKey,
    // ).toLowerCase();
    return translatedTitle.contains(_searchQuery);
    // || translatedCategory.contains(_searchQuery);
  }

  List<Document> get _filteredDocuments {
    return _documents.where((doc) {
      final categoryMatch =
          _selectedCategory == 'all' ||
          doc.mainCategoryKey == _selectedCategory;
      return categoryMatch && _matchesSearch(doc) && _matchesDate(doc);
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedDate != null ||
      _selectedCategory != 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading documents',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshDocuments,
              child: Text(AppLocalizations.tr(context, 'retry')),
            ),
          ],
        ),
      );
    }

    final filteredDocuments = _filteredDocuments;

    return Column(
      children: [
        // ── Search bar ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.tr(context, 'searchHint'),
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Date picker row ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickDate,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: _selectedDate != null
                            ? primaryColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                                  '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                                  '${_selectedDate!.year}'
                            : AppLocalizations.tr(context, 'filterByDate'),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate != null
                              ? primaryColor
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: _selectedDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearDate,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Active filter count badge
              if (_hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, size: 14, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '${filteredDocuments.length} ${AppLocalizations.tr(context, 'results')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Category filter chips ───────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  label: AppLocalizations.tr(context, 'all'),
                  isSelected: _selectedCategory == 'all',
                  onTap: () => setState(() => _selectedCategory = 'all'),
                ),
              ),
              ...MainCategory.values.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: AppLocalizations.tr(context, category.key),
                    icon: category.iconData,
                    isSelected: _selectedCategory == category.key,
                    onTap: () =>
                        setState(() => _selectedCategory = category.key),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Sort row ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.tr(context, 'sortBy')} ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              SortDropdown(onSortChanged: _onSortChanged),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Document list ───────────────────────────────────────────────────
        Expanded(
          child: filteredDocuments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasActiveFilters
                            ? Icons.search_off_outlined
                            : Icons.folder_outlined,
                        size: 64,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _hasActiveFilters
                            ? AppLocalizations.tr(context, 'noResults')
                            : AppLocalizations.tr(context, 'noDocuments'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedCategory = 'all';
                              _selectedDate = null;
                            });
                          },
                          child: Text(
                            AppLocalizations.tr(context, 'clearFilters'),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: filteredDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocuments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DocumentCard(
                          title: doc.title,
                          category: AppLocalizations.tr(
                            context,
                            doc.mainCategoryKey,
                          ),
                          date: doc.createdAt,
                          deadline: doc.deadline,
                          status: _getStatusLabel(doc.statusKey),
                          hasDeadline: doc.hasDeadline,
                          imagePath: doc.mainImagePath,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/document-detail',
                              arguments: {'documentId': doc.id},
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
