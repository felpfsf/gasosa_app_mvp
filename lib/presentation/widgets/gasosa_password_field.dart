import 'package:flutter/material.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_form_field.dart';
import 'package:gasosa_app/theme/app_colors.dart';

class GasosaPasswordField extends StatefulWidget {
  const GasosaPasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  State<GasosaPasswordField> createState() => _GasosaPasswordFieldState();
}

class _GasosaPasswordFieldState extends State<GasosaPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return GasosaFormField(
      label: widget.label,
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator,
      suffixIcon: IconButton(
        onPressed: () {
          setState(() => _obscureText = !_obscureText);
        },
        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
        color: AppColors.text.withValues(alpha: .6),
      ),
    );
  }
}
