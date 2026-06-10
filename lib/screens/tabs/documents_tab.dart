import 'package:brief_ai/cubit/document_cubit/document_cubit.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/models/document_result.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/app_loading.dart';
import 'package:brief_ai/widgets/category_chip.dart';
import 'package:brief_ai/widgets/document_card.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:brief_ai/widgets/professional_snackbar.dart';
import 'package:brief_ai/widgets/sort_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentsTab extends StatefulWidget {
  const DocumentsTab({super.key});

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  String _selectedCategory = 'all';
  List<Document> _filteredDocumentsLocal = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _currentSort = 'latest';

  @override
  void initState() {
    super.initState();
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

  void _onSortChanged(String sortType, List<Document> documents) {
    setState(() {
      _currentSort = sortType;
      _applySorting(documents);
    });
  }

  void _applySorting(List<Document> documents) {
    switch (_currentSort) {
      case 'latest':
        _filteredDocumentsLocal.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'deadline':
        _filteredDocumentsLocal.sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
        break;
      case 'category':
        _filteredDocumentsLocal.sort(
          (a, b) => a.mainCategoryKey.compareTo(b.mainCategoryKey),
        );
        break;
    }
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
    ).add(const Duration(days: 2));
    return doc.createdAt.isAfter(from) && doc.createdAt.isBefore(to);
  }

  bool _matchesSearch(Document doc) {
    if (_searchQuery.isEmpty) return true;
    final translatedTitle = AppLocalizations.tr(context, doc.title).toLowerCase();
    return translatedTitle.contains(_searchQuery);
  }

  void _filterDocuments(List<Document> allDocuments) {
    _filteredDocumentsLocal = allDocuments.where((doc) {
      final categoryMatch = _selectedCategory == 'all' || doc.mainCategoryKey == _selectedCategory;
      return categoryMatch && _matchesSearch(doc) && _matchesDate(doc);
    }).toList();
    _applySorting(allDocuments);
  }

  bool get _hasActiveFilters => _searchQuery.isNotEmpty || _selectedDate != null || _selectedCategory != 'all';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocConsumer<DocumentCubit, DocumentState>(
      listener: (context, state) {
        if (state is DocumentError) {
          ProfessionalSnackbar.error(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is DocumentLoading) {
          return const AppLoading();
        }

        if (state is DocumentError) {
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
                  onPressed: () => context.read<DocumentCubit>().loadDocuments(),
                  child: Text(AppLocalizations.tr(context, 'retry')),
                ),
              ],
            ),
          );
        }

        if (state is DocumentLoaded) {
          _filterDocuments(state.documents);

          return Column(
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickDate,
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
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
                    if (_hasActiveFilters)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                              '${_filteredDocumentsLocal.length} ${AppLocalizations.tr(context, 'results')}',
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
                          onTap: () => setState(() => _selectedCategory = category.key),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${AppLocalizations.tr(context, 'sortBy')} ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    SortDropdown(onSortChanged: (sortType) {
                      _onSortChanged(sortType, state.documents);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredDocumentsLocal.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasActiveFilters ? Icons.search_off_outlined : Icons.folder_outlined,
                              size: 64,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
                        onRefresh: () async {
                          await context.read<DocumentCubit>().refreshFromDatabase();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                          itemCount: _filteredDocumentsLocal.length,
                          itemBuilder: (context, index) {
                            final doc = _filteredDocumentsLocal[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DocumentCard(
                                title: doc.title,
                                category: AppLocalizations.tr(context, doc.mainCategoryKey),
                                date: doc.createdAt,
                                deadline: doc.deadline,
                                status: doc.statusKey,
                                hasDeadline: doc.hasDeadline,
                                imagePath: doc.mainImagePath,
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    '/document-detail',
                                    arguments: {'documentId': doc.id},
                                  );
                                  context.read<DocumentCubit>().refreshFromDatabase();
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

        return const SizedBox.shrink();
      },
    );
  }
}