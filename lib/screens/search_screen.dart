// lib/screens/search_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
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

  // Use category keys instead of localized strings
  final List<Map<String, dynamic>> _searchResults = [
    {
      'title': 'Mietvertrag Wohnung',
      'categoryKey': 'contracts',
      'date': '15.03.2024',
      'statusKey': 'pending',
      'hasDeadline': true,
      'image': '1.jpeg',
    },
    {
      'title': 'GEZ Befreiung',
      'categoryKey': 'letters',
      'date': '10.03.2024',
      'statusKey': 'done',
      'hasDeadline': true,
      'image': '2.jpeg',
    },
    {
      'title': 'Stromrechnung Januar',
      'categoryKey': 'invoices',
      'date': '05.03.2024',
      'statusKey': 'pending',
      'hasDeadline': true,
      'image': '3.jpeg',
    },
    {
      'title': 'Krankenkassenbescheid',
      'categoryKey': 'important',
      'date': '01.03.2024',
      'statusKey': 'pending',
      'hasDeadline': false,
      'image': '4.jpeg',
    },
  ];

  // Helper method to get localized category
  String _getCategoryLabel(String categoryKey) {
    switch (categoryKey) {
      case 'contracts':
        return AppLocalizations.tr(context, 'contracts');
      case 'invoices':
        return AppLocalizations.tr(context, 'invoices');
      case 'letters':
        return AppLocalizations.tr(context, 'letters');
      case 'important':
        return AppLocalizations.tr(context, 'important');
      default:
        return categoryKey;
    }
  }

  // Helper method to get localized status
  String _getStatusLabel(String statusKey) {
    switch (statusKey) {
      case 'pending':
        return AppLocalizations.tr(context, 'pending');
      case 'done':
        return AppLocalizations.tr(context, 'done');
      default:
        return statusKey;
    }
  }

  // Filter results based on search query
  List<Map<String, dynamic>> get _filteredResults {
    if (_searchQuery.isEmpty) {
      return [];
    }

    final query = _searchQuery.toLowerCase();
    return _searchResults.where((doc) {
      return doc['title'].toLowerCase().contains(query) ||
          _getCategoryLabel(doc['categoryKey']).toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredResults = _filteredResults;

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
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${filteredResults.length} ${AppLocalizations.tr(context, 'results')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Search results or empty state
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildEmptySearch(context)
                : filteredResults.isEmpty
                ? _buildNoResults(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final doc = filteredResults[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DocumentCard(
                          title: doc['title'],
                          category: _getCategoryLabel(doc['categoryKey']),
                          date: doc['date'],
                          deadline: doc['deadline'],
                          status: _getStatusLabel(doc['statusKey']),
                          hasDeadline: doc['hasDeadline'],
                          image: doc['image'],
                          onTap: () {
                            Navigator.pushNamed(context, '/document-detail');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: primaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.tr(context, 'startSearching'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr(context, 'searchDescription'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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
          Icon(
            Icons.search_off,
            size: 80,
            color: primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.tr(context, 'noResults'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '“$_searchQuery”',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tr(context, 'tryDifferentSearch'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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
