import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

enum GasosaButtonVariant {
  primary,
  danger,
  secondary,
  outline,
}

class GasosaButton extends StatelessWidget {
  const GasosaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GasosaButtonVariant.primary,
    this.isExpanded = true,
    this.isDisabled = false,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final GasosaButtonVariant variant;
  final bool isExpanded;
  final bool isDisabled;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;

  Color _getBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    
    switch (variant) {
      case GasosaButtonVariant.primary:
        return AppColors.primary;
      case GasosaButtonVariant.danger:
        return Colors.red;
      case GasosaButtonVariant.secondary:
        return Colors.grey;
      case GasosaButtonVariant.outline:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (textColor != null) return textColor!;
    
    switch (variant) {
      case GasosaButtonVariant.primary:
        return AppColors.text;
      case GasosaButtonVariant.danger:
        return Colors.white;
      case GasosaButtonVariant.secondary:
        return AppColors.text;
      case GasosaButtonVariant.outline:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isButtonDisabled = isDisabled || isLoading;
    final bgColor = _getBackgroundColor();
    final txtColor = _getTextColor();
    
    final child = ElevatedButton(
      onPressed: isButtonDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isButtonDisabled ? bgColor.withValues(alpha: .4) : bgColor,
        foregroundColor: isButtonDisabled
            ? txtColor.withValues(alpha: .4)
            : txtColor,
        textStyle: AppTypography.textMdBold,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusMd,
          side: variant == GasosaButtonVariant.outline
              ? BorderSide(color: isButtonDisabled ? AppColors.primary.withValues(alpha: .4) : AppColors.primary)
              : BorderSide.none,
        ),
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
                  txtColor.withValues(alpha: .7),
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
