import 'package:flutter/material.dart';
import 'package:gasosa_app/core/app_strings.dart';
import 'package:gasosa_app/core/di/injection.dart';
import 'package:gasosa_app/core/presentation/ui_state.dart';
import 'package:gasosa_app/presentation/screens/auth/viewmodel/login_viewmodel.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_appbar.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_button.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/presentation/widgets/messages.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final LoginViewModel _viewModel;

  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<LoginViewModel>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await _viewModel.sendPasswordReset(_emailController.text.trim());

    if (!mounted) return;

    result?.fold(
      (failure) => Messages.showError(context, failure.message),
      (_) => setState(() => _emailSent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GasosaAppbar(
        title: ForgotPasswordStrings.appBarTitle,
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: _emailSent
              ? _SuccessState(email: _emailController.text.trim())
              : _FormState(
                  formKey: _formKey,
                  emailController: _emailController,
                  viewModel: _viewModel,
                  onSubmit: _submit,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form state
// ---------------------------------------------------------------------------

class _FormState extends StatelessWidget {
  const _FormState({
    required this.formKey,
    required this.emailController,
    required this.viewModel,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final LoginViewModel viewModel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.lg,
        children: [
          Text(
            ForgotPasswordStrings.instructions,
            style: AppTypography.textMdRegular,
          ),
          GasosaFormField(
            label: ForgotPasswordStrings.emailLabel,
            hint: ForgotPasswordStrings.emailHint,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o e-mail';
              }
              if (!value.contains('@')) {
                return 'E-mail inválido';
              }
              return null;
            },
          ),
          ListenableBuilder(
            listenable: viewModel.resetCommand.state,
            builder: (_, _) {
              final isLoading = viewModel.resetCommand.state.value is UiLoading;
              return GasosaButton(
                label: ForgotPasswordStrings.sendButton,
                isLoading: isLoading,
                isDisabled: isLoading,
                onPressed: onSubmit,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success state
// ---------------------------------------------------------------------------

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSpacing.md,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: AppColors.primary,
        ),
        Text(
          ForgotPasswordStrings.successTitle,
          style: AppTypography.titleMd,
          textAlign: TextAlign.center,
        ),
        Text(
          ForgotPasswordStrings.successMessage,
          style: AppTypography.textMdRegular,
          textAlign: TextAlign.center,
        ),
        Text(
          email,
          style: AppTypography.textMdBold,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        GasosaButton(
          label: ForgotPasswordStrings.backToLoginButton,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
