// lib/screens/document_detail_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/services/data_service.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _reminderEnabled = true;
  int _currentPage = 0;
  Map<String, dynamic> document = {};
  late TabController _tabController;
  String ocrText = '''
Weiterbewilligungsantrag
Antrag auf Weiterbewilligung der Leistungen zur Sicherung des Lebensunterhalts nach dem Zweiten Buch Sozialgesetzbuch (SGB II)

Zutreffendes bitte ankreuzen
Weitere Informationen finden Sie zu der jeweiligen Nummer in den Ausfüllhinweisen

Die nachstehenden Daten unterliegen dem Sozialgeheimnis (siehe Merkblatt SGB II). Ihre Angaben werden aufgrund der §§ 60–65 Erstes Buch Sozialgesetzbuch (SGB I) und der §§ 67a, b, c Zweites Buch Sozialgesetzbuch (SGB X) für die Leistungen nach dem Zweiten Buch Sozialgesetzbuch (SGB II) erhoben. Datenschutzrechtliche Hinweise erhalten Sie bei Ihrem zuständigen Jobcenter sowie im Internet unter: www.jobcenter.de

Das Merkblatt SGB II, die Ausfüllhinweise und weitere Anlagen finden Sie im Internet unter www.jobcenter.de

Beachten Sie bitte, dass in den Abschnitten 2, 3, 4, 6 nicht nur nach Änderungen, sondern auch nach den derzeitigen Verhältnissen gefragt wird. Geben Sie in Abschnitt 5 bitte alle weiteren Änderungen an, die noch nicht mitgeteilt wurden oder seit der letzten Antragstellung eingetreten sind.

Falls Sie für Ihre Antworten mehr Platz benötigen, als im Formular vorgesehen ist, verwenden Sie bitte ein separates Blatt Papier und geben dieses Ihrem Antrag bei.

1. Persönliche Daten der Antragstellerin / des Antragstellers

Anrede | Vorname
Familienname | Geburtsdatum
Straße, Hausnummer
Postleitzahl | Wohnort
Nummer der Bedarfsgemeinschaft

Bearbeitungsvermerke (Nur vom Jobcenter auszufüllen)

Eingangsstempel

Tag der Antragstellung

Ende des laufenden Bewilligungsabschnitts

Dienststelle

Team''';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final documentId = args['documentId'] as int;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    document = DataService().getDocumentById(documentId - 1);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.share_outlined,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        onPressed: () {
                          _showShareOptions(context);
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              // Handle edit
                              break;
                            case 'export':
                              // Handle export
                              break;
                            case 'delete':
                              _showDeleteDialog(context);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: primaryColor, size: 20),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.tr(context, 'edit')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.tr(context, 'exportPDF')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: isDark
                                      ? AppTheme.darkDanger
                                      : AppTheme.lightDanger,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.tr(context, 'delete'),
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.darkDanger
                                        : AppTheme.lightDanger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Document preview with page indicator
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDark ? Colors.grey[900] : Colors.grey[200],
              ),
              child: Stack(
                children: [
                  PageView(
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/docs/${document['image']}',
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      if (document['image2'] != null)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/docs/${document['image2']}',
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        2,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? primaryColor
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Glass info panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppLocalizations.tr(context, 'contracts'),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${AppLocalizations.tr(context, 'dueDate')} 17.03.2026',
                              style: TextStyle(
                                color: AppTheme.lightWarning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _reminderEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _reminderEnabled = value;
                                });
                              },
                              activeColor: primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mietvertrag Wohnung',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppLocalizations.tr(context, 'addedDate')} 15.03.2026',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab sections
            Expanded(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: AppLocalizations.tr(context, 'scanPages')),
                      Tab(text: AppLocalizations.tr(context, 'ocrText')),
                      Tab(text: AppLocalizations.tr(context, 'aiAnalysis')),
                    ],
                    labelColor: primaryColor,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color,
                    indicatorColor: primaryColor,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Scan pages
                        _buildScanPagesTab(context),

                        // OCR Text
                        _buildOcrTextTab(context),

                        // AI Analysis
                        _buildAIAnalysisTab(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xBF141928) : const Color(0xE5FFFFFF),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              context,
              Icons.share,
              AppLocalizations.tr(context, 'share'),
            ),
            _buildActionButton(
              context,
              Icons.picture_as_pdf,
              AppLocalizations.tr(context, 'exportPDF'),
            ),
            _buildActionButton(
              context,
              Icons.edit,
              AppLocalizations.tr(context, 'edit'),
            ),
            _buildActionButton(
              context,
              Icons.delete_outline,
              AppLocalizations.tr(context, 'delete'),
              isDestructive: true,
              onTap: () => _showDeleteDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanPagesTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage('assets/docs/${document['image'] ?? '1.jpeg'}'),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOcrTextTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.all(1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.tr(context, 'extractedText'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.tr(context, 'textCopied'),
                          ),
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkSuccess
                              : AppTheme.lightSuccess,
                        ),
                      );
                    },
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable text area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  // Changed to SelectableText for better UX
                  ocrText,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: 'RobotoMono',
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, 'summary'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Untermietvertrag für eine Wohnung in Berlin. Laufzeit: 6 Monate. Kaution: 1500€. Monatsmiete: 750€ warm.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, 'nextSteps'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildChecklistItem(context, 'Kaution überweisen', false),
                _buildChecklistItem(
                  context,
                  'Unterschriebenen Vertrag zurücksenden',
                  true,
                ),
                _buildChecklistItem(
                  context,
                  'Schlüsselübergabe terminieren',
                  false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.tr(context, 'riskLevel'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightWarning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppLocalizations.tr(context, 'medium'),
                    style: TextStyle(
                      color: AppTheme.lightWarning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(context, 'suggestedDeadline'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '31.03.2026',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isDestructive
                ? (Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkDanger
                      : AppTheme.lightDanger)
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDestructive
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkDanger
                        : AppTheme.lightDanger)
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    String text,
    bool isChecked,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isChecked
                ? (Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkSuccess
                      : AppTheme.lightSuccess)
                : Theme.of(context).textTheme.bodyMedium?.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                decoration: isChecked ? TextDecoration.lineThrough : null,
                color: isChecked
                    ? Theme.of(context).textTheme.bodyMedium?.color
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(AppLocalizations.tr(context, 'shareImage')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'sharingImage')),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(AppLocalizations.tr(context, 'sharePDF')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'sharingPDF')),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: Text(AppLocalizations.tr(context, 'shareText')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'sharingText')),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.tr(context, 'deleteDocument')),
        content: Text(AppLocalizations.tr(context, 'deleteDocumentConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.tr(context, 'cancel'),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Return to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.tr(context, 'documentDeleted'),
                  ),
                  backgroundColor: isDark
                      ? AppTheme.darkSuccess
                      : AppTheme.lightSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppTheme.darkDanger
                  : AppTheme.lightDanger,
            ),
            child: Text(AppLocalizations.tr(context, 'delete')),
          ),
        ],
      ),
    );
  }
}
