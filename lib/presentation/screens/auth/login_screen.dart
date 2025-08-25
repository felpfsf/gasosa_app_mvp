import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/auth/viewmodel/login_viewmodel.dart';
import 'package:gasosa_app/presentation/screens/auth/widgets/auth_google_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_password_field.dart';
import 'package:gasosa_app/presentation/widgets/logo_hero.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';
import 'package:validatorless/validatorless.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailEC = TextEditingController();
  final _passwordEC = TextEditingController();
  late final LoginViewmodel _viewModel;

  @override
  void initState() {
    _viewModel = getIt<LoginViewmodel>();
    super.initState();
  }

  Future<void> _handleGoogleSignIn() async {
    final ok = await _viewModel.googleSignIn();
    if (!mounted) {
      return;
    }
    if (ok) {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      context.go(RoutePaths.dashboard, extra: {'email': email});
    } else {
      final msg = _viewModel.state.errorMessage ?? 'Erro desconhecido';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _handleLoginWithEmalPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await _viewModel.loginWithEmailPassword();

    if (!mounted) {
      return;
    }

    if (ok) {
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      context.go(RoutePaths.dashboard, extra: {'email': email});
    } else {
      final msg = _viewModel.state.errorMessage ?? 'Erro desconhecido';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                      if (_viewModel.state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _viewModel.state.errorMessage!,
                            style: AppTypography.textMdBold.copyWith(color: AppColors.error),
                          ),
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
                              validator: Validatorless.multiple([
                                Validatorless.required('Email obrigatório'),
                                Validatorless.email('Email inválido'),
                              ]),
                              onChanged: (value) => _viewModel.setEmail(value),
                            ),
                            GasosaPasswordField(
                              label: 'Senha',
                              controller: _passwordEC,
                              validator: Validatorless.multiple([
                                Validatorless.required('Senha obrigatória'),
                                Validatorless.min(6, 'Senha deve ter pelo menos 6 caracteres'),
                              ]),
                              onChanged: (value) => _viewModel.setPassword(value),
                            ),
                            GasosaButton(
                              label: state.isLoading ? 'Entrando...' : 'Entrar',
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
