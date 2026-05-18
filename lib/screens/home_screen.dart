// lib/screens/home_screen.dart
import 'dart:ui';

import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/screens/tabs/documents_tab.dart';
import 'package:brief_ai/screens/tabs/home_dashboard_tab.dart';
import 'package:brief_ai/screens/tabs/profile_tab.dart';
import 'package:brief_ai/screens/tabs/tasks_tab.dart';
import 'package:brief_ai/theme/app_theme.dart';
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

  String _tabTitle(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return AppLocalizations.tr(context, 'home');
      case 1:
        return AppLocalizations.tr(context, 'documents');
      case 2:
        return AppLocalizations.tr(context, 'tasks');
      case 3:
        return AppLocalizations.tr(context, 'profile');
      default:
        return AppLocalizations.tr(context, 'home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final reverseColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with privacy indicator
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.transparent, Colors.transparent],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                        Row(
                          children: [
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 10,
                            //     vertical: 4,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: primaryColor.withOpacity(0.1),
                            //     borderRadius: BorderRadius.circular(20),
                            //   ),
                            //   child: Row(
                            //     mainAxisSize: MainAxisSize.min,
                            //     children: [
                            //       Icon(
                            //         Icons.lock_outline,
                            //         size: 12,
                            //         color: primaryColor,
                            //       ),
                            //       const SizedBox(width: 4),
                            //       Text(
                            //         AppLocalizations.tr(context, 'localOnly'),
                            //         style: TextStyle(
                            //           color: primaryColor,
                            //           fontSize: 11,
                            //           fontWeight: FontWeight.w500,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            Container(
                              margin: const EdgeInsets.only(right: 8, left: 4),
                              height: 25,
                              width: 3,
                            ),
                            Text(
                              _tabTitle(context),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // // ── Tab title (replaces the three icon buttons) ──
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 35.0),
                    //   child: Text(
                    //     _tabTitle(context),
                    //     style: Theme.of(context).textTheme.headlineMedium
                    //         ?.copyWith(
                    //           fontSize: 20,
                    //           fontWeight: FontWeight.w500,
                    //           color: Theme.of(context).colorScheme.onSurface,
                    //           letterSpacing: -0.2,
                    //         ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  HomeDashboardTab(
                    onTabChange: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                  const DocumentsTab(),
                  const TasksTab(),
                  ProfileTab(onToggleTheme: widget.onToggleTheme),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: PrimaryFAB(
        onPressed: () => Navigator.pushNamed(context, '/scan'),
        icon: Icons.document_scanner,
        label: AppLocalizations.tr(context, 'scanButton'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
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
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: reverseColor,
              unselectedItemColor: reverseColor.withOpacity(0.6),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: AppLocalizations.tr(context, 'home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.folder_outlined),
                  activeIcon: const Icon(Icons.folder),
                  label: AppLocalizations.tr(context, 'documents'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.task_outlined),
                  activeIcon: const Icon(Icons.task),
                  label: AppLocalizations.tr(context, 'tasks'),
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
}

// Small helper to avoid repeating the header button decoration
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.primaryColor,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withOpacity(0.5)
            : AppTheme.lightSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 0.5,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 22, color: primaryColor),
        onPressed: onPressed,
      ),
    );
  }
}
