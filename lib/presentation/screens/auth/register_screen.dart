import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gasosa_app/core/di/locator.dart';
import 'package:gasosa_app/core/validators/user_validators.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/auth/viewmodel/register_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_password_field.dart';
import 'package:gasosa_app/presentation/widgets/logo_hero.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
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
    if (_viewModel.state.isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    final ok = await _viewModel.register();

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
          appBar: GasosaAppbar(
            title: 'Registrar',
            showBackButton: true,
            onBackPressed: () => context.go(RoutePaths.dashboard),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: AppSpacing.lg,
                    children: [
                      const LogoHero(size: 120),
                      Text('Crie sua conta', style: AppTypography.textLgBold),
                      Form(
                        key: _formKey,
                        child: Column(
                          spacing: AppSpacing.md,
                          children: [
                            GasosaFormField(
                              label: 'Nome',
                              controller: _nameEC,
                              validator: UserValidators.name,
                              onChanged: (value) => _viewModel.setName(value),
                            ),
                            GasosaFormField(
                              label: 'E-mail',
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
                            GasosaPasswordField(
                              label: 'Confirmar Senha',
                              controller: _confirmPasswordEC,
                              validator: UserValidators.confirmPassword(_passwordEC),
                            ),
                            AppSpacing.gap8,
                            GasosaButton(
                              label: 'Cadastrar',
                              onPressed: state.isLoading ? null : () => _handleRegister(),
                            ),
                          ],
                        ),
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

  @override
  void dispose() {
    super.dispose();
    _nameEC.dispose();
    _emailEC.dispose();
    _passwordEC.dispose();
    _confirmPasswordEC.dispose();
    _viewModel.dispose();
  }
}
