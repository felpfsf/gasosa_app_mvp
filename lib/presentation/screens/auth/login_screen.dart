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
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: AppSpacing.lg,
                    children: [
                      const LogoHero(size: 200),
                      Text(AuthStrings.loginTitle, style: AppTypography.titleLg),
                      AuthGoogleButton(
                        onPressed: isLoading ? null : () => _handleGoogleSignIn(),
                        isLoading: isLoading,
                      ),
                      _buildDivider(),
                      Form(
                        key: _formKey,
                        child: Column(
                          spacing: AppSpacing.lg,
                          children: [
                            GasosaFormField(
                              label: AuthStrings.emailLabel,
                              controller: _emailEC,
                              keyboardType: TextInputType.emailAddress,
                              validator: UserValidators.email,
                            ),
                            GasosaPasswordField(
                              label: AuthStrings.passwordLabel,
                              controller: _passwordEC,
                              validator: UserValidators.password,
                            ),
                            GasosaButton(
                              label: AuthStrings.loginButton,
                              isDisabled: isLoading,
                              onPressed: isLoading ? null : () => _handleLoginWithEmailPassword(),
                            ),
                          ],
                        ),
                      ),
                      _linkRow(
                        AuthStrings.registerLink,
                        () {
                          context.go(Routes.register);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _linkRow(String text, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Text(
        text,
        style: AppTypography.textMdBold.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
          ),
        ),
        Padding(
          padding: AppSpacing.paddingHorizontalSm,
          child: Text('ou'),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
          ),
        ),
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
