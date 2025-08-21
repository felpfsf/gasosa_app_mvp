import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class GasosaButton extends StatelessWidget {
  const GasosaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isExpanded = true,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
  });
  
  final String label;
  final VoidCallback? onPressed;
  final bool isExpanded;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final child = ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: textColor ?? AppColors.text,
        textStyle: AppTypography.textMdBold,
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
      ),
      child: Text(label),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: child);
    }

    return child;
  }
}
