import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/routes/route_paths.dart';
import 'package:gasosa_app/presentation/screens/auth/widgets/auth_google_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_password_field.dart';
import 'package:gasosa_app/presentation/widgets/logo_hero.dart';
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
  @override
  Widget build(BuildContext context) {
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
                  const AuthGoogleButton(),
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
                        ),
                        GasosaPasswordField(
                          label: 'Senha',
                          controller: _passwordEC,
                        ),
                        const GasosaButton(label: 'Entrar'),
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
  }
}
