// lib/screens/splash_screen.dart
import 'package:brief_ai/cubit/auth_cubit/auth_cubit.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _decided = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
    if (!mounted) return;

    if (!onboardingDone) {
      _decided = true;
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    // Onboarding done — route based on auth state
    await context.read<AuthCubit>().checkCurrentUser();
    if (!mounted) return;
    _routeForState(context.read<AuthCubit>().state);
  }

  void _routeForState(AuthState state) {
    if (_decided) return;
    if (state is Authenticated) {
      _decided = true;
      Navigator.pushReplacementNamed(context, '/home');
      _maybeOpenNotificationTarget();
    } else if (state is Unauthenticated || state is AuthError) {
      _decided = true;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// When the app was cold-started by tapping a reminder, open that document
  /// on top of the home screen once the home route is in place.
  void _maybeOpenNotificationTarget() {
    final id = NotificationService().consumeLaunchDocumentId();
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.navigatorKey.currentState?.pushNamed(
        '/document-detail',
        arguments: {'documentId': id},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) => _routeForState(state),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.1),
                Colors.transparent,
                primaryColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.document_scanner,
                          size: 60,
                          color: primaryColor,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.tr(context, 'appName'),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.tr(context, 'briefAIDescription'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 48),
                Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.tr(context, 'loading'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
