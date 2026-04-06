import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/core/validators/user_validators.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/auth/viewmodel/login_viewmodel.dart';
import 'package:gasosa_app/presentation/screens/auth/widgets/auth_google_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_password_field.dart';
import 'package:gasosa_app/presentation/widgets/logo_hero.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailEC = TextEditingController();
  final _passwordEC = TextEditingController();
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<LoginViewModel>();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_viewModel.isLoading) return;

    final result = await _viewModel.googleSignIn();
    if (!mounted) return;
    result?.fold(
      (failure) => Messages.showWarning(context, failure.message),
      (user) {
        context.go(Routes.dashboard, extra: {'email': user.email});
      },
    );
  }

  Future<void> _handleLoginWithEmailPassword() async {
    if (_viewModel.isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final result = await _viewModel.loginWithEmailPassword(
      email: _emailEC.text,
      password: _passwordEC.text,
    );
    if (!mounted) return;
    result?.fold(
      (failure) => Messages.showError(context, failure.message),
      (user) {
        context.go(Routes.dashboard, extra: {'email': user.email});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel.googleCommand.state, _viewModel.loginCommand.state]),
      builder: (_, _) {
        final isLoading = _viewModel.isLoading;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  const Spacer(),
                  const LogoHero(size: 120),
                  AppSpacing.gap8,
                  Text(
                    AuthStrings.loginTitle,
                    style: AppTypography.titleSm,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gap24,
                  AuthGoogleButton(
                    onPressed: isLoading ? null : _handleGoogleSignIn,
                    isLoading: isLoading,
                  ),
                  AppSpacing.gap16,
                  _buildDivider(),
                  AppSpacing.gap16,
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        spacing: AppSpacing.md,
                        children: [
                          GasosaFormField(
                            label: AuthStrings.emailLabel,
                            hint: AuthStrings.emailHint,
                            controller: _emailEC,
                            keyboardType: TextInputType.emailAddress,
                            validator: UserValidators.email,
                          ),
                          GasosaPasswordField(
                            label: AuthStrings.passwordLabel,
                            hint: AuthStrings.passwordHint,
                            controller: _passwordEC,
                            validator: UserValidators.password,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () => context.push(Routes.forgotPassword),
                                child: Text(
                                  AuthStrings.forgotPasswordLink,
                                  style: AppTypography.textSmRegular.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GasosaButton(
                            label: AuthStrings.loginButton,
                            isDisabled: isLoading,
                            onPressed: isLoading ? null : _handleLoginWithEmailPassword,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: GestureDetector(
                      onTap: () => context.go(Routes.register),
                      child: Text(
                        AuthStrings.registerLink,
                        style: AppTypography.textMdBold.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: AppSpacing.paddingHorizontalSm,
          child: Text(
            'ou',
            style: AppTypography.textSmRegular.copyWith(
              color: AppColors.text.withValues(alpha: 0.5),
            ),
          ),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }

  @override
  void dispose() {
    _emailEC.dispose();
    _passwordEC.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}
