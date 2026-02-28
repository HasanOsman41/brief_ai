// lib/screens/search_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:brief_ai/widgets/document_card.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Document> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await DocumentService().searchDocuments(_searchQuery);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  // Helper method to get localized category
  String _getCategoryLabel(String categoryKey) {
    switch (categoryKey) {
      case 'jobcenter':
        return AppLocalizations.tr(context, 'jobcenter');
      case 'auslaenderbehoerde':
        return AppLocalizations.tr(context, 'auslaenderbehoerde');
      case 'krankenkasse':
        return AppLocalizations.tr(context, 'krankenkasse');
      case 'finanzamt':
        return AppLocalizations.tr(context, 'finanzamt');
      case 'contracts':
        return AppLocalizations.tr(context, 'contracts');
      case 'bills':
        return AppLocalizations.tr(context, 'bills');
      case 'bank':
        return AppLocalizations.tr(context, 'bank');
      case 'insurance':
        return AppLocalizations.tr(context, 'insurance');
      case 'rent':
        return AppLocalizations.tr(context, 'rent');
      case 'other':
        return AppLocalizations.tr(context, 'other');
      default:
        return categoryKey;
    }
  }

  // Helper method to get localized status
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr(context, 'search')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _performSearch();
                },
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.tr(context, 'searchHint'),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Search results or empty state
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searchQuery.isEmpty) {
      return _buildEmptySearch(context);
    }

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults(context);
    }

    return _buildResultsList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.tr(context, 'searching'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error searching documents',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _performSearch,
            child: Text(AppLocalizations.tr(context, 'retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '${_searchResults.length} ${AppLocalizations.tr(context, 'results')}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final doc = _searchResults[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DocumentCard(
                  title: doc.title,
                  category: _getCategoryLabel(doc.categoryKey),
                  date: doc.formattedCreatedAt,
                  deadline: doc.formattedDeadline,
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
      ],
    );
  }

  Widget _buildEmptySearch(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search, size: 48, color: primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.tr(context, 'startSearching'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.tr(context, 'searchDescription'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 48, color: primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.tr(context, 'noResults'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '“$_searchQuery”',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              AppLocalizations.tr(context, 'tryDifferentSearch'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
