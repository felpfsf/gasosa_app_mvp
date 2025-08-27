import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class GasosaEmptyStateWidget extends StatelessWidget {
  const GasosaEmptyStateWidget({
    super.key,
    required this.title,
    this.actionLabel,
    this.message,
    this.onPressed,
  });

  final String title;
  final String? message;
  final VoidCallback? onPressed;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: AppSpacing.paddingHorizontalMd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.md,
            children: [
              const Icon(Icons.find_in_page_rounded, color: AppColors.border, size: 96),
              Text(
                title,
                style: AppTypography.titleMd,
                textAlign: TextAlign.center,
              ),
              if (message != null)
                Text(
                  message!,
                  style: AppTypography.textMdRegular,
                  textAlign: TextAlign.center,
                ),
              if (onPressed != null)
                ElevatedButton(
                  onPressed: onPressed,
                  child: Text(actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}