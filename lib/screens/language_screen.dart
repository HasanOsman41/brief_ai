import 'package:flutter/material.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:brief_ai/main.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'de'; // Default value
  bool _isLoading = false;

  final List<Map<String, dynamic>> _languages = const [
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪', 'direction': 'ltr'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'direction': 'ltr'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'direction': 'rtl'},
  ];

  @override
  void initState() {
    super.initState();
    // Don't access Localizations.localeOf(context) here
    // We'll set the language in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now it's safe to access Localizations
    _selectedLanguage = Localizations.localeOf(context).languageCode;
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() {
      _isLoading = true;
    });

    // Small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      // Update app locale
      BriefAIApp.setLocale(context, Locale(languageCode));
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageCode == 'de' ? 'Sprache geändert' :
            languageCode == 'en' ? 'Language changed' :
            'تم تغيير اللغة',
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkSuccess 
              : AppTheme.lightSuccess,
          duration: const Duration(seconds: 1),
        ),
      );
      
      // Navigate back after language change
      Navigator.pop(context, languageCode);
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'Deutsch';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.tr(context, 'language')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                child: Column(
                  children: _languages.map((language) {
                    final isSelected = language['code'] == _selectedLanguage;
                    final isRTL = language['direction'] == 'rtl';
                    
                    return Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                language['flag'],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(
                            language['name'],
                            style: Theme.of(context).textTheme.titleMedium,
                            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          subtitle: Text(
                            language['code'].toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: primaryColor,
                                )
                              : null,
                          onTap: _isLoading ? null : () async {
                            setState(() {
                              _selectedLanguage = language['code'];
                            });
                            await _changeLanguage(language['code']);
                          },
                        ),
                        if (language != _languages.last)
                          const Divider(),
                      ],
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 20),
              
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '🌐 ${AppLocalizations.tr(context, 'language')}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedLanguage == 'de' 
                            ? 'Wählen Sie Ihre bevorzugte Sprache'
                            : _selectedLanguage == 'en'
                                ? 'Choose your preferred language'
                                : 'اختر لغتك المفضلة',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedLanguage == 'de'
                            ? 'Sprache wird geändert...'
                            : _selectedLanguage == 'en'
                                ? 'Changing language...'
                                : 'جاري تغيير اللغة...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}