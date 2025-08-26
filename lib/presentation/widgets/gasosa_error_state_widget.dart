import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class GasosaErrorStateWidget extends StatelessWidget {
  const GasosaErrorStateWidget({
    super.key,
    required this.errorMessage,
    this.onPressed,
  });

  final String errorMessage;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.md,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.surface),
            Text(errorMessage, style: AppTypography.textMdRegular),
            FilledButton.icon(
              onPressed: onPressed,
              label: const Text('Tentar novamente'),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
