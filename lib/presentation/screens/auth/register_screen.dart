import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/core/validators/user_validators.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/auth/viewmodel/register_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_password_field.dart';
import 'package:gasosa_app/presentation/widgets/logo_hero.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameEC = TextEditingController();
  final _emailEC = TextEditingController();
  final _passwordEC = TextEditingController();
  final _confirmPasswordEC = TextEditingController();

  late final RegisterViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<RegisterViewModel>();
  }

  Future<void> _handleRegister() async {
    if (_viewModel.isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    final result = await _viewModel.register(
      name: _nameEC.text,
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
      listenable: _viewModel.registerCommand.state,
      builder: (_, _) {
        final isLoading = _viewModel.isLoading;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go(Routes.login),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSpacing.gap16,
                          const LogoHero(size: 120),
                          AppSpacing.gap8,
                          Text(
                            AuthStrings.registerTitle,
                            style: AppTypography.titleSm,
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.gap24,
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
                                    label: AuthStrings.nameLabel,
                                    hint: AuthStrings.nameHint,
                                    controller: _nameEC,
                                    validator: UserValidators.name,
                                  ),
                                  GasosaFormField(
                                    label: AuthStrings.emailRegisterLabel,
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
                                  GasosaPasswordField(
                                    label: AuthStrings.confirmPasswordLabel,
                                    hint: AuthStrings.confirmPasswordHint,
                                    controller: _confirmPasswordEC,
                                    validator: UserValidators.confirmPassword(_passwordEC),
                                  ),
                                  AppSpacing.gap4,
                                  GasosaButton(
                                    label: AuthStrings.registerButton,
                                    onPressed: isLoading ? null : _handleRegister,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gap16,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: GestureDetector(
                      onTap: () => context.go(Routes.login),
                      child: Text(
                        AuthStrings.loginLink,
                        style: AppTypography.textMdBold.copyWith(color: AppColors.primary),
                        textAlign: TextAlign.center,
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

  @override
  void dispose() {
    _nameEC.dispose();
    _emailEC.dispose();
    _passwordEC.dispose();
    _confirmPasswordEC.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}
