import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class GasosaCheckbox extends StatelessWidget {
  const GasosaCheckbox({
    super.key,
    required this.title,
    required this.value,
    this.onChanged,
    this.subtitle,
  });

  final String title;
  final bool value;
  final Function(bool?)? onChanged;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: AppTypography.textSmBold),
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        checkColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
