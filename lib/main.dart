import 'package:brief_ai/data/local/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/screens/splash_screen.dart';
import 'package:brief_ai/screens/home_screen.dart';
import 'package:brief_ai/screens/scan_screen.dart';
import 'package:brief_ai/screens/document_detail_screen.dart';
import 'package:brief_ai/screens/settings_screen.dart';
import 'package:brief_ai/screens/onboarding_screen.dart';
import 'package:brief_ai/screens/search_screen.dart';
import 'package:brief_ai/screens/backup_import_screen.dart';
import 'package:brief_ai/screens/privacy_screen.dart';
import 'package:brief_ai/screens/impressum_screen.dart';
import 'package:brief_ai/screens/language_screen.dart';
import 'package:brief_ai/screens/reminders_screen.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/services/locale_service.dart';
import 'package:brief_ai/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await DatabaseHelper().database; // Ensure database is initialized
  runApp(const BriefAIApp());
}

class BriefAIApp extends StatefulWidget {
  const BriefAIApp({Key? key}) : super(key: key);

  @override
  State<BriefAIApp> createState() => _BriefAIAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _BriefAIAppState? state = context
        .findAncestorStateOfType<_BriefAIAppState>();
    state?.setLocale(newLocale);
  }
}

class _BriefAIAppState extends State<BriefAIApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  final LocaleService _localeService = LocaleService();

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _localeService.getLocale();
    setState(() {
      _locale = Locale(savedLocale);
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void setLocale(Locale locale) async {
    await _localeService.saveLocale(locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BriefAI',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: _locale,
      supportedLocales: const [
        Locale('de'), // German
        Locale('en'), // English
        Locale('ar'), // Arabic
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // If we have a saved locale, use it
        if (_locale != null) {
          return _locale;
        }

        // Otherwise check if the current locale is supported
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        // If not, return German (default)
        return const Locale('de');
      },
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => HomeScreen(onToggleTheme: _toggleTheme),
        '/scan': (context) => const ScanScreen(),
        '/document-detail': (context) => const DocumentDetailScreen(),
        '/settings': (context) => SettingsScreen(onToggleTheme: _toggleTheme),
        '/search': (context) => const SearchScreen(),
        '/backup': (context) => const BackupImportScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/impressum': (context) => const ImpressumScreen(),
        '/language': (context) => const LanguageScreen(),
        '/reminders': (context) => const RemindersScreen(),
      },
    );
  }
}
