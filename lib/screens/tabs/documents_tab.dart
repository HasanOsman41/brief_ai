import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/models/document_result.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/category_chip.dart';
import 'package:brief_ai/widgets/common_widgets.dart';
import 'package:brief_ai/widgets/document_card.dart';
import 'package:brief_ai/widgets/glass_card.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDocuments();
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
            Icon(Icons.error_outline, size: 48, color: Colors.red),
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

    // Filter documents by selected category
    final filteredDocuments = _selectedCategory == 'all'
        ? _documents
        : _documents
              .where((doc) => doc.mainCategoryKey == _selectedCategory)
              .toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/search');
            },
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Container(
                height: 56,
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.tr(context, 'searchHint'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // "All" category chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  label: AppLocalizations.tr(context, 'all'),
                  isSelected: _selectedCategory == 'all',
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'all';
                    });
                  },
                ),
              ),
              // Categories from MainCategory enum
              ...MainCategory.values.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: AppLocalizations.tr(context, category.key),
                    icon: category.iconData,
                    isSelected: _selectedCategory == category.key,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category.key;
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Sort options
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

        const SizedBox(height: 16),

        // Document list
        Expanded(
          child: filteredDocuments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedCategory == 'all'
                            ? AppLocalizations.tr(context, 'noDocuments')
                            : 'No documents in this category',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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