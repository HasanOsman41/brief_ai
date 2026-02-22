// lib/screens/home_screen.dart
import 'dart:ui';

import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/services/data_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/category_chip.dart';
import 'package:brief_ai/widgets/document_card.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:brief_ai/widgets/primary_fab.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({Key? key, required this.onToggleTheme}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'all';

  // Use keys instead of localized strings for categories
  final List<Map<String, String>> _categoryKeys = const [
    {'key': 'all', 'labelKey': 'all'},
    {'key': 'contracts', 'labelKey': 'contracts'},
    {'key': 'invoices', 'labelKey': 'invoices'},
    {'key': 'letters', 'labelKey': 'letters'},
    {'key': 'important', 'labelKey': 'important'},
  ];

  // Helper method to get localized category label
  String _getCategoryLabel(String categoryKey) {
    switch (categoryKey) {
      case 'all':
        return AppLocalizations.tr(context, 'all');
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

  // Build Home Tab Dashboard
  Widget _buildHomeDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    var documents = DataService().getData();

    // Calculate statistics
    int totalDocuments = documents.length;
    int pendingDocuments = documents
        .where((doc) => doc['statusKey'] == 'pending')
        .length;
    int closedDocuments = documents
        .where((doc) => doc['statusKey'] == 'done')
        .length;

    // Get recently added documents (last 3)
    var recentDocuments = documents.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards - Now at the top
          Row(
            children: [
              // Total Documents
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.description,
                  value: totalDocuments.toString(),
                  label: AppLocalizations.tr(context, 'totalDocuments'),
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              // Pending Documents
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.pending_actions,
                  value: pendingDocuments.toString(),
                  label: AppLocalizations.tr(context, 'pending'),
                  color: isDark ? AppTheme.darkWarning : AppTheme.lightWarning,
                ),
              ),
              const SizedBox(width: 12),
              // Closed Documents
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.check_circle,
                  value: closedDocuments.toString(),
                  label: AppLocalizations.tr(context, 'done'),
                  color: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
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
                  // Switch to documents tab in bottom navigation
                  setState(() {
                    _selectedIndex = 2;
                  });
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
                        title: doc['title'],
                        category: _getCategoryLabel(doc['categoryKey']),
                        date: doc['date'],
                        deadline: doc['deadline'],
                        status: _getStatusLabel(doc['statusKey']),
                        hasDeadline: doc['hasDeadline'],
                        image: doc['image'],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/document-detail',
                            arguments: {'documentId': doc['id']},
                          );
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build Documents Tab (Original document list with search and filters)
  Widget _buildDocumentsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var documents = DataService().getData();

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
            children: _categoryKeys.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  label: _getCategoryLabel(category['key']!),
                  isSelected: _selectedCategory == category['key'],
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['key']!;
                    });
                  },
                ),
              );
            }).toList(),
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
              _buildSortDropdown(context),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Document list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              // Only show documents matching selected category (if not 'all')
              if (_selectedCategory != 'all' &&
                  doc['categoryKey'] != _selectedCategory) {
                return const SizedBox.shrink();
              }
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
                    Navigator.pushNamed(
                      context,
                      '/document-detail',
                      arguments: {'documentId': doc['id']},
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with privacy indicator - Enhanced for Home tab
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor.withOpacity(0.1), Colors.transparent],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left side - App name and local indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.tr(context, 'appName'),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 12,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.tr(context, 'localOnly'),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Right side - Theme and settings buttons with enhanced styling
                    Row(
                      children: [
                        // Theme toggle with background
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface.withOpacity(0.5)
                                : AppTheme.lightSurface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                              width: 0.5,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              size: 22,
                              color: primaryColor,
                            ),
                            onPressed: widget.onToggleTheme,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reminders button with background
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface.withOpacity(0.5)
                                : AppTheme.lightSurface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                              width: 0.5,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              size: 22,
                              color: primaryColor,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/reminders');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Settings button with background
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface.withOpacity(0.5)
                                : AppTheme.lightSurface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                              width: 0.5,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.settings_outlined,
                              size: 22,
                              color: primaryColor,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/settings');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Content based on selected tab
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  // Home Tab - Dashboard
                  _buildHomeDashboard(),

                  // Scan Tab - Will be handled by navigation
                  const SizedBox.shrink(),

                  // Documents Tab - Full document list
                  _buildDocumentsTab(),

                  // Profile Tab - Placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 80,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.tr(context, 'profile'),
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coming soon...',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                            fontSize: 16,
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
      ),

      // Floating scan button
      floatingActionButton: PrimaryFAB(
        onPressed: () {
          Navigator.pushNamed(context, '/scan');
        },
        icon: Icons.document_scanner,
        label: AppLocalizations.tr(context, 'scanButton'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xBF141928) : const Color(0xE5FFFFFF),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });

                // Handle navigation based on index
                switch (index) {
                  case 1: // Scan
                    Navigator.pushNamed(context, '/scan');
                    break;
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryColor,
              unselectedItemColor: Theme.of(
                context,
              ).textTheme.bodyMedium?.color,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: AppLocalizations.tr(context, 'home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.scanner_outlined),
                  activeIcon: const Icon(Icons.scanner),
                  label: AppLocalizations.tr(context, 'scanButton'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.folder_outlined),
                  activeIcon: const Icon(Icons.folder),
                  label: AppLocalizations.tr(context, 'documents'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outlined),
                  activeIcon: const Icon(Icons.person),
                  label: AppLocalizations.tr(context, 'profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xBF141928) : const Color(0xE5FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          // Handle sort option change
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sorted by $value'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        offset: const Offset(0, 40),
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Text(
              AppLocalizations.tr(context, 'latest'),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ],
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'latest',
            child: Row(
              children: [
                Icon(Icons.access_time, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr(context, 'latest')),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'deadline',
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr(context, 'deadline')),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'category',
            child: Row(
              children: [
                Icon(Icons.category, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.tr(context, 'category')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
