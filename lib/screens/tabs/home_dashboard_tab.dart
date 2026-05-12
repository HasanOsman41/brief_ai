import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/document_card.dart';
import 'package:brief_ai/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class HomeDashboardTab extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeDashboardTab({Key? key, required this.onTabChange})
    : super(key: key);

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
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
              'Error loading dashboard',
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

    // Calculate statistics
    int totalDocuments = _documents.length;
    int pendingDocuments = _documents
        .where(
          (doc) => doc.statusKey == 'pending' || doc.statusKey == 'inProgress',
        )
        .length;
    int closedDocuments = _documents
        .where((doc) => doc.statusKey == 'done')
        .length;

    // Get recently added documents (last 3)
    var recentDocuments = _documents.take(3).toList();

    return RefreshIndicator(
      onRefresh: _refreshDocuments,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.description,
                    value: totalDocuments.toString(),
                    label: AppLocalizations.tr(context, 'totalDocuments'),
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.pending_actions,
                    value: pendingDocuments.toString(),
                    label: AppLocalizations.tr(context, 'pending'),
                    color: isDark
                        ? AppTheme.darkWarning
                        : AppTheme.lightWarning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle,
                    value: closedDocuments.toString(),
                    label: AppLocalizations.tr(context, 'done'),
                    color: isDark
                        ? AppTheme.darkSuccess
                        : AppTheme.lightSuccess,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recently Added Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.tr(context, 'recentlyAdded'),
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onTabChange(1);
                  },
                  child: Text(
                    AppLocalizations.tr(context, 'viewAll'),
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Recently Added Documents List
            recentDocuments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        AppLocalizations.tr(context, 'noDocuments'),
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = recentDocuments[index];
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
          ],
        ),
      ),
    );
  }
}
