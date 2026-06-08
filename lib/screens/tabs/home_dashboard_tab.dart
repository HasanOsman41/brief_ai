import 'package:brief_ai/cubit/document_cubit/document_cubit.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/document_card.dart';
import 'package:brief_ai/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeDashboardTab extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeDashboardTab({super.key, required this.onTabChange});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocConsumer<DocumentCubit, DocumentState>(
      listener: (context, state) {
        if (state is DocumentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: isDark ? AppTheme.darkDanger : AppTheme.lightDanger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DocumentLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(primaryColor),
            ),
          );
        }

        if (state is DocumentError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
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
          final documents = state.documents;
          
          int totalDocuments = documents.length;
          int pendingDocuments = documents
              .where((doc) => doc.statusKey == 'pending' || doc.statusKey == 'inProgress')
              .length;
          int closedDocuments = documents
              .where((doc) => doc.statusKey == 'done')
              .length;

          var recentDocuments = documents.take(3).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<DocumentCubit>().refreshFromDatabase();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          color: isDark ? AppTheme.darkWarning : AppTheme.lightWarning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.check_circle,
                          value: closedDocuments.toString(),
                          label: AppLocalizations.tr(context, 'done'),
                          color: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.tr(context, 'recentlyAdded'),
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
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
                  recentDocuments.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              AppLocalizations.tr(context, 'noDocuments'),
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}