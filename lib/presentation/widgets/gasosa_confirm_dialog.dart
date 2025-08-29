import 'package:flutter/material.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class GasosaConfirmDialog extends StatelessWidget {
  const GasosaConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.cancelLabel,
    this.danger = false,
  });

  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final confirmStyle = danger ? FilledButton.styleFrom(backgroundColor: scheme.error) : null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        spacing: AppSpacing.sm,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded, color: AppColors.error.withValues(alpha: 0.8)),
          Text(title, style: AppTypography.textSmBold.copyWith(color: AppColors.error)),
        ],
      ),
      content: Text(content, style: AppTypography.textSmRegular.copyWith(color: scheme.onSurfaceVariant)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel, style: AppTypography.textSmRegular),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: confirmStyle,
          child: Text(confirmLabel, style: AppTypography.textSmRegular),
        ),
      ],
    );
  }
}

Future<bool> showGasosaConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool danger = false,
}) async {
  final result = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => GasosaConfirmDialog(
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
    ),
  );
  return result == true;
}
