import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/models/document.dart';
import 'package:brief_ai/services/document_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/utils/risk_level.dart';
import 'package:brief_ai/widgets/document_card.dart';
import 'package:brief_ai/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({Key? key}) : super(key: key);

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _taskFilter = 'all';
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

  RiskLevel _filterToLevel(String filter) {
    switch (filter) {
      case 'wichtig':
        return RiskLevel.wichtig;
      case 'pruefen':
        return RiskLevel.pruefen;
      case 'offen':
        return RiskLevel.offen;
      default:
        return RiskLevel.offen;
    }
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
        child: ElevatedButton(
          onPressed: _refreshDocuments,
          child: Text(AppLocalizations.tr(context, 'retry')),
        ),
      );
    }

    final wichtig = _documents
        .where((d) => calcRiskLevel(d.deadline) == RiskLevel.wichtig)
        .toList();
    final pruefen = _documents
        .where((d) => calcRiskLevel(d.deadline) == RiskLevel.pruefen)
        .toList();
    final offen = _documents
        .where((d) => calcRiskLevel(d.deadline) == RiskLevel.offen)
        .toList();

    List<Document> filtered;
    switch (_taskFilter) {
      case 'wichtig':
        filtered = wichtig;
        break;
      case 'pruefen':
        filtered = pruefen;
        break;
      case 'offen':
        filtered = offen;
        break;
      default:
        filtered = [...wichtig, ...pruefen, ...offen];
    }

    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Column(
      children: [
        // Stat cards
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: RiskLevel.wichtig.icon,
                  value: wichtig.length.toString(),
                  label: AppLocalizations.tr(
                    context,
                    RiskLevel.wichtig.translationKey,
                  ),
                  color: RiskLevel.wichtig.color(isDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: RiskLevel.pruefen.icon,
                  value: pruefen.length.toString(),
                  label: AppLocalizations.tr(
                    context,
                    RiskLevel.pruefen.translationKey,
                  ),
                  color: RiskLevel.pruefen.color(isDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: RiskLevel.offen.icon,
                  value: offen.length.toString(),
                  label: AppLocalizations.tr(
                    context,
                    RiskLevel.offen.translationKey,
                  ),
                  color: RiskLevel.offen.color(isDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final f in ['all', 'wichtig', 'pruefen', 'offen'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _taskFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _taskFilter == f
                            ? (f == 'all'
                                  ? primaryColor
                                  : _filterToLevel(f).color(isDark))
                            : (isDark
                                  ? AppTheme.darkSurface
                                  : AppTheme.lightSurface),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: f == 'all'
                              ? primaryColor
                              : _filterToLevel(f).color(isDark),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        f == 'all'
                            ? AppLocalizations.tr(context, 'all')
                            : AppLocalizations.tr(
                                context,
                                _filterToLevel(f).translationKey,
                              ),
                        style: TextStyle(
                          color: _taskFilter == f
                              ? Colors.white
                              : (f == 'all'
                                    ? primaryColor
                                    : _filterToLevel(f).color(isDark)),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Document list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.tr(context, 'noDocuments'),
                    style: TextStyle(color: textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final groupColor = calcRiskLevel(
                        doc.deadline,
                      ).color(isDark);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Stack(
                          children: [
                            DocumentCard(
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
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/document-detail',
                                arguments: {'documentId': doc.id},
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 8,
                              bottom: 8,
                              child: Container(
                                width: 4,
                                decoration: BoxDecoration(
                                  color: groupColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
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
