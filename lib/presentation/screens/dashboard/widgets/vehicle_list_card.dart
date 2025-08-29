import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gasosa_app/domain/entities/vehicle.dart';
import 'package:gasosa_app/presentation/widgets/gasosa_card.dart';
import 'package:gasosa_app/theme/app_colors.dart';
import 'package:gasosa_app/theme/app_spacing.dart';
import 'package:gasosa_app/theme/app_typography.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final VehicleEntity vehicle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final plate = (vehicle.plate ?? '').trim();
    final capacity = vehicle.tankCapacity;
    final subtitle = [
      if (plate.isNotEmpty) plate.toUpperCase(),
      if (capacity != null) '${capacity.toStringAsFixed(0)} L',
    ].join(' • ');

    return GasosaCard(
      onTap: onTap,
      child: Row(
        spacing: AppSpacing.md,
        children: [
          _VehicleThumbnail(vehicle.photoPath),
          AppSpacing.gap16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  vehicle.name,
                  style: AppTypography.textMdBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppTypography.textSmRegular.copyWith(color: AppColors.warning),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                color: AppColors.text,
                onPressed: onEdit?.call,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir',
                color: AppColors.text,
                onPressed: onDelete?.call,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Ver detalhes',
                color: AppColors.text,
                onPressed: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleThumbnail extends StatelessWidget {
  const _VehicleThumbnail(this.photoUrl);

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    const double size = 48.0;
    final radius = BorderRadius.circular(24);
    Widget child;
    if (photoUrl != null && photoUrl!.isNotEmpty && File(photoUrl!).existsSync()) {
      child = ClipRRect(
        borderRadius: radius,
        child: Image.file(
          File(photoUrl!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.directions_car_filled_outlined, color: AppColors.primary),
      );
    }

    return child;
  }
}
