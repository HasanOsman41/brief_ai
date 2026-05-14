import 'package:flutter/material.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/document_result.dart';
import 'package:brief_ai/widgets/category_chip.dart';
import 'package:brief_ai/theme/app_theme.dart';

class FilterTabs extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;
  final FilterTabsType type;
  final TabController? tabController;

  const FilterTabs({
    Key? key,
    required this.selectedValue,
    required this.onChanged,
    required this.type,
    this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case FilterTabsType.categoryChips:
        return _buildCategoryChips(context);
      case FilterTabsType.taskTabs:
        return _buildTaskTabs(context);
    }
  }

  Widget _buildCategoryChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              label: AppLocalizations.tr(context, 'all'),
              isSelected: selectedValue == 'all',
              onTap: () => onChanged('all'),
            ),
          ),
          ...MainCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: AppLocalizations.tr(context, category.key),
                icon: category.iconData,
                isSelected: selectedValue == category.key,
                onTap: () => onChanged(category.key),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(30),
        ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        dividerColor: Theme.of(context).colorScheme.background,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(text: AppLocalizations.tr(context, 'important')),
          Tab(text: AppLocalizations.tr(context, 'soon')),
          Tab(text: AppLocalizations.tr(context, 'completed')),
          Tab(text: AppLocalizations.tr(context, 'all')),
        ],
      ),
    );
  }
}

enum FilterTabsType { categoryChips, taskTabs }
