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
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isExpanded;
  final bool isDisabled;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final isButtonDisabled = isDisabled || isLoading;
    
    final child = ElevatedButton(
      onPressed: isButtonDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isButtonDisabled ? AppColors.primary.withValues(alpha: .4) : (backgroundColor ?? AppColors.primary),
        foregroundColor: isButtonDisabled
            ? (textColor ?? AppColors.text).withValues(alpha: .4)
            : (textColor ?? AppColors.text),
        textStyle: AppTypography.textMdBold,
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  (textColor ?? AppColors.text).withValues(alpha: .7),
                ),
              ),
            ),
          Text(label),
        ],
      ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: child);
    }

    return child;
  }
}
