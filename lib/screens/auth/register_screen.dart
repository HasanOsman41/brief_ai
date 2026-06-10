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
import 'package:brief_ai/widgets/app_loading.dart';
import 'package:brief_ai/widgets/common_button.dart';
import 'package:brief_ai/widgets/language_sheet.dart';
import 'package:brief_ai/widgets/professional_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
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

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) {
      return AppLocalizations.tr(context, 'passwords_dont_match');
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().registerWithEmail(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text,
        );
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
            title: AppLocalizations.tr(context, 'register_failed'),
            message: AppLocalizations.tr(context, state.messageKey),
            type: SnackbarType.error,
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48,
                          maxWidth: 480,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              BrandHeader(
                                title: AppLocalizations.tr(context, 'register_title'),
                                subtitle: AppLocalizations.tr(context, 'register_subtitle'),
                                primary: primary,
                                fallbackIcon: Icons.person_add_alt_1,
                              ),
                              const SizedBox(height: 28),
                              AutofillGroup(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      AuthTextField(
                                        controller: _nameCtrl,
                                        label: AppLocalizations.tr(context, 'name_optional'),
                                        prefixIcon: Icons.person_outline,
                                        keyboardType: TextInputType.name,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.name],
                                        enabled: !loading,
                                      ),
                                      const SizedBox(height: 14),
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
                                      const SizedBox(height: 14),
                                      AuthTextField(
                                        controller: _passwordCtrl,
                                        label: AppLocalizations.tr(context, 'password'),
                                        hintText: '••••••••',
                                        prefixIcon: Icons.lock_outline,
                                        obscure: true,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.newPassword],
                                        validator: _validatePassword,
                                        enabled: !loading,
                                      ),
                                      const SizedBox(height: 14),
                                      AuthTextField(
                                        controller: _confirmCtrl,
                                        label: AppLocalizations.tr(context, 'confirm_password'),
                                        hintText: '••••••••',
                                        prefixIcon: Icons.lock_outline,
                                        obscure: true,
                                        textInputAction: TextInputAction.done,
                                        validator: _validateConfirm,
                                        onSubmitted: (_) => _submit(),
                                        enabled: !loading,
                                      ),
                                      const SizedBox(height: 22),
                                      CommonButton(
                                        text: loading
                                            ? AppLocalizations.tr(context, 'signing_up')
                                            : AppLocalizations.tr(context, 'create_account'),
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
                                question: AppLocalizations.tr(context, 'have_account_sign_in'),
                                actionLabel: AppLocalizations.tr(context, 'sign_in'),
                                primary: primary,
                                onTap: loading ? null : () => Navigator.pop(context),
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
              if (loading)
                AppLoadingOverlay(
                  message: AppLocalizations.tr(context, 'signing_up'),
                ),
            ],
          ),
        );
      },
    );
  }
}
