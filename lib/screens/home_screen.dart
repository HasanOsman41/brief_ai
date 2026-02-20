// lib/screens/home_screen.dart
import 'dart:ui';

import 'package:brief_ai/localization/app_localizations.dart';
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

  // Document data with category keys instead of localized strings
  final List<Map<String, dynamic>> _documents = [
    {
      'title': 'Mietvertrag Wohnung',
      'categoryKey': 'contracts',
      'date': '15.03.2024',
      'deadline': DateTime.now().add(const Duration(days: 2)),
      'statusKey': 'pending',
      'hasDeadline': true,
      'image': '1.jpeg'
    },
    {
      'title': 'GEZ Befreiung',
      'categoryKey': 'letters',
      'date': '10.03.2024',
      'deadline': DateTime.now().add(const Duration(days: 5)),
      'statusKey': 'done',
      'hasDeadline': true,
      'image': '2.jpeg'
    },
    {
      'title': 'Stromrechnung Januar',
      'categoryKey': 'invoices',
      'date': '05.03.2024',
      'deadline': DateTime.now().add(const Duration(days: 12)),
      'statusKey': 'pending',
      'hasDeadline': true,
      'image': '3.jpeg'
    },
    {
      'title': 'Krankenkassenbescheid',
      'categoryKey': 'important',
      'date': '01.03.2024',
      'deadline': null,
      'statusKey': 'pending',
      'hasDeadline': false,
      'image': '4.jpeg'
    },
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with privacy indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.tr(context, 'appName'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
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
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.tr(context, 'localOnly'),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        onPressed: widget.onToggleTheme,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
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
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final doc = _documents[index];
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
                        Navigator.pushNamed(context, '/document-detail');
                      },
                    ),
                  );
                },
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
                  case 0:
                    // Already on home
                    break;
                  case 1:
                    Navigator.pushNamed(context, '/scan');
                    break;
                  case 2:
                    // Documents - could navigate to documents screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.tr(context, 'documents')),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    break;
                  case 3:
                    // Profile - could navigate to profile screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.tr(context, 'profile')),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    break;
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryColor,
              unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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