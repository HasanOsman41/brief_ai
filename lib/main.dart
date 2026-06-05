import 'package:brief_ai/data/local/database_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/screens/splash_screen.dart';
import 'package:brief_ai/screens/home_screen.dart';
import 'package:brief_ai/screens/scan_screen.dart';
import 'package:brief_ai/screens/document_detail_screen.dart';
import 'package:brief_ai/screens/onboarding_screen.dart';
import 'package:brief_ai/screens/backup_import_screen.dart';
import 'package:brief_ai/screens/privacy_screen.dart';
import 'package:brief_ai/screens/impressum_screen.dart';
import 'package:brief_ai/screens/language_screen.dart';
import 'package:brief_ai/screens/reminders_screen.dart';
import 'package:brief_ai/screens/auth/login_screen.dart';
import 'package:brief_ai/screens/auth/register_screen.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/services/locale_service.dart';
import 'package:brief_ai/services/notification_service.dart';
import 'package:brief_ai/services/theme_service.dart';
import 'package:brief_ai/cubit/document_cubit/document_cubit.dart';
import 'package:brief_ai/cubit/auth_cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final results = await Future.wait([
      _localeService.getLocale(),
      _themeService.getThemeMode(),
    ]);
    if (!mounted) return;
    setState(() {
      _locale = Locale(results[0] as String);
      _themeMode = results[1] as ThemeMode;
    });
  }

  void _toggleTheme() {
    final Brightness current;
    if (_themeMode == ThemeMode.system) {
      current = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    } else {
      current = _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
    }
    final newMode =
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = newMode);
    _themeService.saveThemeMode(newMode);
  }

  void setLocale(Locale locale) async {
    await _localeService.saveLocale(locale.languageCode);
    if (!mounted) return;
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => DocumentCubit()..loadDocuments()),
      ],
      child: MaterialApp(
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
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => HomeScreen(onToggleTheme: _toggleTheme),
          '/scan': (context) => const ScanScreen(),
          '/document-detail': (context) => const DocumentDetailScreen(),
          '/backup': (context) => const BackupImportScreen(),
          '/privacy': (context) => const PrivacyScreen(),
          '/impressum': (context) => const ImpressumScreen(),
          '/language': (context) => const LanguageScreen(),
          '/reminders': (context) => const RemindersScreen(),
        },
      ),
    );
  }
}
