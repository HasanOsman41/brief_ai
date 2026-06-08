import 'package:brief_ai/cubit/auth_cubit/auth_cubit.dart';
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/main.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:brief_ai/widgets/auth/auth_backdrop.dart';
import 'package:brief_ai/widgets/auth/auth_text_field.dart';
import 'package:brief_ai/widgets/auth/brand_header.dart';
import 'package:brief_ai/widgets/auth/footer_prompt.dart';
import 'package:brief_ai/widgets/auth/google_button.dart';
import 'package:brief_ai/widgets/auth/or_divider.dart';
import 'package:brief_ai/widgets/common_button.dart';
import 'package:brief_ai/widgets/language_sheet.dart';
import 'package:brief_ai/widgets/professional_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return AppLocalizations.tr(context, 'email_required');
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    if (!ok) return AppLocalizations.tr(context, 'invalid_email');
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return AppLocalizations.tr(context, 'password_required');
    if (value.length < 6) {
      return AppLocalizations.tr(context, 'password_too_short');
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signInWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
  }

  Future<void> _showForgotPasswordDialog() async {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppLocalizations.tr(ctx, 'password_reset_title'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tr(ctx, 'password_reset_hint'),
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.tr(ctx, 'email'),
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) {
                      return AppLocalizations.tr(ctx, 'email_required');
                    }
                    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                    if (!ok) return AppLocalizations.tr(ctx, 'invalid_email');
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.tr(ctx, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, ctrl.text.trim());
                }
              },
              child: Text(AppLocalizations.tr(ctx, 'send')),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      context.read<AuthCubit>().sendPasswordReset(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        } else if (state is AuthError) {
          ProfessionalSnackbar.show(
            context: context,
            title: AppLocalizations.tr(context, 'login_failed'),
            message: AppLocalizations.tr(context, state.messageKey),
            type: SnackbarType.error,
          );
        } else if (state is PasswordResetSent) {
          ProfessionalSnackbar.show(
            context: context,
            title: AppLocalizations.tr(context, 'password_reset_title'),
            message: AppLocalizations.tr(context, 'password_reset_sent'),
            type: SnackbarType.success,
          );
        }
      },
      builder: (context, state) {
        final loading = state is AuthLoading;
        return Scaffold(
          body: Stack(
            children: [
              AuthBackdrop(primary: primary, secondary: secondary),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 56,
                          maxWidth: 480,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              BrandHeader(
                                title: AppLocalizations.tr(context, 'login_title'),
                                subtitle: AppLocalizations.tr(context, 'login_subtitle'),
                                primary: primary,
                                fallbackIcon: Icons.document_scanner,
                              ),
                              const SizedBox(height: 36),
                              AutofillGroup(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      AuthTextField(
                                        controller: _emailCtrl,
                                        label: AppLocalizations.tr(context, 'email'),
                                        hintText: 'you@example.com',
                                        prefixIcon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.email],
                                        validator: _validateEmail,
                                        enabled: !loading,
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        controller: _passwordCtrl,
                                        label: AppLocalizations.tr(context, 'password'),
                                        hintText: '••••••••',
                                        prefixIcon: Icons.lock_outline,
                                        obscure: true,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [AutofillHints.password],
                                        validator: _validatePassword,
                                        onSubmitted: (_) => _submit(),
                                        enabled: !loading,
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: AlignmentDirectional.centerEnd,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            minimumSize: const Size(0, 36),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: loading ? null : _showForgotPasswordDialog,
                                          child: Text(
                                            AppLocalizations.tr(context, 'forgot_password'),
                                            style: TextStyle(
                                              color: primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      CommonButton(
                                        text: loading
                                            ? AppLocalizations.tr(context, 'signing_in')
                                            : AppLocalizations.tr(context, 'sign_in'),
                                        icon: loading ? null : Icons.arrow_forward_rounded,
                                        onTap: loading ? null : _submit,
                                        width: double.infinity,
                                        height: 54,
                                      ),
                                      const SizedBox(height: 22),
                                      OrDivider(textSecondary: textSecondary),
                                      const SizedBox(height: 22),
                                      GoogleButton(
                                        label: AppLocalizations.tr(context, 'continue_with_google'),
                                        enabled: !loading,
                                        onPressed: () =>
                                            context.read<AuthCubit>().signInWithGoogle(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: 24),
                              FooterPrompt(
                                question: AppLocalizations.tr(context, 'no_account_register'),
                                actionLabel: AppLocalizations.tr(context, 'register_link'),
                                primary: primary,
                                onTap: loading
                                    ? null
                                    : () => Navigator.pushNamed(context, '/register'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          ),
                          color: primary,
                          onPressed: () => BriefAIApp.toggleTheme(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.language_outlined),
                          color: primary,
                          onPressed: () => LanguageSheet.show(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
