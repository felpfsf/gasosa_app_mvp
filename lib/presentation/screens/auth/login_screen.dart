import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
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
    _viewModel = getIt<LoginViewModel>();
    super.initState();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_viewModel.state.isLoading) return;

    final ok = await _viewModel.googleSignIn();
    if (!mounted) return;
    if (ok) {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      context.go(RoutePaths.dashboard, extra: {'email': email});
    } else {
      final message = _viewModel.state.errorMessage ?? 'Erro desconhecido';
      Messages.showWarning(context, message);
    }
  }

  Future<void> _handleLoginWithEmalPassword() async {
    if (_viewModel.state.isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final ok = await _viewModel.loginWithEmailPassword();

    if (!mounted) return;

    if (ok) {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      context.go(RoutePaths.dashboard, extra: {'email': email});
    } else {
      final message = _viewModel.state.errorMessage ?? 'Erro desconhecido';
      Messages.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (_, __) {
        final state = _viewModel.state;
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
                      Text('Entrar no Gasosa', style: AppTypography.titleLg),
                      AuthGoogleButton(
                        onPressed: state.isLoading ? null : () => _handleGoogleSignIn(),
                        isLoading: state.isLoading,
                      ),
                      _buildDivider(),
                      Form(
                        key: _formKey,
                        child: Column(
                          spacing: AppSpacing.lg,
                          children: [
                            GasosaFormField(
                              label: 'Email',
                              controller: _emailEC,
                              keyboardType: TextInputType.emailAddress,
                              validator: UserValidators.email,
                              onChanged: (value) => _viewModel.setEmail(value),
                            ),
                            GasosaPasswordField(
                              label: 'Senha',
                              controller: _passwordEC,
                              validator: UserValidators.password,
                              onChanged: (value) => _viewModel.setPassword(value),
                            ),
                            GasosaButton(
                              label: 'Entrar',
                              isDisabled: state.isLoading,
                              onPressed: state.isLoading ? null : () => _handleLoginWithEmalPassword(),
                            ),
                          ],
                        ),
                      ),
                      _linkRow(
                        'Não tem uma conta? Cadastre-se',
                        () {
                          context.go(RoutePaths.register);
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
    super.dispose();
    _emailEC.dispose();
    _passwordEC.dispose();
    _viewModel.dispose();
  }
}
